#!/bin/bash
if [ "$PROJECT_DIR" == "" ]; then
  echo "ERROR: PROJECT_DIR undefined. Please use starter.sh"
  exit 1
fi  
cd $PROJECT_DIR
. env.sh -no-auto
. $BIN_DIR/build_common.sh

# Call build_common to push the ${TF_VAR_prefix}-app:latest and ui:latest to OCIR Docker registry
ocir_docker_push

# Run terraform a second time
cd $PROJECT_DIR
. env.sh 
$BIN_DIR/terraform_apply.sh --auto-approve -no-color
