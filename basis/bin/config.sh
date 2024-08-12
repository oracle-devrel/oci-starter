#!/bin/bash
title "CONFIG.SH"

accept_request() {
    if [ "$ACCEPT_ALL" == "TRUE" ]; then
      return 0;
    fi
    echo "$REQUEST"
    echo ""  
    read -r -p "Please confirm. [Yes/No/All] " response
    case "$response" in
        [aA][lL][lL])
            export ACCEPT_ALL="TRUE"
            return 0
            ;;
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            echo "Skipping $1"
            return 1 
    esac
}

read_ocid() {
  while [ "${!1}" == "__TO_FILL__" ]; do
    read -r -p "$2 (Format: $3.xxxxx):" response
    if [[ $response == $3* ]]; then
      export $1=$response
      sed -i "s&$1=\"__TO_FILL__\"&$1=\"${!1}\"&" $PROJECT_DIR/env.sh              
      sed -i "s&# export $1=[.*]&export TF_VAR_compartment_ocid=\"$TF_VAR_compartment_ocid\"&" $PROJECT_DIR/env.sh
      echo "$1 stored in env.sh"            
      echo            
    else
      echo "Wrong format $response"
      echo            
    fi
  done    
}

# DB_PASSWORD
if [ "$TF_VAR_db_password" == "__TO_FILL__" ]; then
  export REQUEST="Generate password for the database ? (TF_VAR_db_password) ?"
  if accept_request; then
    echo "Generating password for the database"
    export TF_VAR_db_password=`python3 $BIN_DIR/gen_password.py`
    sed -i "s&TF_VAR_db_password=\"__TO_FILL__\"&TF_VAR_db_password=\"$TF_VAR_db_password\"&" $PROJECT_DIR/env.sh
    echo "Password stored in env.sh"
    echo "> TF_VAR_db_password=$TF_VAR_db_password"
  fi 
fi

# AUTH_TOKEN
if [ "$TF_VAR_auth_token" == "__TO_FILL__" ]; then
  export REQUEST="Generate OCI Auth token ? (TF_VAR_auth_token) ?"
  if accept_request; then
    echo "Generating OCI Auth token"
    . $BIN_DIR/gen_auth_token.sh
  fi 
fi

# Livelabs Green Button (Autodetect compartment/vcn/subnet)
livelabs_green_button

read_ocid TF_VAR_compartment_ocid "Enter your compartment OCID" ocid1.compartment 
read_ocid TF_VAR_vcn_ocid "Enter your Virtual Cloud Network (VCN) OCID" ocid1.vcn 
read_ocid TF_VAR_public_subnet_ocid "Enter your Public Subnet OCID" ocid1.subnet
read_ocid TF_VAR_private_subnet_ocid "Enter your Private Subnet OCID" ocid1.subnet
read_ocid TF_VAR_oke_ocid "Enter your Kubernetes Cluster (OKE) OCID" ocid1.cluster
read_ocid TF_VAR_atp_ocid "Enter your Autonomous Datababase OCID" ocid1.autonomousdatabase
read_ocid TF_VAR_db_ocid "Enter your Base Database OCID" ocid1.dbsystem
read_ocid TF_VAR_mysql_ocid "Enter your MySQL OCID" ocid1.mysqldbsystem
read_ocid TF_VAR_vault_ocid "Enter your Vault OCID" ocid1.vault

# ? # read_ocid TF_VAR_vault_secret_authtoken_ocid "Enter your Private Subnet OCID" ocid1.subnet

# -- env.sh
# Do not stop if __TO_FILL__ are not replaced if TF_VAR_group_name exist in env variable
# XXX -> It would be safer to check also for TF_VAR_xxx containing __TO_FILL__ too

if declare -p | grep -q "__TO_FILL__"; then
  echo
  echo "ERROR: missing environment variables"
  echo
  declare -p | grep __TO_FILL__
  echo
  echo "Edit the file env.sh. Some variables needs to be filled:" 
  cat env.sh | grep __TO_FILL__
  error_exit "Missing environment variables."
fi  


