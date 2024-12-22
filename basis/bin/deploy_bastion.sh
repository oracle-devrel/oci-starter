#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

# Create the DB table from the BASTION
# Using RSYNC allow to reapply the same command several times easily. 
function scp_bastion() {
  if command -v rsync &> /dev/null; then
    rsync -av -e "ssh -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path" src/db opc@$BASTION_IP:.
  else
    scp -r -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path src/db opc@$BASTION_IP:/home/opc/.
  fi
}

# Try 5 times to copy the files / wait 5 secs between each try
i=0
while [ true ]; do
 scp_bastion
 if [ $? -eq 0 ]; do
   break;
 elif [ "$i" == "5" ]; then
  echo "deploy_compute.sh: Maximum number of scp retries, ending."
  error_exit
 fi
 sleep 5
 i=$(($i+1))
done

ssh -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path opc@$BASTION_IP "export DB_USER=\"$TF_VAR_db_user\";export DB_PASSWORD=\"$TF_VAR_db_password\";export DB_URL=\"$DB_URL\"; bash db/db_init.sh 2>&1 | tee -a db/db_init.log"

