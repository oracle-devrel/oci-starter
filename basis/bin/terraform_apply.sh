#!/bin/bash
if [ "$PROJECT_DIR" == "" ]; then
  echo "ERROR: PROJECT_DIR undefined. Please use starter.sh terraform apply"
  exit 1
fi  
cd $PROJECT_DIR

. starter.sh env -silent
. $BIN_DIR/shared_infra_as_code.sh
cd $PROJECT_DIR/src/terraform

# First build is auto-approved. Else you need to pass --auto-approve flag.
if [ "$1" == "--auto-approve" ]; then
  export TERRAFORM_FLAG="--auto-approve"
elif [ -f $STATE_FILE ]; then
  echo "$STATE_FILE detected."
else
  infra_as_code_precheck
  export TERRAFORM_FLAG="--auto-approve"
fi

infra_as_code_apply $TERRAFORM_FLAG $@
exit_on_error
