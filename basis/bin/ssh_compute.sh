#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh

eval "$(ssh-agent -s)"
ssh-add $TF_VAR_ssh_private_path
ssh -o StrictHostKeyChecking=no $BASTION_PROXY_COMMAND opc@$COMPUTE_IP