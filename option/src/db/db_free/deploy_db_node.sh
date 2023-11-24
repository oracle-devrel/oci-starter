#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

# Start ssh-agent to do a Jump from the BASTION to the DB_NODE
eval "$(ssh-agent -s)"
ssh-add $TF_VAR_ssh_private_path
# Do not rely on DB_NODE_IP in case of group with DATABASE and DB_FREE like the testsuite
get_output_from_tfstate "DB_FREE_IP" "db_free_ip"

# Wait that the host is up
# until ssh -o StrictHostKeyChecking=no -J opc@$BASTION_IP opc@$DB_FREE_IP echo test; do
#  sleep 5
#   echo "SSH - Waiting for $DB_FREE_IP"
# done

scp -o StrictHostKeyChecking=no -oProxyCommand="ssh -o StrictHostKeyChecking=no -W %h:%p opc@$BASTION_IP" src/db/db_node_init.sh opc@$DB_FREE_IP:/tmp/.
ssh -o StrictHostKeyChecking=no -J opc@$BASTION_IP opc@$DB_FREE_IP "chmod +x /tmp/db_node_init.sh; sudo -i -u root DB_PASSWORD=$TF_VAR_db_password TF_VAR_language=$TF_VAR_language /tmp/db_node_init.sh 2>&1 | tee -a /tmp/db_node_init.log"

