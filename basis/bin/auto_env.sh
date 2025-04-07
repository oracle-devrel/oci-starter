#!/bin/bash

# PROJECT_DIR
if [[ -z "${PROJECT_DIR}" ]]; then
  echo "ERROR: PROJECT_DIR not set"
  exit 1
fi
# TARGET_DIR
export TARGET_DIR=$PROJECT_DIR/target
export STATE_FILE=$TARGET_DIR/terraform.tfstate
if [ ! -d $TARGET_DIR ]; then
  mkdir $TARGET_DIR
fi
# BIN_DIR
if [[ -z "${BIN_DIR}" ]]; then
  export BIN_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
fi

# ENV.SH
. $PROJECT_DIR/env.sh

# Autocomplete in bash
_starter_completions()
{
  COMPREPLY=($(compgen -W "build ssh terraform destroy generate deploy env help" "${COMP_WORDS[1]}"))
}
complete -F _starter_completions ./starter.sh

# group_common_env.sh
if [ -f $PROJECT_DIR/../group_common_env.sh ]; then
  . $PROJECT_DIR/../group_common_env.sh
elif [ -f $PROJECT_DIR/../../group_common_env.sh ]; then
  . $PROJECT_DIR/../../group_common_env.sh
fi

# Check the SHAPE
unset MISMATCH_PLATFORM
if [ "$TF_VAR_instance_shape" == "VM.Standard.A1.Flex" ]; then
  if [ `arch` != "aarch64" ]; then
    if [ "$TF_VAR_deploy_type" == "kubernetes" ] || [ "$TF_VAR_deploy_type" == "container_instance" ] || [ "$TF_VAR_deploy_type" == "function" ]; then
        MISMATCH_PLATFORM="ERROR: ARM (Ampere) build using Containers (Kubernetes / Cointainer Instance / Function) needs to run on ARM processor"
        DESIRED_PLATFORM="ARM (aarch64)"
    fi      
  fi
elif [ `arch` != "x86_64" ]; then
  if [ "$TF_VAR_deploy_type" == "kubernetes" ] || [ "$TF_VAR_deploy_type" == "container_instance" ] || [ "$TF_VAR_deploy_type" == "function" ]; then
    MISMATCH_PLATFORM="ERROR: X86_64 (AMD/Intel) build using Containers (Kubernetes / Cointainer Instance / Function) needs to run on X86 (AMD/Intel) processor"
    DESIRED_PLATFORM="X86_64"
  fi   
fi 

if [ "$MISMATCH_PLATFORM" != "" ]; then
  echo $MISMATCH_PLATFORM
  echo
  if [ "$OCI_CLI_CLOUD_SHELL" == "True" ];  then
    echo "Cloud Shell is not running in the correct Architecture. Please change it in the menu above."
    echo
    echo "Action:"
    echo "- Click the menu 'Actions' on top of Cloud Shell"
    echo "- Choose 'Architecture"
    echo "  - Choose $DESIRED_PLATFORM"
    echo "  - Click 'Confirm'"
    echo "- Restart the build"
  fi
  echo "Exiting. Please use the right CPU Architecture."
  exit 1
fi

# Enable BASH history for Stack Trace.
# - Do not store in HISTFILE 
# - Do not use it when env.sh is called from bash directly.
if [ "$0" != "-bash" ]; then
  unset HISTFILE
  set -o history -o histexpand
fi

# Shared BASH Functions
. $BIN_DIR/shared_bash_function.sh

if [ "$1" == "-no-auto" ]; then
  return
fi 

# Change the prompt
export PS1='[\[\e[0;3m\]\u@\h:\W\[\e[0m\]]$ '

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

# CONFIG.SH
. $BIN_DIR/config.sh

if ! command -v jq &> /dev/null; then
  error_exit "Unix command jq not found. Please install it."
fi

#-- PRE terraform ----------------------------------------------------------
if [ "$OCI_STARTER_VARIABLES_SET" == "$OCI_STARTER_CREATION_DATE" ]; then
  echo "Variables already set"
else
  #-- Check internet connection ---------------------------------------------
  wget -q --spider http://www.oracle.com

  if [ "$?" != "0" ]; then
    echo "---------------------------------------------------------------------"
    echo "WARNING - Are you sure that you have connection to Internet ? "
    if [ "$OCI_CLI_CLOUD_SHELL" == "True" ];  then
      echo "- For Cloud Shell, be sure that you have an connection to Internet."
      echo "  Please change the Network connection to Public Network."
      echo "  See: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro_topic-Cloud_Shell_Networking.htm"
    fi
    echo "---------------------------------------------------------------------"
  fi

  export OCI_STARTER_VARIABLES_SET=$OCI_STARTER_CREATION_DATE
  get_user_details

  # Availability Domain for FreeTier E2.1 Micro
  if [ "$TF_VAR_instance_shape" == "VM.Standard.E2.1.Micro" ]; then
     find_availabilty_domain_for_shape $TF_VAR_instance_shape
  elif [ "$TF_VAR_instance_shape" == "" ]; then
     # Check that the Fungible shape VM.Standard.x86.Generic exists in the tenancy
     oci compute shape list --compartment-id $TF_VAR_compartment_ocid --all | jq -r '.data[].shape' > $TARGET_DIR/shapes.list
     if grep -q "VM.Standard.x86.Generic" $TARGET_DIR/shapes.list; then
       auto_echo "Fungible shape VM.Standard.x86.Generic found"
     else
       export TF_VAR_instance_shape="VM.Standard.E4.Flex"
       echo "Warning: fungible shape VM.Standard.x86.Generic not found. Using $TF_VAR_instance_shape"
     fi
  fi

  # SSH keys
  if [ "$TF_VAR_ssh_private_path" == "" ] && [ -f $TARGET_DIR/ssh_key_starter ]; then 
    export TF_VAR_ssh_public_key=$(cat $TARGET_DIR/ssh_key_starter.pub)
    export TF_VAR_ssh_private_key=$(cat $TARGET_DIR/ssh_key_starter)
    export TF_VAR_ssh_private_path=$TARGET_DIR/ssh_key_starter
  fi

  # Echo
  auto_echo TF_VAR_tenancy_ocid=$TF_VAR_tenancy_ocid
  auto_echo TF_VAR_compartment_ocid=$TF_VAR_compartment_ocid
  auto_echo TF_VAR_region=$TF_VAR_region

  # DATE_POSTFIX (used for logs names)
  DATE_POSTFIX=`date '+%Y%m%d-%H%M%S'`

  # Kubernetes and OCIR
  if [ "$TF_VAR_deploy_type" == "kubernetes" ] || [ "$TF_VAR_deploy_type" == "function" ] || [ "$TF_VAR_deploy_type" == "container_instance" ] || [ -f $PROJECT_DIR/src/terraform/oke.tf ]; then
    export TF_VAR_namespace=`oci os ns get | jq -r .data`
    auto_echo TF_VAR_namespace=$TF_VAR_namespace
    export TF_VAR_email=mail@domain.com
    auto_echo TF_VAR_email=$TF_VAR_email
    # ex: OCIR region is using the key prefix: fra.ocir.io
    export TF_VAR_region_key=`oci iam region list --all --query "data[?name=='$TF_VAR_region']" | jq -r ".[0].key" | awk '{print tolower($0)}'`
    auto_echo TF_VAR_region_key=$TF_VAR_region_key
    export TF_VAR_ocir=${TF_VAR_region_key}.ocir.io
    auto_echo TF_VAR_ocir=$TF_VAR_ocir
    
    export DOCKER_PREFIX=${TF_VAR_ocir}/${TF_VAR_namespace}
    auto_echo DOCKER_PREFIX=$DOCKER_PREFIX
    export KUBECONFIG=$TARGET_DIR/kubeconfig_starter
  fi

  if [ "$TF_VAR_db_type" == "nosql" ]; then
    # export TF_VAR_nosql_endpoint="nosql.${TF_VAR_region}.oci.oraclecloud.com"
    export TF_VAR_nosql_endpoint=`oci nosql table list --compartment-id $TF_VAR_compartment_ocid -d 2>&1 | grep "Endpoint: https" | sed "s#.* https:\/\/##" | sed "s#/.*##"`
  fi

  # OpenAPI Spec
  if [ -f $PROJECT_DIR/src/app/openapi_spec.yaml ]; then
    export TF_VAR_openapi_spec=$(cat $PROJECT_DIR/src/app/openapi_spec.yaml)
  fi

  if [ "$TF_VAR_deploy_type" == "hpc" ]; then
    # Create synonyms for variables with another name in the oci-hpc stack
    export TF_VAR_ssh_key=$TF_VAR_ssh_public_key
    export TF_VAR_targetCompartment=$TF_VAR_compartment_ocid
    export TF_VAR_ad=`oci iam availability-domain list --compartment-id=$TF_VAR_tenancy_ocid | jq -r .data[0].name`
    export TF_VAR_bastion_ad=$TF_VAR_ad
  fi 
  
  # Base DB - version
  if [ -f $PROJECT_DIR/src/terraform/dbsystem.tf ]; then
    export TF_VAR_db_version=`oci db version list --compartment-id $TF_VAR_compartment_ocid --db-system-shape VM.Standard.E4.Flex | jq -r ".data | last | .version"`
  fi

  # TLS
  if [ "$TF_VAR_dns_name" != "" ] && [ "$TF_VAR_certificate_ocid" == "" ]; then
    export TF_VAR_certificate_ocid=`oci certs-mgmt certificate list --all --compartment-id $TF_VAR_compartment_ocid --name $TF_VAR_dns_name | jq -r .data.items[].id`
  fi

  # GIT
  if [ `git rev-parse --is-inside-work-tree 2>/dev/null` ]; then   
    export GIT_BRANCH=`git rev-parse --abbrev-ref HEAD`
    if [ "$GIT_BRANCH" != "" ]; then
      export TF_VAR_git_url=`git config --get remote.origin.url`
      if [[ "$TF_VAR_git_url" == *"github.com"* ]]; then
        S1=${TF_VAR_git_url/git@github.com:/https:\/\/github.com\/}        
        if [[ "$TF_VAR_git_url" == *".git"* ]]; then
          export TF_VAR_git_url=${S1/.git/\/blob\/}${GIT_BRANCH}
        else
          export TF_VAR_git_url=${S1}/blob/${GIT_BRANCH}
        fi
      elif [[ "$TF_VAR_git_url" == *"gitlab.com"* ]]; then
        S1=${TF_VAR_git_url/git@gitlab.com:/https:\/\/gitlab.com\/}        
        export TF_VAR_git_url=${S1/.git/\/-\/blob\/}${GIT_BRANCH}
      fi
      cd $PROJECT_DIR
      export GIT_RELATIVE_PATH=`git rev-parse --show-prefix`
      cd - > /dev/null
      export TF_VAR_git_url=${TF_VAR_git_url}/${GIT_RELATIVE_PATH}
      auto_echo TF_VAR_git_url=$TF_VAR_git_url
    fi  
  fi
fi


#-- POST terraform ----------------------------------------------------------
if [ -f $STATE_FILE ]; then
  # OBJECT_STORAGE_URL
  export OBJECT_STORAGE_URL=https://objectstorage.${TF_VAR_region}.oraclecloud.com

  # APIGW URL - not always used
  get_attribute_from_tfstate "APIGW_HOSTNAME" "starter_apigw" "hostname"
  # APIGW Deployment id
  get_attribute_from_tfstate "APIGW_DEPLOYMENT_OCID" "starter_apigw_deployment" "id"
 
  # Instance Pool
  if [ "$TF_VAR_deploy_type" == "instance_pool" ]; then
    # XXX Does not work with Resource Manager XXX
    # Check in the terraform state is the compute is already created.
    get_id_from_tfstate "COMPUTE_OCID" "starter_compute"
    if [ "$COMPUTE_OCID" != "" ]; then
      export TF_VAR_compute_ready="true"
    fi
  fi

  # Functions
  if [ "$TF_VAR_deploy_type" == "function" ]; then
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
  if [ "$TF_VAR_deploy_type" == "container_instance" ]; then
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

  # Compute
  get_output_from_tfstate "COMPUTE_IP" "compute_ip"
  
  # Bastion 
  get_output_from_tfstate "BASTION_IP" "bastion_public_ip"

  # Check if there is a BASTION SERVICE with a BASTION COMMAND
  get_output_from_tfstate "BASTION_COMMAND" "bastion_command"
  if [ "$BASTION_COMMAND" == "" ]; then
    if [ "$TF_VAR_deploy_type" == "public_compute" ]; then
      # Ideally BASTION_PROXY_COMMAND should be not used. But passing a empty value does not work...
      export COMPUTE_IP=$BASTION_IP
    fi
    export BASTION_USER_HOST="opc@$BASTION_IP"
    export BASTION_PROXY_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p $BASTION_USER_HOST"
  else 
    # export Ex: BASTION_COMMAND="ssh -i <privateKey>-o ProxyCommand=\"ssh -i <privateKey> -W %h:%p -p 22 ocid1.bastionsession.oc1.eu-frankfurt-1.xxxxxxxx@host.bastion.eu-frankfurt-1.oci.oraclecloud.com\" -p 22 opc@10.0.1.97"
    export BASTION_USER_HOST=`echo $BASTION_COMMAND | sed "s/.*ocid1.bastionsession/ocid1.bastionsession/" | sed "s/oci\.oraclecloud\.com.*/oci\.oraclecloud\.com/"`
    export BASTION_IP=`echo $BASTION_COMMAND | sed "s/.*opc@//"`
    export BASTION_PROXY_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p $BASTION_USER_HOST"
  fi

  # JDBC_URL
  get_output_from_tfstate "JDBC_URL" "jdbc_url"
  get_output_from_tfstate "DB_URL" "db_url"


  if [ "$TF_VAR_db_type" == "autonomous" ] || [ "$TF_VAR_db_type" == "database" ] ; then
    get_output_from_tfstate "ORDS_URL" "ords_url"
  fi

  if [ "$TF_VAR_db_type" == "database" ]; then
    get_attribute_from_tfstate "DB_NODE_IP" "starter_node_vnic" "private_ip_address"
  elif [ "$TF_VAR_db_type" == "db_free" ]; then
    get_output_from_tfstate "DB_NODE_IP" "db_free_ip"
  fi

  if [ "$TF_VAR_deploy_type" == "kubernetes" ] || [ -f $PROJECT_DIR/src/terraform/oke.tf ]; then
    # OKE
    get_output_from_tfstate "OKE_OCID" "oke_ocid"
    if [ -f $KUBECONFIG ]; then
      export TF_VAR_ingress_ip=`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
      export INGRESS_LB_OCID=`oci lb load-balancer list --compartment-id $TF_VAR_compartment_ocid | jq -r '.data[] | select(.["ip-addresses"][0]["ip-address"]=="'$TF_VAR_ingress_ip'") | .id'`  
    fi
  fi

  # JMS
  if [ -f $PROJECT_DIR/src/terraform/jms.tf ]; then 
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
