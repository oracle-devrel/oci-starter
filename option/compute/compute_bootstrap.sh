#!/bin/bash
# compute_java_bootstrap 
#
# Script that is runned once during the setup of a 
# - compute
# - with Java
if [[ -z "$TF_VAR_language" ]]; then
  echo "Missing env variables"
  exit
fi

export ARCH=`rpm --eval '%{_arch}'`
echo "ARCH=$ARCH"

# Disable SELinux
# XXXXXX Since OL8, the service does not start if SELINUX=enforcing XXXXXX
sudo setenforce 0
sudo sed -i s/^SELINUX=.*$/SELINUX=permissive/ /etc/selinux/config

# -- Java --------------------------------------------------------------------
# Set up the correct Java / VM version
if [ "$TF_VAR_language" == "java" ]; then
  # Install the JVM (jdk or graalvm)
  if [ "$TF_VAR_java_vm" == "graalvm" ]; then
    # graalvm
    if [ "$TF_VAR_java_version" == 8 ]; then
      sudo dnf install -y graalvm21-ee-8-jdk 
      sudo update-alternatives --set java /usr/lib64/graalvm/graalvm22-ee-java8/bin/java
    elif [ "$TF_VAR_java_version" == 11 ]; then
      sudo dnf install -y graalvm22-ee-11-jdk
      sudo update-alternatives --set java /usr/lib64/graalvm/graalvm22-ee-java11/bin/java
    elif [ "$TF_VAR_java_version" == 17 ]; then
      sudo dnf install -y graalvm22-ee-17-jdk 
      sudo update-alternatives --set java /usr/lib64/graalvm/graalvm22-ee-java17/bin/java
    fi   
  else
    # jdk 
    if [ "$TF_VAR_java_version" == 8 ]; then
      sudo dnf install -y java-1.8.0-openjdk
    elif [ "$TF_VAR_java_version" == 11 ]; then
      sudo dnf install -y java-11  
    elif [ "$TF_VAR_java_version" == 17 ]; then
      sudo dnf install -y java-17  
      # Trick to find the path
      # cd -P "/usr/java/latest"
      # export JAVA_LATEST_PATH=`pwd`
      # cd -
      # sudo update-alternatives --set java $JAVA_LATEST_PATH/bin/java
    fi
  fi

  # JMS agent deploy (to fleet_ocid )
  if [ -f jms_agent_deploy.sh ]; then
    chmod +x jms_agent_deploy.sh
    sudo ./jms_agent_deploy.sh
  fi
fi

# -- App --------------------------------------------------------------------
# Application Specific installation
if [ -f app/install.sh ]; then
  chmod +x app/install.sh
  app/install.sh
fi  

# -- app/start.sh -----------------------------------------------------------
if [ -f app/start.sh ]; then
  # Hardcode the connection to the DB in the start.sh
  if [ "$DB_URL" != "" ]; then
    sed -i "s!##JDBC_URL##!$JDBC_URL!" app/start.sh 
    sed -i "s!##DB_URL##!$DB_URL!" app/start.sh 
  fi  
  sed -i "s!##TF_VAR_java_vm##!$TF_VAR_java_vm!" app/start.sh   
  chmod +x app/start.sh

  # Create an "app.service" that starts when the machine starts.
  cat > /tmp/app.service << EOT
[Unit]
Description=App
After=network.target

[Service]
Type=simple
ExecStart=/home/opc/app/start.sh
TimeoutStartSec=0
User=opc

[Install]
WantedBy=default.target
EOT

  sudo cp /tmp/app.service /etc/systemd/system
  sudo chmod 664 /etc/systemd/system/app.service
  sudo systemctl daemon-reload
  sudo systemctl enable app.service
  sudo systemctl restart app.service
fi

# -- UI --------------------------------------------------------------------
# Install NGINX
sudo dnf install nginx -y > /tmp/dnf_nginx.log

# Default: location /app/ { proxy_pass http://localhost:8080 }
sudo cp nginx_app.locations /etc/nginx/conf.d/.
if grep -q nginx_app /etc/nginx/nginx.conf; then
  echo "Include nginx_app.locations is already there"
else
    echo "Include nginx_app.locations not found"
    sudo awk -i inplace '/404.html/ && !x {print "        include conf.d/nginx_app.locations;"; x=1} 1' /etc/nginx/nginx.conf
fi

# SE Linux (for proxy_pass)
sudo setsebool -P httpd_can_network_connect 1

# Start it
sudo systemctl enable nginx
sudo systemctl restart nginx

if [ -d ui ]; then
  # Copy the index file after the installation of nginx
  sudo cp -r ui/* /usr/share/nginx/html/
fi

# Firewalld
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
sudo firewall-cmd --reload

# -- Util -------------------------------------------------------------------
sudo dnf install -y psmisc
