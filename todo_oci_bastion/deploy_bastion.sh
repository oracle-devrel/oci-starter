#!/usr/bin/env bash
if [ "$PROJECT_DIR" == "" ]; then
  echo "ERROR: PROJECT_DIR undefined. Please use starter.sh deploy bastion"
  exit 1
fi  
cd $PROJECT_DIR
. starter.sh env -silent

get_output_from_tfstate "BASTION_COMMAND" "bastion_command"
if [ "$BASTION_COMMAND" == "" ]; then
  # VM Bastion
  BASTION_USER_HOST = "opc@$$BASTION_IP"
else
  # OCI Bastion Service
  # export Ex: BASTION_COMMAND="ssh -i <privateKey>-o ProxyCommand=\"ssh -i <privateKey> -W %h:%p -p 22 ocid1.bastionsession.oc1.eu-frankfurt-1.xxxxxxxx@host.bastion.eu-frankfurt-1.oci.oraclecloud.com\" -p 22 opc@10.0.1.97"
  export BASTION_USER_HOST=`echo $BASTION_COMMAND | sed "s/.*ocid1.bastionsession/ocid1.bastionsession/" | sed "s/oci\.oraclecloud\.com.*/oci\.oraclecloud\.com/"`
  export BASTION_IP=`echo $BASTION_COMMAND | sed "s/.*opc@//"`
fi
auto_echo "BASTION_USER_HOST=$BASTION_USER_HOST"

eval "$(ssh-agent -s)"
ssh-add $TF_VAR_ssh_private_path

scp -r -o StrictHostKeyChecking=no -oProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p $BASTION_USER_HOST" src/db opc@$BASTION_IP:/home/opc/.

get_attribute_from_tfstate "APIGW_HOSTNAME" "starter_apigw_private" "hostname"
ssh -o StrictHostKeyChecking=no -oProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p $BASTION_USER_HOST" opc@$BASTION_IP "export APIGW_HOSTNAME=\"$APIGW_HOSTNAME\";export DB_USER=\"$TF_VAR_db_user\";export DB_PASSWORD=\"$TF_VAR_db_password\";export DB_URL=\"$DB_URL\"; bash db/db_init.sh 2>&1 | tee -a db/db_init.log"

