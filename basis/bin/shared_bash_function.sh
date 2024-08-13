### Commmon functions
title() {
  line='-------------------------------------------------------------------------'
  NAME=$1
  echo
  echo "-- $NAME ${line:${#NAME}} ($SECONDS secs)"
  echo  
}

# Used in for loop for APP_DIR
app_dir_list() {
  ls -d $PROJECT_DIR/src/app* | sort -g | sed "s/.*src\///g"
}

# Java Build Common
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

build_ui() {
  cd $SCRIPT_DIR
  if is_deploy_compute; then
    mkdir -p ../../target/compute/ui
    cp -r ui/* ../../target/compute/ui/.
  elif [ "$TF_VAR_deploy_type" == "function" ]; then 
    oci os object bulk-upload -ns $TF_VAR_namespace -bn ${TF_VAR_prefix}-public-bucket --src-dir ui --overwrite --content-type auto
  else
    # Kubernetes and Container Instances
    docker image rm ${TF_VAR_prefix}-ui:latest
    docker build -t ${TF_VAR_prefix}-ui:latest .
  fi 
}

build_function() {
  # Build the function
  fn create context ${TF_VAR_region} --provider oracle
  fn use context ${TF_VAR_region}
  fn update context oracle.compartment-id ${TF_VAR_compartment_ocid}
  fn update context api-url https://functions.${TF_VAR_region}.oraclecloud.com
  fn update context registry ${TF_VAR_ocir}/${TF_VAR_namespace}
  # Set pipefail to get the error despite pip to tee
  set -o pipefail
  fn build -v | tee $TARGET_DIR/fn_build.log
  exit_on_error

  if grep --quiet "built successfully" $TARGET_DIR/fn_build.log; then
     fn bump
     # Store the image name and DB_URL in files
     grep "built successfully" $TARGET_DIR/fn_build.log | sed "s/Function //" | sed "s/ built successfully.//" > $TARGET_DIR/fn_image.txt
     echo "$1" > $TARGET_DIR/fn_db_url.txt
     . ../../env.sh
     # Push the image to docker
     docker login ${TF_VAR_ocir} -u ${TF_VAR_namespace}/${TF_VAR_username} -p "${TF_VAR_auth_token}"
     docker push $TF_VAR_fn_image
  else 
     echo "build_function - built successfully not found"
     exit 1
  fi 

  # First create the Function using terraform
  # Run env.sh to get function image 
  cd $PROJECT_DIR
  . env.sh 
  src/terraform/apply.sh --auto-approve
}

# Create KUBECONFIG file
create_kubeconfig() {
  oci ce cluster create-kubeconfig --cluster-id $OKE_OCID --file $KUBECONFIG --region $TF_VAR_region --token-version 2.0.0  --kube-endpoint PUBLIC_ENDPOINT
  chmod 600 $KUBECONFIG
}

ocir_docker_push () {
  # Docker Login
  docker login ${TF_VAR_ocir} -u ${TF_VAR_namespace}/${TF_VAR_username} -p "${TF_VAR_auth_token}"
  echo DOCKER_PREFIX=$DOCKER_PREFIX

  # Push image in registry
  docker tag ${TF_VAR_prefix}-app ${DOCKER_PREFIX}/${TF_VAR_prefix}-app:latest
  docker push ${DOCKER_PREFIX}/${TF_VAR_prefix}-app:latest

  docker tag ${TF_VAR_prefix}-ui ${DOCKER_PREFIX}/${TF_VAR_prefix}-ui:latest
  docker push ${DOCKER_PREFIX}/${TF_VAR_prefix}-ui:latest
}

replace_db_user_password_in_file() {
  # Replace DB_USER DB_PASSWORD
  CONFIG_FILE=$1
  sed -i "s/##DB_USER##/$TF_VAR_db_user/" $CONFIG_FILE
  sed -i "s/##DB_PASSWORD##/$TF_VAR_db_password/" $CONFIG_FILE
  sed -i "s%##JDBC_URL##%$JDBC_URL%" $CONFIG_FILE
}  

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

exit_on_error() {
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    echo "Success"
  else
    echo
    echo "EXIT ON ERROR - HISTORY"
    history 2
    error_exit "Command Failed (RESULT=$RESULT)"
  fi  
}

auto_echo () {
  if [ -z "$SILENT_MODE" ]; then
    echo "$1"
  fi  
}

set_if_not_null () {
  if [ "$2" != "" ] && [ "$2" != "null" ]; then
    auto_echo "$1=$RESULT"
    export $1="$RESULT"
  fi  
}

get_attribute_from_tfstate () {
  RESULT=`jq -r '[.resources[] | select(.name=="'$2'") | .instances[0].attributes.'$3'][0]' $STATE_FILE`
  set_if_not_null $1 $RESULT
}

get_id_from_tfstate () {
  RESULT=`jq -r '.resources[] | select(.name=="'$2'") | select(.mode=="managed") | .instances[0].attributes.id' $STATE_FILE`
  set_if_not_null $1 $RESULT
}


get_output_from_tfstate () {
  RESULT=`jq -r '.outputs."'$2'".value' $STATE_FILE | sed "s/ //"`
  set_if_not_null $1 $RESULT
}

# Check is the option '$1' is part of the TF_VAR_group_common
# If the app is not a group_common one, return 1==false
group_common_contain() {
  if [ "$TF_VAR_group_common" == "" ]; then
    return 1 
  fi  
  COMMON=,${TF_VAR_group_common},
  if [[ "$COMMON" == *",$1,"* ]]; then
    return 0
  else 
    return 1  
  fi
}

# Find the availability domain for a shape (ex: "VM.Standard.E2.1.Micro")
# ex: find_availabilty_domain_for_shape "VM.Standard.E2.1.Micro"
find_availabilty_domain_for_shape() {
  if [ "$TF_VAR_availability_domain_number" != "" ]; then
    return 0
  fi
  echo "Searching for shape $1 in Availability Domains"  
  i=1
  for ad in `oci iam availability-domain list --compartment-id=$TF_VAR_tenancy_ocid | jq -r ".data[].name"` 
  do
    echo "Checking in $ad"
    TEST=`oci compute shape list --compartment-id=$TF_VAR_tenancy_ocid --availability-domain $ad | jq ".data[] | select( .shape==\"$1\" )"`
    if [[ "$TEST" != "" ]]; then
        echo "Found in $ad"
        export TF_VAR_availability_domain_number=$i
        return 0
    fi
    i=$((i+1))
  done
  echo "Error shape $1 not found" 
  exit 1
}

# Get User Details (username and OCID)
get_user_details() {
  if [ "$OCI_CLI_CLOUD_SHELL" == "True" ];  then
    # Cloud Shell
    export TF_VAR_tenancy_ocid=$OCI_TENANCY
    export TF_VAR_region=$OCI_REGION
    # Needed for child region
    export TF_VAR_home_region=`echo $OCI_CS_HOST_OCID | awk -F[/.] '{print $4}'`
    if [[ "$OCI_CS_USER_OCID" == *"ocid1.saml2idp"* ]]; then
      # Ex: ocid1.saml2idp.oc1..aaaaaaaaexfmggau73773/user@domain.com -> oracleidentitycloudservice/user@domain.com
      # Split the string in 2 
      IFS='/' read -r -a array <<< "$OCI_CS_USER_OCID"
      IDP_NAME=`oci iam identity-provider get --identity-provider-id=${array[0]} | jq -r .data.name`
      IDP_NAME_LOWER=${IDP_NAME,,}
      export TF_VAR_username="$IDP_NAME_LOWER/${array[1]}"
    elif [[ "$OCI_CS_USER_OCID" == *"ocid1.user"* ]]; then
      export TF_VAR_user_ocid="$OCI_CS_USER_OCID"
    else 
      export TF_VAR_username=$OCI_CS_USER_OCID
    fi
  elif [ -f $HOME/.oci/config ]; then
    ## Get the [DEFAULT] config
    if [ -z "$OCI_CLI_PROFILE" ]; then
      OCI_PRO=DEFAULT
    else 
      OCI_PRO=$OCI_CLI_PROFILE
    fi    
    sed -n -e "/\[$OCI_PRO\]/,$$p" $HOME/.oci/config > /tmp/ociconfig
    export TF_VAR_user_ocid=`sed -n 's/user=//p' /tmp/ociconfig |head -1`
    export TF_VAR_fingerprint=`sed -n 's/fingerprint=//p' /tmp/ociconfig |head -1`
    export TF_VAR_private_key_path=`sed -n 's/key_file=//p' /tmp/ociconfig |head -1`
    export TF_VAR_region=`sed -n 's/region=//p' /tmp/ociconfig |head -1`
    export TF_VAR_tenancy_ocid=`sed -n 's/tenancy=//p' /tmp/ociconfig |head -1`  
    # echo TF_VAR_user_ocid=$TF_VAR_user_ocid
    # echo TF_VAR_fingerprint=$TF_VAR_fingerprint
    # echo TF_VAR_private_key_path=$TF_VAR_private_key_path
  elif [ "$OCI_AUTH" == "ResourcePrincipal" ]; then
    # OCI DevOps use resource principal
    # XXX Missing a lot of other variable... 
    # OCI_RESOURCE_PRINCIPAL_RPST=xxx.xxxbase64xxx.xxxx
    export TF_VAR_tenancy_ocid=`echo "${OCI_RESOURCE_PRINCIPAL_RPST#*\.}" | sed "s/\..*//" | base64 -d | jq -r .tenant`
    export TF_VAR_region=$OCI_RESOURCE_PRINCIPAL_REGION
  fi

  # Find TF_VAR_username based on TF_VAR_user_ocid or the opposite
  # In this order, else this is not reentrant. "oci iam user list" require more privileges.  
  if [ "$TF_VAR_user_ocid" != "" ]; then
    export TF_VAR_username=`oci iam user get --user-id $TF_VAR_user_ocid | jq -r '.data.name'`
  elif [ "$TF_VAR_username" != "" ]; then
    export TF_VAR_user_ocid=`oci iam user list --name $TF_VAR_username | jq -r .data[0].id`
  fi  
  auto_echo TF_VAR_username=$TF_VAR_username
  auto_echo TF_VAR_user_ocid=$TF_VAR_user_ocid
}

# Get the user interface URL
get_ui_url() {
  if [ "$TF_VAR_deploy_type" == "compute" ]; then
    if [ "$TF_VAR_tls" != "" ] && [ "$TF_VAR_tls" == "existing_ocid" ]; then
      export UI_URL=https://${TF_VAR_dns_name}/${TF_VAR_prefix}
    else 
      export UI_URL=http://${COMPUTE_IP}
      if [ "$TF_VAR_tls" != "" ] && [ "$TF_VAR_certificate_ocid" != "" ]; then
        export UI_HTTP=$UI_URL
        export UI_URL=https://${TF_VAR_dns_name}
      fi
    fi  
  elif [ "$TF_VAR_deploy_type" == "instance_pool" ]; then
    get_output_from_tfstate INSTANCE_POOL_LB_IP instance_pool_lb_ip 
    export UI_URL=http://${INSTANCE_POOL_LB_IP}
    if [ "$TF_VAR_tls" != "" ] && [ "$TF_VAR_certificate_ocid" != "" ]; then
      export UI_HTTP=$UI_URL
      export UI_URL=https://${TF_VAR_dns_name}
    fi
  elif [ "$TF_VAR_deploy_type" == "kubernetes" ]; then
    export TF_VAR_ingress_ip=`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
    export UI_URL=http://${TF_VAR_ingress_ip}/${TF_VAR_prefix}
    if [ "$TF_VAR_tls" != "" ] && [ "$TF_VAR_dns_name" != "" ]; then
      export UI_HTTP=$UI_URL
      export UI_URL=https://${TF_VAR_dns_name}/${TF_VAR_prefix}
    fi
  elif [ "$TF_VAR_deploy_type" == "function" ] || [ "$TF_VAR_deploy_type" == "container_instance" ]; then  
    export UI_URL=https://${APIGW_HOSTNAME}/${TF_VAR_prefix}
    if [ "$TF_VAR_tls" != "" ] && [ "$TF_VAR_certificate_ocid" != "" ]; then
      export UI_HTTP=$UI_URL
      export UI_URL=https://${TF_VAR_dns_name}/${TF_VAR_prefix}
    fi   
  fi
}

is_deploy_compute() {
  if [ "$TF_VAR_deploy_type" == "compute" ] || [ "$TF_VAR_deploy_type" == "instance_pool" ]; then
    return 0
  else
    return 1
  fi
}

livelabs_green_button() {
  # Lot of tests to be sure we are in a empty Green Button LiveLabs
  # compartment_ocid still undefined ? 
  if grep -q '# export TF_VAR_compartment_ocid=ocid1.compartment.xxxxx' $PROJECT_DIR/env.sh; then
    # vnc_ocid still undefined ? 
    if [ "$TF_VAR_vcn_ocid" != "__TO_FILL__" ]; then
      # Variables already set
      return
    fi
    # In cloud shell ? 
    if [ -z $OCI_CLI_CLOUD_SHELL ]; then 
      return
    fi
    # Whoami user format ? 
    W=$(whoami)
    W=${W^^}
    if [[ $W =~ ^LL.*_U.* ]]; then
      echo "LiveLabs - Green Button - whoami format detected"
    else
      return
    fi
    get_user_details
    # OCI User name format ? 
    if [[ $TF_VAR_username =~ ^LL.*-USER$ ]]; then
      echo "LiveLabs - Green Button - OCI User detected"
    else
      return
    fi

    export USER_BASE=`echo "${TF_VAR_username/-USER/}"` 
    echo USER_BASE=$USER_BASE

    export TF_VAR_compartment_ocid=`oci iam compartment list --compartment-id-in-subtree true --all | jq -c -r '.data[] | select(.name | contains("'$USER_BASE'")) | .id'`
    echo TF_VAR_compartment_ocid=$TF_VAR_compartment_ocid

    if [ "$TF_VAR_compartment_ocid" != "" ]; then
      sed -i "s&# export TF_VAR_compartment_ocid=ocid1.compartment.xxxxx&export TF_VAR_compartment_ocid=\"$TF_VAR_compartment_ocid\"&" $PROJECT_DIR/env.sh
      echo "TF_VAR_compartment_ocid stored in env.sh"
    fi  

    export TF_VAR_vcn_ocid=`oci network vcn list --compartment-id $TF_VAR_compartment_ocid | jq -c -r '.data[].id'`
    echo TF_VAR_vcn_ocid=$TF_VAR_vcn_ocid  
    if [ "$TF_VAR_vcn_ocid" != "" ]; then
      sed -i "s&TF_VAR_vcn_ocid=\"__TO_FILL__\"&TF_VAR_vcn_ocid=\"$TF_VAR_vcn_ocid\"&" $PROJECT_DIR/env.sh
      echo "TF_VAR_vcn_ocid stored in env.sh"
    fi  

    export TF_VAR_subnet_ocid=`oci network subnet list --compartment-id $TF_VAR_compartment_ocid | jq -c -r '.data[].id'`
    echo TF_VAR_subnet_ocid=$TF_VAR_subnet_ocid  
    if [ "$TF_VAR_subnet_ocid" != "" ]; then
      sed -i "s&TF_VAR_public_subnet_ocid=\"__TO_FILL__\"&TF_VAR_public_subnet_ocid=\"$TF_VAR_subnet_ocid\"&" $PROJECT_DIR/env.sh
      sed -i "s&TF_VAR_private_subnet_ocid=\"__TO_FILL__\"&TF_VAR_private_subnet_ocid=\"$TF_VAR_subnet_ocid\"&" $PROJECT_DIR/env.sh
      echo "TF_VAR_subnet_ocid stored in env.sh"
      # Set the real variables such that the first "build" works too.
      export TF_VAR_public_subnet_ocid=$TF_VAR_subnet_ocid
      export TF_VAR_private_subnet_ocid=$TF_VAR_subnet_ocid
    fi  
    
    # LiveLabs support only E4 Shapes
    # if grep -q '# export TF_VAR_instance_shape=VM.Standard.E4.Flex' $PROJECT_DIR/env.sh; then
    #   sed -i "s&# export TF_VAR_instance_shape=&export TF_VAR_instance_shape=&" $PROJECT_DIR/env.sh
    # fi

  fi
}

create_deployment_in_apigw() {
# Publish the API with an API Deployment to API Gateway
  if [ "$APIGW_DEPLOYMENT_OCID" != "" ]; then
   cat > $TARGET_DIR/api_deployment.json << EOF
{
  "loggingPolicies": {
    "accessLog": {
      "isEnabled": true
    },
    "executionLog": {
      "isEnabled": true,
      "logLevel": "string"
    }
  },  
  "routes": [
    {
      "path": "/app/{pathname*}",
      "methods": [ "ANY" ],
      "backend": {
        "type": "HTTP_BACKEND",
        "url": "$UI_URL/app/dept"
      }
    }
  ]
}
EOF
   oci api-gateway deployment create --compartment-id $TF_VAR_compartment_ocid --display-name "${TF_VAR_prefix}-apigw-deployment" --gateway-id $APIGW_DEPLOYMENT_OCID \
      --path-prefix "/${TF_VAR_prefix}" --specification file://$TARGET_DIR/api_deployment.json
  fi
}

configure() {
  if cat env.sh | grep -q "__TO_FILL__"; then
    echo Found these variables:
    cat env.sh | grep -q "__TO_FILL__"
    echo
    echo "Configure Mode"
    echo 
    echo 
    if [ "$1" != "--auto-approve" ]; then
      read -p "Do you want to proceed? (yes/no) " yn

      case $yn in 
        yes ) echo Configuring;;
      no ) echo Exiting...;
        exit;;
      * ) echo Invalid response;
        exit 1;;
      esac
    fi
  fi
} 

java_get_version() {
  JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
  JAVA_VERSION_NUMBER=$(echo $JAVA_VERSION | awk -F '.' '{print $1}')
}

java_home_exists() {
  if [ -d /$1 ]; then
    export JAVA_HOME=$1
    export PATH=$JAVA_HOME/bin:$PATH
    java -version
    return 0 
  fi
  echo "Not Found $1"
  return 1
}

java_check_exact_version() {
  java_get_version
  if [[ "$1" = "$JAVA_VERSION_NUMBER" ]]; then
    echo "Check Java Version OK: Request: $1 = Found: $JAVA_VERSION_NUMBER"
  else 
    echo "Check Java Version FAILED: Request: $1 != Found $JAVA_VERSION_NUMBER"
    exit 1
  fi
}

java_find_version() {
  JAVA_REQUEST=$1
  java_get_version
  if [[ "$JAVA_VERSION_NUMBER" < "$JAVA_REQUEST" ]]; then
    echo "Java Version too small: Found $JAVA_VERSION_NUMBER < Request: $JAVA_REQUEST"
    echo "Trying to find version $1 in standard Java directory"
    if java_home_exists /usr/lib64/graalvm/graalvm-java$JAVA_REQUEST; then
       return;
    fi; 
    if java_home_exists /usr/java/jdk-$JAVA_REQUEST; then
       return;
    fi; 
    echo "Not found"
    exit 1
  else 
    echo "Check Java Version OK: Request: $JAVA_REQUEST <= Found: $JAVA_VERSION_NUMBER"
  fi
}

certificate_validity() {
  CERT_DATE_VALIDITY=`oci certs-mgmt certificate get --certificate-id $TF_VAR_certificate_ocid | jq -r '.data["current-version"].validity["time-of-validity-not-after"]'`
  CERT_VALIDITY_DAY=`echo $((($(date -d $CERT_DATE_VALIDITY +%s) - $(date +%s))/86400))`
  echo "Certificate valid until: $CERT_DATE_VALIDITY"
  echo "Days left: $CERT_VALIDITY_DAY"
}

certificate_create() {
  echo "Creating or Updating certificate $TF_VAR_dns_name"
  CERT_CERT=$(cat $TF_VAR_certificate_dir/cert.pem)
  CERT_CHAIN=$(cat $TF_VAR_certificate_dir/chain.pem)
  CERT_PRIVKEY=$(cat $TF_VAR_certificate_dir/privkey.pem)
  if [ "$TF_VAR_certificate_ocid" == "" ]; then
    oci certs-mgmt certificate create-by-importing-config --compartment-id=$TF_VAR_compartment_ocid  --name=$TF_VAR_dns_name --cert-chain-pem="$CERT_CHAIN" --certificate-pem="$CERT_CERT"  --private-key-pem="$CERT_PRIVKEY" --wait-for-state ACTIVE --wait-for-state FAILED
  else
    oci certs-mgmt certificate update-certificate-by-importing-config-details --certificate-id=$TF_VAR_certificate_ocid --cert-chain-pem="$CERT_CHAIN" --certificate-pem="$CERT_CERT"  --private-key-pem="$CERT_PRIVKEY" --wait-for-state ACTIVE --wait-for-state FAILED
  fi
  exit_on_error
  TF_VAR_certificate_ocid=`oci certs-mgmt certificate list --all --compartment-id $TF_VAR_compartment_ocid --name $TF_VAR_dns_name | jq -r .data.items[0].id`
}

certificate_dir_before_terraform() {
  if [ "$TF_VAR_dns_name" == "" ]; then
    echo "ERROR: certificate_dir_before_terraform: TF_VAR_dns_name not defined"
    exit 1
  fi
  if [ -d $PROJECT_DIR/src/tls/$TF_VAR_dns_name ]; then
    export TF_VAR_certificate_dir=$PROJECT_DIR/src/tls/$TF_VAR_dns_name
    echo Using existing TF_VAR_certificate_dir=$TF_VAR_certificate_dir
  elif [ "$TF_VAR_certificate_dir" != "" ]; then
    # Check if the directory exists
    if [ -d $TF_VAR_certificate_dir ]; then
      echo Using existing TF_VAR_certificate_dir=$TF_VAR_certificate_dir
    else
      echo "ERROR: TF_VAR_certificate_dir directory does not exist ( $TF_VAR_certificate_dir )"
      exit 1
    fi
  elif [ "$TF_VAR_tls" == "new_dns_01" ]; then
    # Create a new certificate via DNS-01
    $BIN_DIR/tls_dns_create.sh 
    exit_on_error
    export TF_VAR_certificate_dir=$PROJECT_DIR/src/tls/$TF_VAR_dns_name
  fi

  if [ "$TF_VAR_deploy_type" == "compute" ]; then
    if [ -d target/compute/certificate ]; then
      echo "Certificate Directory exists already" 
    elif [ "$TF_VAR_certificate_dir" != "" ]; then
      mkdir -p target/compute/certificate
      cp $TF_VAR_certificate_dir/* target/compute/certificate/.
      cp src/tls/nginx_tls.conf target/compute/.
      sed -i "s/##DNS_NAME##/$TF_VAR_dns_name/" target/compute/nginx_tls.conf
    elif [ "$TF_VAR_tls" == "new_http_01" ]; then
      echo "New Certificate will be created after the deployment."      
    else 
      echo "ERROR: compute: certificate_dir_before_terraform: missing variables TF_VAR_certificate_dir"
      exit 1
    fi
  elif [ "$TF_VAR_deploy_type" == "kubernetes" ]; then
    if [ "$TF_VAR_tls" == "new_http_01" ]; then
      echo "New Certificate will be created after the deployment."      
    elif [ "$TF_VAR_certificate_dir" != "" ]; then
      echo "ERROR: kubernetes: certificate_dir_before_terraform: missing variables TF_VAR_certificate_dir"
      exit 1
    fi    
  elif [ "$TF_VAR_certificate_ocid" == "" ] && [ "$TF_VAR_certificate_dir" != "" ] ;  then
    certificate_create
  elif [ "$TF_VAR_certificate_ocid" != "" ]; then
    certificate_validity
  else 
    error_exit "certificate_dir_before_terraform: missing variables TF_VAR_certificate_ocid or TF_VAR_certificate_dir"
  fi  
}

# Certificate - Post Deploy
certificate_post_deploy() {
  if [ "$TF_VAR_tls" == "new_http_01" ]; then
    if [ "$TF_VAR_deploy_type" == "compute" ]; then
      certificate_run_certbot_http_01
    elif [ "$TF_VAR_deploy_type" == "kubernetes" ]; then
      echo "Skip: TLS - Kubernetes - HTTP_01"
    fi
  elif [ "$TF_VAR_deploy_type" == "kubernetes"  ]; then
    # Set the TF_VAR_ingress_ip
    get_ui_url 
    src/terraform/apply.sh --auto-approve -no-color
    exit_on_error
  fi  
}

# Generate a certificate on compute
certificate_run_certbot_http_01()
{
  if [ -z "$TF_VAR_certificate_email" ]; then
    error_exit "TF_VAR_certificate_email is not defined."
  fi   

  # Generate the certificate with Let'Encrypt on the COMPUTE
  scp -r -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path src/tls opc@$COMPUTE_IP:/home/opc/.
  exit_on_error
  ssh -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path opc@$COMPUTE_IP "export TF_VAR_dns_name=\"$TF_VAR_dns_name\";export TF_VAR_certificate_email=\"$TF_VAR_certificate_email\"; bash tls/certbot_http_01.sh 2>&1 | tee -a tls/certbot_http_01.log"
  scp -r -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path opc@$COMPUTE_IP:tls/certificate target/.
  exit_on_error
  export TF_VAR_certificate_dir=$PROJECT_DIR/target/certificate/$TF_VAR_dns_name
}
