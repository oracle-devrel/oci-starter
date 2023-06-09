#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

# Using RSYNC allow to reapply the same command several times easily. 
if command -v rsync &> /dev/null
then
  rsync -av -e "ssh -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path" src/db opc@$BASTION_IP:.
else
  scp -r -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path src/db opc@$BASTION_IP:/home/opc/.
fi
ssh -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path opc@$BASTION_IP "export DB_USER=\"$TF_VAR_db_user\";export DB_PASSWORD=\"$TF_VAR_db_password\";export DB_URL=\"$DB_URL\"; bash db/db_init.sh 2>&1 | tee -a db/db_init.log"

# Run something directly on the DB_NODE ? (ex RAC)
if [ -f src/db/db_node_init.sh ]; then
  # Start ssh-agent to do a Jump from the bastion to the DB_NODE_IP
  eval "$(ssh-agent -s)"
  ssh-add $TF_VAR_ssh_private_path
  scp -o StrictHostKeyChecking=no -oProxyCommand="ssh -W %h:%p opc@$BASTION_IP" src/db/db_node_init.sh opc@$DB_NODE_IP:/tmp/.
  ssh -o StrictHostKeyChecking=no -J opc@$BASTION_IP opc@$DB_NODE_IP "export PREFIX=\"$PREFIX\"; chmod +x /tmp/db_node_init.sh; sudo su - oracle /tmp/db_node_init.sh 2>&1 | tee -a /tmp/db_node_init.log"
fi