#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/../..
. starter.sh env -silent

title "Deploy MySQL in Public Compute"
scp_via_bastion src/db/db_node_init.sh opc@$MYSQL_COMPUTE_IP:/tmp/.
ssh -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" opc@$MYSQL_COMPUTE_IP "chmod +x /tmp/db_node_init.sh; sudo -i -u root DB_PASSWORD=$TF_VAR_db_password TF_VAR_language=$TF_VAR_language /tmp/db_node_init.sh 2>&1 | tee -a /tmp/db_node_init.log"

