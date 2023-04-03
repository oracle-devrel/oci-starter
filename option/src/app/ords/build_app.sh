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

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  sed "s&##ORDS_URL##&$ORDS_URL&" nginx_app.locations > ../../target/compute/nginx_app.locations
else
  echo "No docker image needed"
fi  
