#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh

if [ "$1" == "compute" ]; then
  ssh opc@$COMPUTE_IP -i $TF_VAR_ssh_private_path
elif [ "$1" == "bastion" ]; then
  ssh opc@$BASTION_IP -i $TF_VAR_ssh_private_path
elif [ "$1" == "db_node" ]; then
  eval "$(ssh-agent -s)"
  ssh-add $TF_VAR_ssh_private_path
  ssh -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path -J opc@$BASTION_IP opc@$DB_NODE_IP 
else
  echo "Usage:"
  echo "- ssh.sh compute"
  echo "- ssh.sh bastion"
  echo "- ssh.sh db_node"    
  echo "  (Works only for DB SYSTEM in single node or RAC)"    
fi