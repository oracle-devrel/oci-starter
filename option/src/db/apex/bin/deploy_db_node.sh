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

scp -r -o StrictHostKeyChecking=no -oProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p opc@$BASTION_IP" src/db/db_node_init opc@$DB_NODE_IP:/tmp
ssh -o StrictHostKeyChecking=no -oProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p opc@$BASTION_IP" opc@$DB_NODE_IP "chmod +x /tmp/db_node_init/db_node_init.sh; sudo -i -u root DB_PASSWORD=$TF_VAR_db_password DB_URL=$DB_URL TF_VAR_language=$TF_VAR_language /tmp/db_node_init/db_node_init.sh 2>&1 | tee -a /tmp/db_node_init/db_node_init.log"

