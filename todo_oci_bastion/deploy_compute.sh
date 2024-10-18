#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

get_output_from_tfstate "BASTION_COMMAND" "bastion_command"
if [ "$BASTION_COMMAND" == "" ]; then
  BASTION_USER_HOST = "opc@$$BASTION_IP"
else
  # export Ex: BASTION_COMMAND="ssh -i <privateKey>-o ProxyCommand=\"ssh -i <privateKey> -W %h:%p -p 22 ocid1.bastionsession.oc1.eu-frankfurt-1.xxxxxxxx@host.bastion.eu-frankfurt-1.oci.oraclecloud.com\" -p 22 opc@10.0.1.97"
  export BASTION_USER_HOST=`echo $BASTION_COMMAND | sed "s/.*ocid1.bastionsession/ocid1.bastionsession/" | sed "s/oci\.oraclecloud\.com.*/oci\.oraclecloud\.com/"`
  export BASTION_IP=`echo $BASTION_COMMAND | sed "s/.*opc@//"`
fi
auto_echo "BASTION_USER_HOST=$BASTION_USER_HOST"

eval "$(ssh-agent -s)"
ssh-add $TF_VAR_ssh_private_path

scp -r -o StrictHostKeyChecking=no -oProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p $BASTION_USER_HOST" target/compute/*  opc@$BASTION_IP:/home/opc/.
ssh -o StrictHostKeyChecking=no -oProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p $BASTION_USER_HOST" opc@$BASTION_IP "export TF_VAR_java_version=\"$TF_VAR_java_version\";export TF_VAR_java_vm=\"$TF_VAR_java_vm\";export TF_VAR_language=\"$TF_VAR_language\";export JDBC_URL=\"$JDBC_URL\";export DB_URL=\"$DB_URL\";export DB_USER=\"$TF_VAR_db_user\";export DB_PASSWORD=\"$TF_VAR_db_password\";export TF_VAR_namespace=\"$TF_VAR_namespace\";export TF_VAR_prefix=\"$TF_VAR_prefix\";bash compute/compute_init.sh 2>&1 | tee -a compute/compute_init.log"

