#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

eval "$(ssh-agent -s)"
ssh-add $TF_VAR_ssh_private_path

function scp_compute() {
  #if command -v rsync &> /dev/null; then
  ##  Using RSYNC allow to reapply the same command several times easily. 
  #  rsync -av -e "ssh -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path" target/compute/* opc@$COMPUTE_IP:.
  # else
  scp -r -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" target/compute/* opc@$COMPUTE_IP:/home/opc/.
  # fi
}

# Try 5 times to copy the files / wait 5 secs between each try
i=0
while [ true ]; do
 scp_compute
 if [ $? -eq 0 ]; do
   break;
 elif [ "$i" == "5" ]; then
  echo "deploy_compute.sh: Maximum number of scp retries, ending."
  error_exit
 fi
 sleep 5
 i=$(($i+1))
done

ssh -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" opc@$COMPUTE_IP "export TF_VAR_java_version=\"$TF_VAR_java_version\";export TF_VAR_java_vm=\"$TF_VAR_java_vm\";export TF_VAR_language=\"$TF_VAR_language\";export JDBC_URL=\"$JDBC_URL\";export DB_URL=\"$DB_URL\";bash compute/compute_init.sh 2>&1 | tee -a compute/compute_init.log"

