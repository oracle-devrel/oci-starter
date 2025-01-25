#!/bin/bash
export PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -f $PROJECT_DIR/bin/oci-starter.sh ]; then
  export BIN_DIR=$PROJECT_DIR/bin
else 
  BIN_PATH=$(which oci-starter.sh)
  if [ "$BIN_PATH" == "" ]; then
    echo "ERROR: oci-starter.sh not found."
    exit 1
  else
    export BIN_DIR=$(dirname "$BIN_PATH")
    echo "$BIN_DIR"
  fi 
fi  
echo "$BIN_DIR"
. $BIN_DIR/oci-starter.sh $@
exit ${PIPESTATUS[0]}