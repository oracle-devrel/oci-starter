#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

# Using RSYNC allow to reapply the same command several times easily
if command -v rsync &> /dev/null
then
  rsync -av -e "ssh -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path" target/compute/* opc@$COMPUTE_IP:.
else
  scp -r -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path target/compute/* opc@$COMPUTE_IP:/home/opc/.
fi
ssh -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path opc@$COMPUTE_IP "export TF_VAR_java_version=\"$TF_VAR_java_version\";export TF_VAR_java_vm=\"$TF_VAR_java_vm\";export TF_VAR_language=\"$TF_VAR_language\";export JDBC_URL=\"$JDBC_URL\";export DB_URL=\"$DB_URL\";bash compute_bootstrap.sh 2>&1 | tee -a compute_bootstrap.log"
