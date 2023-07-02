# Build_common.sh
#!/bin/bash
if [[ -z "${OCI_STARTER_BIN_DIR}" ]]; then
  echo "Error: OCI_STARTER_BIN_DIR not set"
  exit
fi
if [[ -z "${PROJECT_DIR}" ]]; then
  echo "Error: PROJECT_DIR not set"
  exit
fi
APP_DIR=`echo ${PROJECT_DIR} |sed -E "s/(.*)\/(.*)\//\2/g"`

# PROJECT_DIR should be set by the calling scripts 
cd $PROJECT_DIR
if [ -z "$TF_VAR_deploy_strategy" ]; then
  . $PROJECT_DIR/env.sh
else 
  . $OCI_STARTER_BIN_DIR/shared_bash_function.sh
fi 
