if [ -f $HOME/compute/tf_env.sh ]; then
    . $HOME/compute/tf_env.sh
    export TF_VAR_namespace=$OBJECT_STORAGE_NAMESPACE
    export IS_BASTION="true"
    export TARGET_DIR="$HOME/target"
    mkdir -p $TARGET_DIR
    if [ "$0" != "-bash" ]; then
        export APP_DIR="${SCRIPT_DIR#*/app/}"
        export APP_NAME="${APP_DIR//\//-}"
    fi
fi

# -- Shared Compute Functions -----------------------------------------------

# -- title ------------------------------------------------------------------
title() {
  line='-------------------------------------------------------------------------'
  NAME=$1
  echo
  echo "-- $NAME ${line:${#NAME}}"
  echo  
}
export -f title

# -- auto_echo --------------------------------------------------------------
auto_echo() {
    if [ -z "$SILENT_MODE" ]; then
        echo "$1"
    fi  
}
export -f auto_echo

# -- debug ------------------------------------------------------------------
debug() {
    if [ "$DEBUG_MODE" == "true" ]; then
        echo "$1"
    fi  
}
export -f debug

# -- error_exit -------------------------------------------------------------
error_exit() {
    echo
    LEN=${#BASH_LINENO[@]}
    printf "%-40s %-10s %-20s\n" "STACK TRACE"  "LINE" "FUNCTION"
    for (( INDEX=${LEN}-1; INDEX>=0; INDEX--))
    do
        printf "   %-37s %-10s %-20s\n" ${BASH_SOURCE[${INDEX}]#$PROJECT_DIR/}  ${BASH_LINENO[$(($INDEX-1))]} ${FUNCNAME[${INDEX}]}
    done

    if [ "$1" != "" ]; then
        echo
        echo "ERROR: $1"
    fi
    exit 1
}
export -f error_exit

# -- exit_on_error ----------------------------------------------------------
exit_on_error() {
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        echo "Success - $1"
    else
        title "EXIT ON ERROR - HISTORY - $1 "
        history 2 | cut -c1-256
        error_exit "Command Failed (RESULT=$RESULT)"
    fi  
}
export -f exit_on_error

# -- replace_db_user_password_in_file ----------------------------------------
replace_db_user_password_in_file() {
    # Replace DB_USER DB_PASSWORD
    CONFIG_FILE=$1
    if [ -f $CONFIG_FILE ]; then 
        sed -i "s/##DB_USER##/$TF_VAR_db_user/" $CONFIG_FILE
        sed -i "s/##DB_PASSWORD##/$TF_VAR_db_password/" $CONFIG_FILE
        sed -i "s%##JDBC_URL##%$JDBC_URL%" $CONFIG_FILE
    fi
}  
export -f replace_db_user_password_in_file

# -- app_dir_list -----------------------------------------------------------
app_dir_list() {
    # Dir with start.sh or install.sh or build.sh or Dockerfile or k8s.yaml
    # ex: db rest ui
    find . -maxdepth 3 -type f \( -name "start.sh" -o -name "install.sh" -o -name "build.sh" -o -name "Dockerfile" -o -name "k8s.yaml" \) | xargs -n1 dirname | sed "s#^./##" | sort -u
}
export -f app_dir_list

# -- install_java -----------------------------------------------------------
install_java() {
  # Install the JVM (jdk or graalvm)
    if [ "$TF_VAR_java_vm" != "jdk" ]; then
        if grep -q 'export JAVA_HOME' $HOME/.bashrc; then
            echo "Java already installed " 
            return
        fi
        # GraalVM
        if [ "$TF_VAR_java_version" == 8 ]; then
            sudo dnf install -y graalvm21-ee-8-jdk 
            export JAVA_HOME=/usr/lib64/graalvm/graalvm22-ee-java8
        elif [ "$TF_VAR_java_version" == 11 ]; then
            sudo dnf install -y graalvm22-ee-11-jdk
            export JAVA_HOME=/usr/lib64/graalvm/graalvm22-ee-java11
        elif [ "$TF_VAR_java_version" == 17 ]; then
            sudo dnf install -y graalvm22-ee-17-jdk 
            export JAVA_HOME=/usr/lib64/graalvm/graalvm22-ee-java17
        elif [ "$TF_VAR_java_version" == 21 ]; then
            sudo dnf install -y graalvm-21-jdk
            export JAVA_HOME=/usr/lib64/graalvm/graalvm-java21
        else
            sudo dnf install -y graalvm-25-jdk
            export JAVA_HOME=/usr/lib64/graalvm/graalvm-java25    
            # sudo update-alternatives --set native-image $JAVA_HOME/lib/svm/bin/native-image
        fi   
        sudo update-alternatives --set java $JAVA_HOME/bin/java
        echo "export JAVA_HOME=${JAVA_HOME}" >> $HOME/.bashrc
    else
        # JDK 
        # Needed due to concurrency
        sudo dnf install -y alsa-lib 
        if [ "$TF_VAR_java_version" == 8 ]; then
            sudo dnf install -y java-1.8.0-openjdk
        elif [ "$TF_VAR_java_version" == 11 ]; then
            sudo dnf install -y java-11  
        elif [ "$TF_VAR_java_version" == 17 ]; then
            sudo dnf install -y java-17        
        elif [ "$TF_VAR_java_version" == 21 ]; then
            sudo dnf install -y java-21         
        else
            sudo dnf install -y java-25  
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

  # Build on Bastion
    if [ "$TF_VAR_build_host" == "bastion" ]; then 
        sudo dnf install -y maven
    fi
}
export -f install_java

# -- install_tnsname  -------------------------------------------------------
install_tnsname() {
    # Run SQLCl
    # Install the tables
    export TNS_ADMIN=$HOME/app/db
    mkdir -p $TNS_ADMIN
    cat > $TNS_ADMIN/tnsnames.ora <<EOT
DB = $DB_URL
EOT
}
export -f install_tnsname

# -- download  --------------------------------------------------------------
function download()
{
   echo "Downloading - $1"
   wget -nv $1
}
export -f download

# -- file_replace_variables -------------------------------------------------
# Function to replace ##VARIABLE_NAME## in a file
# Replace ##OPTIONAL/VARIABLE_NAME## by variables if it exists or __NOT_USED__

file_replace_variables() {
  local file="$1"
  local temp_file=$(mktemp)

  echo "Replace variables in file: $1"
  while IFS= read -r line || [ -n "$line" ]; do  
    while [[ $line =~ (.*)##(.*)##(.*) ]]; do
      local var_name="${BASH_REMATCH[2]}"
      debug "- variable: ${var_name}"

      if [[ ${var_name} =~ OPTIONAL/(.*) ]]; then
         var_name2="${BASH_REMATCH[1]}"
         var_value="${!var_name2}"
         if [ "$var_value" == "" ]; then
            var_value="__NOT_USED__"
         fi
      else
        var_value="${!var_name}"       
        if [ "$var_value" == "" ]; then
            echo "ERROR: Environment variable '${var_name}' is not defined."
            error_exit
        fi
      fi
      line=${line/"##${var_name}##"/${var_value}}
    done

    echo "$line" >> "$temp_file"
  done < "$file"

  mv "$temp_file" "$file"
}
export -f file_replace_variables 

# -- install_sqlcl  ---------------------------------------------------------
install_sqlcl() {
    install_java
    install_tnsname
    cd $HOME/app/db
    if [ ! -f sqlcl-latest.zip ]; then
        download https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip
        rm -Rf sqlcl
        unzip sqlcl-latest.zip
    fi 
    cd -
}  
export -f install_sqlcl

# -- install_python  --------------------------------------------------------
install_python() {
    sudo dnf install -y python3.12 python3.12-pip python3-devel wget
    sudo update-alternatives --set python /usr/bin/python3.12
    curl -LsSf https://astral.sh/uv/install.sh | sh
    uv venv myenv
    source myenv/bin/activate
    if [ -f requirements.txt ]; then 
      uv pip install -r requirements.txt
    fi 
    if [ -f src/requirements.txt ]; then 
      uv pip install -r src/requirements.txt
    fi 
}
export -f install_python

# -- install_libreoffice  ---------------------------------------------------
install_libreoffice() {
    export STABLE_VERSIONS=`curl -s https://download.documentfoundation.org/libreoffice/stable/`
    export LIBREOFFICE_VERSION=`echo $STABLE_VERSIONS | sed 's/.*<td valign="top">//' | sed 's/\/<\/a>.*//' | sed 's/.*\/">//'`
    echo LIBREOFFICE_VERSION=$LIBREOFFICE_VERSION
    cd /tmp
    export LIBREOFFICE_TGZ="LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_rpm.tar.gz"
    if [ ! -f $LIBREOFFICE_TGZ ]; then
        sudo dnf group install -y "Server with GUI"

        download https://download.documentfoundation.org/libreoffice/stable/${LIBREOFFICE_VERSION}/rpm/x86_64/$LIBREOFFICE_TGZ
        tar -xzvf $LIBREOFFICE_TGZ
        cd LibreOffice*/RPMS
        sudo dnf install *.rpm -y
    fi 
    export LIBRE_OFFICE_EXE=`find ${PATH//:/ } -maxdepth 1 -executable -name 'libreoffice*' | grep "libreoffice"`
    echo LIBRE_OFFICE_EXE=$LIBRE_OFFICE_EXE
    cd -
} 
export -f install_libreoffice   

# -- install_chrome  --------------------------------------------------------
install_chrome() {
    cd /tmp
    export CHROME_RPM="google-chrome-stable_current_x86_64.rpm"
    if [ ! -f $CHROME_RPM ]; then
      cd /tmp
      download https://dl.google.com/linux/direct/$CHROME_RPM
      sudo dnf localinstall -y $CHROME_RPM
    fi
    cd -
} 
export -f install_chrome   

# -- install_instant_client  ------------------------------------------------

# Install InstantClient (including SqlPlus)
install_instant_client() {
    install_tnsname

    # Install SQL*InstantClient
    if [[ `arch` == "aarch64" ]]; then
        sudo dnf install -y oracle-release-el8 
        sudo dnf install -y oracle-instantclient19.19-basic oracle-instantclient19.19-sqlplus oracle-instantclient19.19-tools
    else
        export INSTANT_VERSION=23.26.0.0.0-1
        cd /tmp
        if [ ! -f /tmp/oracle-instantclient-basic-${INSTANT_VERSION}.el8.x86_64.rpm ]; then
            wget -nv https://download.oracle.com/otn_software/linux/instantclient/2326000/oracle-instantclient-basic-${INSTANT_VERSION}.el8.x86_64.rpm
            wget -nv https://download.oracle.com/otn_software/linux/instantclient/2326000/oracle-instantclient-sqlplus-${INSTANT_VERSION}.el8.x86_64.rpm
            wget -nv https://download.oracle.com/otn_software/linux/instantclient/2326000/oracle-instantclient-tools-${INSTANT_VERSION}.el8.x86_64.rpm
            sudo dnf install -y oracle-instantclient-basic-${INSTANT_VERSION}.el8.x86_64.rpm oracle-instantclient-sqlplus-${INSTANT_VERSION}.el8.x86_64.rpm oracle-instantclient-tools-${INSTANT_VERSION}.el8.x86_64.rpm
        fi 
        cd -
    fi
}
export -f install_instant_client   

create_self_signed_ip_certificate()
{
    mkdir -p certificate
    cd certificate
    # IP Certificate Request      
    cat > san.cnf << EOF     
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
C = US
ST = State
L = City
O = Organization
CN = $BASTION_IP

[req_ext]
subjectAltName = @alt_names

[alt_names]
IP.1 = $BASTION_IP
EOF

    # Generate the key and the chain      
    openssl genrsa -out server.key 2048
    openssl req -new -key server.key -out server.csr -config san.cnf
    openssl x509 -req -in server.csr -signkey server.key -out server.crt -days 365 -extensions req_ext -extfile san.cnf
    cd -

    cat > nginx_tls.conf << EOF     
# Self Signed IP Certificate     
server {
    server_name  $BASTION_IP; 
    root         /usr/share/nginx/html;

    # Load configuration files for the default server block.
    include /etc/nginx/default.d/*.conf;
    location / {
    }

    include conf.d/nginx_app.locations;
    error_page 404 /404.html;
        location = /40x.html {
    }

    error_page 500 502 503 504 /50x.html;
        location = /50x.html {
    }
    listen [::]:443 ssl ipv6only=on; 
    listen 443 ssl; 
    ssl_certificate /home/opc/app/ui/certificate/server.crt; 
    ssl_certificate_key /home/opc/app/ui/certificate/server.key; 

    ssl_session_cache shared:le_nginx_SSL:10m;
    ssl_session_timeout 1440m;
    ssl_session_tickets off;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
}
EOF
}
export -f create_self_signed_ip_certificate 

# -- Install NGINX  ------------------------------------------------------------------
install_ngnix() {
    title "NGINX"
    sudo dnf install nginx -y > /tmp/dnf_nginx.log

    # Default: location /app/ { proxy_pass http://localhost:8080 }
    if [ -f nginx_app.locations ]; then
        cp nginx_app.locations $TARGET_DIR/nginx_app.locations
        file_replace_variables $TARGET_DIR/nginx_app.locations
        sudo cp $TARGET_DIR/nginx_app.locations /etc/nginx/conf.d/.
        if grep -q nginx_app /etc/nginx/nginx.conf; then
            echo "Include nginx_app.locations is already there"
        else
            echo "Adding nginx_app.locations"
            sudo awk -i inplace '/404.html/ && !x {print "        include conf.d/nginx_app.locations;"; x=1} 1' /etc/nginx/nginx.conf
        fi
    fi

    # TLS
    if [ ! -f nginx_tls.conf ]; then
        create_self_signed_ip_certificate  
    fi

    echo "Adding nginx_tls.conf"
    sudo cp nginx_tls.conf /etc/nginx/conf.d/.
    sudo awk -i inplace '/# HTTPS server/ && !x {print "        include conf.d/nginx_tls.conf;"; x=1} 1' /etc/nginx/nginx.conf

    # SE Linux (for proxy_pass)
    sudo setsebool -P httpd_can_network_connect 1

    # Start it
    sudo systemctl enable nginx
    sudo systemctl restart nginx

    if [ -d html ]; then
        # Copy the index file after the installation of nginx
        sudo cp -r html/* /usr/share/nginx/html/
    fi

    # Firewalld
    sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
    sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
    sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
    sudo firewall-cmd --reload

    # -- Util -------------------------------------------------------------------
    sudo dnf install -y psmisc
}
export -f install_ngnix 

# -- Install Docker tools ---------------------------------------------------

install_docker_tools() {
    # docker 
    sudo yum install -y docker
    sudo touch /etc/containers/nodocker

    # oci cli
    sudo dnf install -y git python36-oci-cli
    oci setup repair-file-permissions --file $HOME/.oci/config
    oci setup repair-file-permissions --file $HOME/.oci/oci_api_key.pem    
    echo "export OCI_CLI_AUTH=instance_principal" >> ~/.bashrc  

    # kubectl
    mkdir -p $HOME/bin
    cd $HOME/bin
    if [ `arch` == "x86_64" ]; then
        ARCH_PREFIX=amd64
    else
        ARCH_PREFIX=arm64
    fi
    curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH_PREFIX}/kubectl
    chmod +x kubectl
    echo "source <(kubectl completion bash)" >> ~/.bashrc
}
export -f install_docker_tools

# -- get_docker_prefix ------------------------------------------------------
get_docker_prefix() {
    export DOCKER_PREFIX_NO_OCIR=${CONTAINER_PREFIX}
    export DOCKER_PREFIX=${OCIR_HOST}/${OBJECT_STORAGE_NAMESPACE}/${DOCKER_PREFIX_NO_OCIR}
    auto_echo DOCKER_PREFIX=$DOCKER_PREFIX
}
export -f get_docker_prefix 

# -- copy_replace_apply_target_oke ------------------------------------------

# Apply k8s file after replacing the variables 
copy_replace_apply_target_oke() {
  FILEPATH="$1"  
  APP="$2"
  FILENAME="${FILEPATH##*/}"
  echo "-- kubectl apply -- $FILENAME --"
  mkdir -p $TARGET_DIR/oke
  cp $FILEPATH $TARGET_DIR/oke/${APP}-${FILENAME}
  file_replace_variables $TARGET_DIR/oke/${APP}-${FILENAME}
  kubectl apply -f $TARGET_DIR/oke/${APP}-${FILENAME}
}
export -f copy_replace_apply_target_oke 

# -- docker_login -----------------------------------------------------------
docker_login() {
    get_docker_prefix
    # Login only if needed
    if ! docker system info 2>/dev/null | grep -q "Username"; then
        oci raw-request --region $TF_VAR_region --http-method GET --target-uri "https://${OCIR_HOST}/20180419/docker/token" | jq -r .data.token | docker login -u BEARER_TOKEN --password-stdin ${OCIR_HOST}
    fi
    exit_on_error "Docker Login"
}

# -- ocir_docker_push_app -------------------------------------------------------
ocir_docker_push_app() {
    # Docker Login
    APP=$1
    docker_login
    export DOCKER_IMG_VERSION=$(date +%Y-%m-%d-%H-%M-%S)
    docker tag ${TF_VAR_prefix}-${APP} ${DOCKER_PREFIX}/${TF_VAR_prefix}-${APP}:${DOCKER_IMG_VERSION}
    oci artifacts container repository create --compartment-id $TF_VAR_compartment_ocid --display-name ${DOCKER_PREFIX_NO_OCIR}/${TF_VAR_prefix}-${APP} 2>/dev/null
    docker push ${DOCKER_PREFIX}/${TF_VAR_prefix}-${APP}:${DOCKER_IMG_VERSION}
    exit_on_error "docker push ${APP}"
    echo "${DOCKER_PREFIX}/${TF_VAR_prefix}-${APP}:${DOCKER_IMG_VERSION}" > $TARGET_DIR/docker_image_${APP}.txt
}
export -f ocir_docker_push_app

# -- ocir_docker_push -------------------------------------------------------
ocir_docker_push () {
    # Docker Login
    echo DOCKER_PREFIX=$DOCKER_PREFIX

    # Push image in registry
    for APP_NAME in `app_name_list_build`; do
        if [ -n "$(docker images -q ${TF_VAR_prefix}-${APP_NAME} 2> /dev/null)" ]; then
            ocir_docker_push_app ${APP_NAME}
        fi
    done
}
export -f ocir_docker_push

# -- oke_deploy_app ------------------------------------------------------------
oke_deploy_app() {
    APP=$1
    if [ -f Dockerfile ]; then
        title "OCIR Docker Push - $APP"  
        ocir_docker_push_app $APP
    fi    
    title "Deploy to OKE - $APP"  
    if [ -f k8s.yaml ]; then
        copy_replace_apply_target_oke k8s.yaml $APP
    fi
    if [ -f k8s-ingress.yaml ]; then
        copy_replace_apply_target_oke k8s-ingress.yaml $APP
    fi
}
export -f oke_deploy_app

# -- is_deploy_compute ------------------------------------------------------
is_deploy_compute() {
    if [ "$TF_VAR_deploy_type" == "public_compute" ] || [ "$TF_VAR_deploy_type" == "private_compute" ] || [ "$TF_VAR_deploy_type" == "instance_pool" ]; then
        return 0
    else
        return 1
    fi
}

# -- build_ui ---------------------------------------------------------------
build_ui() {
    cd $SCRIPT_DIR
    if is_deploy_compute; then
        if [ "$IS_BASTION" != "" ]; then
            ./install.sh
        else 
            mkdir -p $TARGET_DIR/compute/app/ui/html
            cp -r html/* $TARGET_DIR/compute/app/ui/html/.
            cp nginx* $TARGET_DIR/compute/app/ui/.
            cp install.sh $TARGET_DIR/compute/app/ui/.
        fi
    elif [ "$TF_VAR_deploy_type" == "function" ]; then 
        if [ -d html ]; then 
            oci os object bulk-upload -ns $OBJECT_STORAGE_NAMESPACE -bn ${TF_VAR_prefix}-public-bucket --src-dir html --overwrite --content-type auto
        else 
            echo "<build_ui> No html directory"
        fi
    else
        # Kubernetes and Container Instances
        docker image rm ${TF_VAR_prefix}-ui:latest 
        docker build -t ${TF_VAR_prefix}-ui:latest .
        if [ "$TF_VAR_deploy_type" == "kubernetes" ]; then
            oke_deploy_app ui
        fi
    fi 
}
export -f build_ui 

# -- java_build_common ------------------------------------------------------
java_build_common() {
    if [ "${OCI_CLI_CLOUD_SHELL,,}" == "true" ]; then
        # csruntimectl is a function defined in /etc/bashrc.cloudshell
        . /etc/bashrc.cloudshell
        export JAVA_ID=`csruntimectl java list | grep jdk-17 | sed -e 's/^.*\(graal[^ ]*\) .*$/\1/'`
        csruntimectl java set $JAVA_ID
    fi

    if [ -f $TARGET_DIR/jms_agent_deploy.sh ]; then
        cp $TARGET_DIR/jms_agent_deploy.sh $TARGET_DIR/compute/.
    fi

    if [ -f $PROJECT_DIR/../group_common/target/jms_agent_deploy.sh ]; then
        cp $PROJECT_DIR/../group_common/target/jms_agent_deploy.sh $TARGET_DIR/compute/.
    fi
}
export -f java_build_common 

# -- build_rsync ------------------------------------------------------------

build_rsync() {
    if [ "$IS_BASTION" != "" ]; then
        return
    fi
 
    if [ "$1" == "" ]; then
        error_exit "Missing src parameter"
    fi

    if [ "$1" == "target" ]; then
        # In Java, copy the *.sh and the target 
        mkdir -p $TARGET_DIR/compute/app/$APP_DIR/target
        cp *.sh $TARGET_DIR/compute/app/$APP_DIR/.
        rsync -av --progress $1/ $TARGET_DIR/compute/app/$APP_DIR/target --exclude starter --exclude terraform.tfvars
    else
        mkdir -p $TARGET_DIR/compute/app/$APP_DIR
        rsync -av --progress $1/ $TARGET_DIR/compute/app/$APP_DIR --exclude starter --exclude terraform.tfvars
    fi
    # Remove the build.sh if it is not done on the bastion
    if [ "$TF_VAR_build_host" != "bastion" ]; then
        rm $TARGET_DIR/compute/app/$APP_DIR/build.sh
    fi    
}
export -f build_rsync
