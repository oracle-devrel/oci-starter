#!/bin/bash
export BIN_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export ROOT_DIR=${BIN_DIR%/*}

# Shared BASH Functions
. $BIN_DIR/shared_bash_function.sh

if grep -q 'TF_VAR_auth_token="__TO_FILL__"' $ROOT_DIR/env.sh; then
  echo "Generating a new AUTH_TOKEN"
  get_user_details
  echo TF_VAR_user_ocid=$TF_VAR_user_ocid
  oci iam auth-token create --description "OCI_STARTER_TOKEN" --user-id $TF_VAR_user_ocid > auth_token.log 2>&1
  export TF_VAR_auth_token=`cat auth_token.log | jq -r '.data.token'`

  cat auth_token.log
  rm auth_token.log

  if [ "$TF_VAR_auth_token" != "" ]; then
    sed -i "s&TF_VAR_auth_token=\"__TO_FILL__\"&TF_VAR_auth_token=\"$TF_VAR_auth_token\"&" $ROOT_DIR/env.sh
    echo "AUTH_TOKEN stored in env.sh"
    echo "> TF_VAR_auth_token=$TF_VAR_auth_token"
  fi  
else
  echo 'File env.sh does not contain: TF_VAR_auth_token="__TO_FILL__"'  
fi
