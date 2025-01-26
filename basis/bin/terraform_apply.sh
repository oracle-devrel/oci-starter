#!/bin/bash
if [ "$PROJECT_DIR" == "" ]; then
  echo "ERROR: PROJECT_DIR undefined. Please use starter.sh terraform apply"
  exit 1
fi  
cd $PROJECT_DIR

. starter.sh env -silent
. $BIN_DIR/shared_infra_as_code.sh
cd $PROJECT_DIR/src/terraform
infra_as_code_apply $@
exit_on_error
