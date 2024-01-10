# Build_common.sh
#!/bin/bash
if [[ -z "${BIN_DIR}" ]]; then
  echo "Error: BIN_DIR not set"
  exit 1
fi
if [[ -z "${PROJECT_DIR}" ]]; then
  echo "Error: PROJECT_DIR not set"
  exit 1
fi

APP_DIR=`echo ${SCRIPT_DIR} |sed -E "s#(.*)/(.*)#\2#"`
cd $SCRIPT_DIR

if [ -z "$TF_VAR_deploy_type" ]; then
  . $PROJECT_DIR/env.sh
else 
  . $BIN_DIR/shared_bash_function.sh
fi 
