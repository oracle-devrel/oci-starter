#!/bin/bash
export BIN_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export ROOT_DIR=${BIN_DIR%/*}

# Shared BASH Functions
. $BIN_DIR/shared_bash_function.sh

# Silent mode (default is not silent)
if [ "$1" == "-silent" ]; then
  SILENT_MODE=true
else
  unset SILENT_MODE
fi 

# XXXXXX TO REMOVE WHEN PY_OCI_STARTER.PY is done
if [ -v REPOSITORY_NAME ]; then
  return
fi 

if [ "$TF_VAR_db_password" == "__TO_FILL__" ]; then
  echo "Generating password for the database"
  export TF_VAR_db_password=`python3 $BIN_DIR/gen_password.py`
  sed -i "s&TF_VAR_db_password=\"__TO_FILL__\"&TF_VAR_db_password=\"$TF_VAR_db_password\"&" $ROOT_DIR/env.sh
  echo "Password stored in env.sh"
  echo "> TF_VAR_db_password=$TF_VAR_db_password"
fi

# -- env.sh
# Do not stop if __TO_FILL__ are not replaced if TF_VAR_group_name exist in env variable
# XXX -> It would be safer to check also for TF_VAR_xxx containing __TO_FILL__ too
if [ ! -f $ROOT_DIR/../group_common_env.sh ]; then 
  if grep -q "__TO_FILL__" $ROOT_DIR/env.sh; then
    echo "Error: missing environment variables."
    echo
    echo "Edit the file env.sh. Some variables needs to be filled:" 
    echo `cat env.sh | grep __TO_FILL__` 
    exit
  fi
fi  

if ! command -v jq &> /dev/null; then
  echo "Command jq could not be found. Please install it"
  echo "Ex on linux: sudo yum install jq -y"
  exit 1
fi

export TARGET_DIR=$ROOT_DIR/target
if [ ! -d $TARGET_DIR ]; then
  mkdir $TARGET_DIR
fi

#-- PRE terraform ----------------------------------------------------------
if [ "$OCI_STARTER_VARIABLES_SET" == "$OCI_STARTER_CREATION_DATE" ]; then
  echo "Variables already set"
else
  export OCI_STARTER_VARIABLES_SET=$OCI_STARTER_CREATION_DATE
  get_user_details

  # Availability Domain for FreeTier E2.1 Micro
  if [ "$TF_VAR_instance_shape" == "VM.Standard.E2.1.Micro" ]; then
     find_availabilty_domain_for_shape $TF_VAR_instance_shape
  fi

  # SSH keys
  if [ -f $TARGET_DIR/ssh_key_starter ]; then 
    export TF_VAR_ssh_public_key=$(cat $TARGET_DIR/ssh_key_starter.pub)
    export TF_VAR_ssh_private_key=$(cat $TARGET_DIR/ssh_key_starter)
    export TF_VAR_ssh_private_path=$TARGET_DIR/ssh_key_starter
  fi

  if [ -z "$TF_VAR_compartment_ocid" ]; then
    echo "WARNING: compartment_ocid is not defined."
    # echo "        The components will be created in the root compartment."
    # export TF_VAR_compartment_ocid=$TF_VAR_tenancy_ocid

    echo "         The components will be created in the 'oci-starter' compartment"
    STARTER_OCID=`oci iam compartment list --name oci-starter | jq .data[0].id -r`
    if [ -z "$STARTER_OCID" ]; then
      echo "Creating a new 'oci-starter' compartment"
      oci iam compartment create --compartment-id $TF_VAR_tenancy_ocid --description oci-starter --name oci-starter --wait-for-state ACTIVE > $TARGET_DIR/compartment.log 2>&1
      STARTER_OCID=`cat $TARGET_DIR/compartment.log | grep \"id\" | sed 's/"//g' | sed "s/.*id: //g" | sed "s/,//g"`
      while [ "$NAME" != "oci-starter" ]
      do
        oci iam compartment get --compartment-id=$STARTER_OCID > $TARGET_DIR/waiting.log 2>&1
        if grep -q "NotAuthorizedOrNotFound" $TARGET_DIR/waiting.log; then
          echo "Waiting"
          sleep 2
        else
          NAME=`cat $TARGET_DIR/waiting.log | jq -r .data.name`
        fi
      done
    else
      echo "Using the existing 'oci-starter' Compartment"
    fi 
    export TF_VAR_compartment_ocid=$STARTER_OCID
    auto_echo "TF_VAR_compartment_ocid=$STARTER_OCID"
    echo "Compartment created"
  fi

  # Echo
  auto_echo TF_VAR_tenancy_ocid=$TF_VAR_tenancy_ocid
  auto_echo TF_VAR_compartment_ocid=$TF_VAR_compartment_ocid
  auto_echo TF_VAR_region=$TF_VAR_region

  # Kubernetes and OCIR
  if [ "$TF_VAR_deploy_strategy" == "kubernetes" ] || [ "$TF_VAR_deploy_strategy" == "function" ] || [ "$TF_VAR_deploy_strategy" == "container_instance" ] || [ -f $ROOT_DIR/src/terraform/oke.tf ]; then
    export TF_VAR_namespace=`oci os ns get | jq -r .data`
    auto_echo TF_VAR_namespace=$TF_VAR_namespace
    export TF_VAR_email=mail@domain.com
    auto_echo TF_VAR_email=$TF_VAR_email
    export TF_VAR_ocir=${TF_VAR_region}.ocir.io
    auto_echo TF_VAR_ocir=$TF_VAR_ocir
    
    export DOCKER_PREFIX=${TF_VAR_ocir}/${TF_VAR_namespace}
    auto_echo DOCKER_PREFIX=$DOCKER_PREFIX
    export KUBECONFIG=$ROOT_DIR/target/kubeconfig_starter
  fi

  # OpenAPI Spec
  if [ -f $ROOT_DIR/src/app/openapi_spec.yaml ]; then
    export TF_VAR_openapi_spec=$(cat $ROOT_DIR/src/app/openapi_spec.yaml)
  fi

  if [ "$TF_VAR_deploy_strategy" == "hpc" ]; then
    # Create synonyms for variables with another name in the oci-hpc stack
    export TF_VAR_ssh_key=$TF_VAR_ssh_public_key
    export TF_VAR_targetCompartment=$TF_VAR_compartment_ocid
    export TF_VAR_ad=`oci iam availability-domain list --compartment-id=$TF_VAR_tenancy_ocid | jq -r .data[0].name`
    export TF_VAR_bastion_ad=$TF_VAR_ad
  fi 

  # GIT 
  export GIT_BRANCH=`git rev-parse --abbrev-ref HEAD`
  if [ "$GIT_BRANCH" != "" ]; then
    export TF_VAR_git_url=`git config --get remote.origin.url`
    if [[ "$TF_VAR_git_url" == *"github.com"* ]]; then
      S1=${TF_VAR_git_url/git@github.com:/https:\/\/github.com\/}        
      export TF_VAR_git_url=${S1/.git/\/blob\/}${GIT_BRANCH}
    elif [[ "$TF_VAR_git_url" == *"gitlab.com"* ]]; then
      S1=${TF_VAR_git_url/git@gitlab.com:/https:\/\/gitlab.com\/}        
      export TF_VAR_git_url=${S1/.git/\/-\/blob\/}${GIT_BRANCH}
    fi

    cd $ROOT_DIR
    export GIT_RELATIVE_PATH=`git rev-parse --show-prefix`
    cd -
    export TF_VAR_git_url=${TF_VAR_git_url}/${GIT_RELATIVE_PATH}
    echo $TF_VAR_git_url
  fi
fi

#-- POST terraform ----------------------------------------------------------
export STATE_FILE=$TARGET_DIR/terraform.tfstate
if [ -f $STATE_FILE ]; then
  # OBJECT_STORAGE_URL
  export OBJECT_STORAGE_URL=https://objectstorage.${TF_VAR_region}.oraclecloud.com

  # API GW
  if [ "$TF_VAR_deploy_strategy" == "function" ] || [ "$TF_VAR_deploy_strategy" == "container_instance" ] || [ "$TF_VAR_ui_strategy" == "api" ]; then
    # APIGW URL
    get_attribute_from_tfstate "APIGW_HOSTNAME" "starter_apigw" "hostname"
    # APIGW Deployment id
    get_attribute_from_tfstate "APIGW_DEPLOYMENT_OCID" "starter_apigw_deployment" "id"
  fi

  # Functions
  if [ "$TF_VAR_deploy_strategy" == "function" ]; then
    # OBJECT Storage URL
    export BUCKET_URL="https://objectstorage.${TF_VAR_region}.oraclecloud.com/n/${TF_VAR_namespace}/b/${TF_VAR_prefix}-public-bucket/o"

    # Function OCID
    get_attribute_from_tfstate "FN_FUNCTION_OCID" "starter_fn_function" "id"

    auto_echo "file=$TARGET_DIR/fn_image.txt" 
    if [ -f $TARGET_DIR/fn_image.txt ]; then
      export TF_VAR_fn_image=`cat $TARGET_DIR/fn_image.txt`
      auto_echo TF_VAR_fn_image=$TF_VAR_fn_image
      export TF_VAR_fn_db_url=`cat $TARGET_DIR/fn_db_url.txt`
      auto_echo TF_VAR_fn_db_url=$TF_VAR_fn_db_url
    fi   
  fi

  # Container Instance
  if [ "$TF_VAR_deploy_strategy" == "container_instance" ]; then
    if [ -f $TARGET_DIR/docker_image_ui.txt ] || [ -f $TARGET_DIR/docker_image_app.txt ] ; then
      if [ -f $TARGET_DIR/docker_image_ui.txt ]; then
        export TF_VAR_docker_image_ui=`cat $TARGET_DIR/docker_image_ui.txt`
      else
        export TF_VAR_docker_image_ui="busybox"      
      fi
      if [ -f $TARGET_DIR/docker_image_app.txt ]; then
        export TF_VAR_docker_image_app=`cat $TARGET_DIR/docker_image_app.txt`
      else
        export TF_VAR_docker_image_app="busybox"      
      fi
    fi
  fi

  # Compute
  if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
    get_attribute_from_tfstate "COMPUTE_IP" "starter_instance" "public_ip"
  fi

  # Bastion 
  get_attribute_from_tfstate "BASTION_IP" "starter_bastion" "public_ip"

  # JDBC_URL
  get_output_from_tfstate "JDBC_URL" "jdbc_url"
  get_output_from_tfstate "DB_URL" "db_url"

  if [ "$TF_VAR_db_strategy" == "autonomous" ]; then
    get_output_from_tfstate "ORDS_URL" "ords_url"
  fi

  if [ "$TF_VAR_deploy_strategy" == "kubernetes" ] || [ -f $ROOT_DIR/src/terraform/oke.tf ]; then
    # OKE
    get_output_from_tfstate "OKE_OCID" "oke_ocid"
  fi

  # JMS
  if [ -f $ROOT_DIR/src/terraform/jms.tf ]; then 
    if [ ! -f $TARGET_DIR/jms_agent_deploy.sh ]; then
      get_output_from_tfstate "FLEET_OCID" "fleet_ocid"
      get_output_from_tfstate "INSTALL_KEY_OCID" "install_key_ocid"
       # JMS requires a "jms" tag namespace / tag "fleet_ocid" (that is unique and should not be deleted by terraform destroy) 
      TAG_NAMESPACE_OCID=`oci iam tag-namespace list --compartment-id=$TF_VAR_tenancy_ocid | jq -r '.data[] | select(.name=="jms") | .id'`
      if [ "$TAG_NAMESPACE_OCID" == "" ]; then
        oci iam tag-namespace create --compartment-id $TF_VAR_tenancy_ocid --description jms --name jms | tee $TARGET_DIR/jms_tag_namespace.log
        TAG_NAMESPACE_OCID=`cat $TARGET_DIR/jms_tag_namespace.log | jq -r .data.id`
        oci iam tag create --description fleet_ocid --name fleet_ocid --tag-namespace-id $TAG_NAMESPACE_OCID | tee $TARGET_DIR/jms_tag_definition.log
      fi  
      oci jms fleet generate-agent-deploy-script --file $TARGET_DIR/jms_agent_deploy.sh --fleet-id $FLEET_OCID --install-key-id $INSTALL_KEY_OCID --is-user-name-enabled true --os-family "LINUX"
    fi 
  fi
fi
