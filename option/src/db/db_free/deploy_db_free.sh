#!/usr/bin/env bash
if [ "$PROJECT_DIR" == "" ]; then
  echo "ERROR: PROJECT_DIR undefined. Please use starter.sh"
  exit 1
fi  
cd $PROJECT_DIR
. starter.sh env -silent

title "Deploy Database Free"
# Do not rely on DB_FREE_IP in case of group with DATABASE and DB_FREE like the testsuite
scp_via_bastion src/db/db_node_init.sh opc@$DB_FREE_IP:/tmp/.
ssh -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" opc@$DB_FREE_IP "chmod +x /tmp/db_node_init.sh; sudo -i -u root DB_PASSWORD=$TF_VAR_db_password TF_VAR_language=$TF_VAR_language /tmp/db_node_init.sh 2>&1 | tee -a /tmp/db_node_init.log"

