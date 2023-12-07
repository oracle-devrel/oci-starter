#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

# Start ssh-agent to do a Jump from the BASTION to the DB_NODE
eval "$(ssh-agent -s)"
ssh-add $TF_VAR_ssh_private_path
# Do not rely on DB_NODE_IP in case of group with DATABASE and DB_FREE like the testsuite
get_output_from_tfstate "MYSQL_COMPUTE_IP" "mysql_compute_ip"

scp -o StrictHostKeyChecking=no -oProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p opc@$BASTION_IP" src/db/db_node_init.sh opc@$MYSQL_COMPUTE_IP:/tmp/.
ssh -o StrictHostKeyChecking=no -oProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p opc@$BASTION_IP" opc@$MYSQL_COMPUTE_IP "chmod +x /tmp/db_node_init.sh; sudo -i -u root DB_PASSWORD=$TF_VAR_db_password TF_VAR_language=$TF_VAR_language /tmp/db_node_init.sh 2>&1 | tee -a /tmp/db_node_init.log"
