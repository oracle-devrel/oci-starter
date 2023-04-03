#!/bin/bash
# Build_app.sh
#
# Compute:
# - build the code 
# - create a $ROOT/compute/app directory with the compiled files
# - and a start.sh to start the program
# Docker:
# - build the image
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../../bin/build_common.sh
java_build_common

if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
  mvn package -Dpackaging=native-image
else 
  mvn package 
fi
exit_on_error  

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  cp start.sh target/.

  mkdir -p ../../target/compute/app
  cp -r target/* ../../target/compute/app/.
  # Replace the user and password in the start file
  replace_db_user_password_in_file ../../target/compute/app/start.sh  
else
  docker image rm ${TF_VAR_prefix}-app:latest
  if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
    docker build -f Dockerfile.native -t ${TF_VAR_prefix}-app:latest .
  else
    docker build -t ${TF_VAR_prefix}-app:latest . 
  fi
  exit_on_error    
fi  
