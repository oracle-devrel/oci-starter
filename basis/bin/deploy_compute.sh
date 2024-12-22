#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

eval "$(ssh-agent -s)"
ssh-add $TF_VAR_ssh_private_path

# Using RSYNC allow to reapply the same command several times easily
# if command -v rsync &> /dev/null
# then
#  rsync -av -e "ssh -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path" target/compute/* opc@$COMPUTE_IP:.
# else
#   scp -r -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path target/compute/* opc@$COMPUTE_IP:/home/opc/.
# fi
while [ true ]; do
  ssh -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" opc@$COMPUTE_IP 2>/dev/null
  if [ $? -eq 0 ]; then
    break
  else
    echo "SSH connection to COMPUTE: $COMPUTE_IP failed. Attempt: $attempts"
    sleep 5
    attempts=$((attempts+1))
    if [ $attempts -eq 5 ]; then
      echo "Failed to establish SSH connection to COMPUTE: $COMPUTE_IP after 5 attempts."
      exit 1
    fi
  fi
done

scp -r -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" target/compute/* opc@$COMPUTE_IP:/home/opc/.
exit_on_error
ssh -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" opc@$COMPUTE_IP "export TF_VAR_java_version=\"$TF_VAR_java_version\";export TF_VAR_java_vm=\"$TF_VAR_java_vm\";export TF_VAR_language=\"$TF_VAR_language\";export JDBC_URL=\"$JDBC_URL\";export DB_URL=\"$DB_URL\";bash compute/compute_init.sh 2>&1 | tee -a compute/compute_init.log"

