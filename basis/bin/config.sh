#!/bin/bash
if declare -p | grep -q "__TO_FILL__"; then
  title "CONFIG.SH"
  
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

  # OCIDs
  read_ocid TF_VAR_compartment_ocid "Compartment" ocid1.compartment 
  read_ocid TF_VAR_vcn_ocid "Virtual Cloud Network (VCN)" ocid1.vcn 
  read_ocid TF_VAR_public_subnet_ocid "Public Subnet" ocid1.subnet
  read_ocid TF_VAR_private_subnet_ocid "Private Subnet" ocid1.subnet
  read_ocid TF_VAR_oke_ocid "Kubernetes Cluster (OKE)" ocid1.cluster
  read_ocid TF_VAR_atp_ocid "Autonomous Datababase" ocid1.autonomousdatabase
  read_ocid TF_VAR_db_ocid "Base Database" ocid1.dbsystem
  read_ocid TF_VAR_mysql_ocid "MySQL" ocid1.mysqldbsystem
  read_ocid TF_VAR_psql_ocid "PostgreSQL" ocid1.postgresqldbsystem
  read_ocid TF_VAR_opensearch_ocid "OpenSearch" ocid1.opensearchcluster
  read_ocid TF_VAR_nosql_ocid "NoSQL Table" ocid1.nosqltable
  read_ocid TF_VAR_vault_ocid "Vault" ocid1.vault
  read_ocid TF_VAR_oic_ocid "Integration" ocid1.integrationinstance
  read_ocid TF_VAR_apigw_ocid "API Gateway" ocid1.apigateway
  read_ocid TF_VAR_fnapp_ocid "Function Application" ocid1.fnapp
  read_ocid TF_VAR_log_group_ocid "Log Group" ocid1.loggroup
  read_ocid TF_VAR_bastion_ocid "Bastion Instance" ocid1.instance
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
fi 


