### Commmon functions

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

  if [ -f $ROOT_DIR/../group_common/target/jms_agent_deploy.sh ]; then
    cp $ROOT_DIR/../group_common/target/jms_agent_deploy.sh $TARGET_DIR/compute/.
  fi
}

build_ui() {
  cd $SCRIPT_DIR
  if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
    mkdir -p ../../target/compute/ui
    cp -r ui/* ../../target/compute/ui/.
  elif [ "$TF_VAR_deploy_strategy" == "function" ]; then 
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
  fn build -v | tee $TARGET_DIR/fn_build.log
  if grep --quiet "built successfully" $TARGET_DIR/fn_build.log; then
     fn bump
     # Store the image name and DB_URL in files
     grep "built successfully" $TARGET_DIR/fn_build.log | sed "s/Function //" | sed "s/ built successfully.//" > $TARGET_DIR/fn_image.txt
     echo "$1" > $TARGET_DIR/fn_db_url.txt
     . ../../env.sh
     # Push the image to docker
     docker login ${TF_VAR_ocir} -u ${TF_VAR_namespace}/${TF_VAR_username} -p "${TF_VAR_auth_token}"
     docker push $TF_VAR_fn_image
  fi 

  # First create the Function using terraform
  # Run env.sh to get function image 
  cd $ROOT_DIR
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
}  

exit_on_error() {
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    echo "Success"
  else
    echo "Failed (RESULT=$RESULT)"
    exit $RESULT
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
  RESULT=`jq -r '.resources[] | select(.name=="'$2'") | .instances[0].attributes.'$3'' $STATE_FILE`
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

