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
  else
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