#!/bin/bash
# Build_app.sh
#
# Build the group_common_env.sh file.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../../env.sh -no-auto
. $BIN_DIR/build_common.sh

append () {
   echo "$1" >> ../../../group_common_env.sh
}

conditional_append() {
  if [[ "$COMMON" == *",$1,"* ]]; then
    append "# $1" 
    append "export $2=${!2}"
  fi
}

if [ -z "$TF_VAR_vcn_ocid" ]; then
   get_id_from_tfstate "TF_VAR_vcn_ocid" "starter_vcn"
fi   

if [ -z "$TF_VAR_public_subnet_ocid" ]; then
   get_id_from_tfstate "TF_VAR_public_subnet_ocid" "starter_public_subnet"
fi   

if [ -z "$TF_VAR_private_subnet_ocid" ]; then
   get_id_from_tfstate "TF_VAR_private_subnet_ocid" "starter_private_subnet"
fi   

if [ -z "$TF_VAR_atp_ocid" ]; then
   get_id_from_tfstate "TF_VAR_atp_ocid" "starter_atp" 
fi   

if [ -z "$TF_VAR_db_ocid" ]; then
   get_id_from_tfstate "TF_VAR_db_ocid" "starter_dbsystem" 
fi   

if [ -z "$TF_VAR_mysql_ocid" ]; then
   get_id_from_tfstate "TF_VAR_mysql_ocid" "starter_mysql" 
fi   

if [ -z "$TF_VAR_psql_ocid" ]; then
   get_id_from_tfstate "TF_VAR_psql_ocid" "starter_psql" 
fi   

if [ -z "$TF_VAR_opensearch_ocid" ]; then
   get_id_from_tfstate "TF_VAR_opensearch_ocid" "starter_opensearch" 
fi   

if [ -z "$TF_VAR_nosql_ocid" ]; then
   get_id_from_tfstate "TF_VAR_nosql_ocid" "starter_nosql_table" 
fi   

get_output_from_tfstate "TF_VAR_oke_ocid" "oke_ocid"

if [ -z "$TF_VAR_apigw_ocid" ]; then
  get_id_from_tfstate "TF_VAR_apigw_ocid" "starter_apigw"
fi   

if [ -z "$TF_VAR_fnapp_ocid" ]; then
   get_id_from_tfstate "TF_VAR_fnapp_ocid" "starter_fn_application"
fi   

if [ -z "$TF_VAR_bastion_ocid" ]; then
  get_id_from_tfstate "TF_VAR_bastion_ocid" "starter_bastion"
fi

if [ -z "$TF_VAR_compute_ocid" ]; then
   get_id_from_tfstate "TF_VAR_compute_ocid" "starter_instance"
fi   

if [ -z "$TF_VAR_log_group_ocid" ]; then
   get_id_from_tfstate "TF_VAR_log_group_ocid" "starter_log_group"
fi   

COMMON=,${TF_VAR_group_common},

cat > ../../../group_common_env.sh <<'EOT' 
export COMMON_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Commment to create an new oci-starter compartment automatically
EOT

if [ -z "$TF_VAR_compartment_ocid" ]; then
  append "export TF_VAR_compartment_ocid=__TO_FILL__"
else
  append "export TF_VAR_compartment_ocid=$TF_VAR_compartment_ocid"
fi

cat >> ../../../group_common_env.sh <<'EOT' 

# API Management
EOT

if [ -z "$APIM_HOST" ]; then
  append "# export APIM_HOST=xxxx-xxx.adb.region.oraclecloudapps.com"
else
  append "export APIM_HOST=$APIM_HOST"
fi
if [ -z "$TF_VAR_instance_shape" ]; then
  append "# export TF_VAR_instance_shape=VM.Standard.E3.Flex"
else
  append "export TF_VAR_instance_shape=$TF_VAR_instance_shape"
fi   

cat >> ../../../group_common_env.sh <<EOT 

# Common Resources Name (Typically: dev, test, qa, prod)
export TF_VAR_group_name=$TF_VAR_prefix

# Landing Zone
# export TF_VAR_lz_appdev_cmp_ocid=$TF_VAR_compartment_ocid
# export TF_VAR_lz_database_cmp_ocid=$TF_VAR_compartment_ocid
# export TF_VAR_lz_network_cmp_ocid=$TF_VAR_compartment_ocid
# export TF_VAR_lz_security_cmp_ocid=$TF_VAR_compartment_ocid

# Network
export TF_VAR_vcn_ocid=$TF_VAR_vcn_ocid
export TF_VAR_public_subnet_ocid=$TF_VAR_public_subnet_ocid
export TF_VAR_private_subnet_ocid=$TF_VAR_private_subnet_ocid

# Bastion
export TF_VAR_bastion_ocid=$TF_VAR_bastion_ocid

EOT

conditional_append atp TF_VAR_atp_ocid
conditional_append database TF_VAR_db_ocid
conditional_append mysql TF_VAR_mysql_ocid
conditional_append psql TF_VAR_psql_ocid
conditional_append opensearch TF_VAR_opensearch_ocid
conditional_append nosql TF_VAR_nosql_ocid
conditional_append oke TF_VAR_oke_ocid
conditional_append apigw TF_VAR_apigw_ocid
conditional_append fnapp TF_VAR_fnapp_ocid
conditional_append compute TF_VAR_compute_ocid

if [ -n "$TF_VAR_log_group_ocid" ]; then
  append "export TF_VAR_log_group_ocid=$TF_VAR_log_group_ocid"
fi   

cat >> ../../../group_common_env.sh <<EOT 

# Database Password
export TF_VAR_db_password="$TF_VAR_db_password"
# Auth Token
export TF_VAR_auth_token="$TF_VAR_auth_token"

EOT

cat >> ../../../group_common_env.sh <<'EOT' 

# SSH Keys
if [ -f $COMMON_DIR/group_common/target/ssh_key_starter ]; then
  export TF_VAR_ssh_public_key=$(cat $COMMON_DIR/group_common/target/ssh_key_starter.pub)
  export TF_VAR_ssh_private_key=$(cat $COMMON_DIR/group_common/target/ssh_key_starter)
  export TF_VAR_ssh_private_path=$COMMON_DIR/group_common/target/ssh_key_starter
fi  
EOT

echo
echo "File group_common_env.sh created."
echo
