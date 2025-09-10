#!/usr/bin/env bash
if [ "$PROJECT_DIR" == "" ]; then
  echo "ERROR: PROJECT_DIR undefined. Please use starter.sh"
  exit 1
fi  
cd $PROJECT_DIR
. starter.sh env -silent

title "Deploy RAC"
# Deploy directly on the DB_NODE (ex RAC)
# Start ssh-agent to do a Jump from the BASTION to the DB_NODE
scp_via_bastion src/db/db_node_init.sh opc@$DB_NODE_IP:/tmp/.
ssh -o StrictHostKeyChecking=no -oProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p opc@$BASTION_IP" opc@$DB_NODE_IP "chmod +x /tmp/db_node_init.sh; sudo -i -u oracle PREFIX=$TF_VAR_prefix /tmp/db_node_init.sh 2>&1 | tee -a /tmp/db_node_init.log"
