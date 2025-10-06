#!/usr/bin/env bash
if [ "$PROJECT_DIR" == "" ]; then
  echo "ERROR: PROJECT_DIR undefined. Please use starter.sh."
  exit 1
fi  
cd $PROJECT_DIR

# Shared BASH Functions
. $BIN_DIR/shared_bash_function.sh

if grep -q 'auth_token="__TO_FILL__"' $PROJECT_DIR/terraform.tfvars; then
  echo "Generating a new AUTH_TOKEN (Home Region=$TF_VAR_home_region)"
  get_user_details
  oci iam auth-token create --description "OCI_STARTER_TOKEN" --user-id $TF_VAR_current_user_ocid --region $TF_VAR_home_region > auth_token.log 2>&1
  exit_error "gen_auth_token - Go to  OCI Console/Profile/<your name>/Tokens and Key. Try to generate an Auth Token and place it in terraform.tfvars"
  export TF_VAR_auth_token=`cat auth_token.log | jq -r '.data.token'`

  cat auth_token.log
  rm auth_token.log

  if [ "$TF_VAR_auth_token" != "" ]; then
    sed -i "s&auth_token=\"__TO_FILL__\"&auth_token=\"$TF_VAR_auth_token\"&" $PROJECT_DIR/terraform.tfvars
    echo "AUTH_TOKEN stored in terraform.tfvars"
    echo "> auth_token=$TF_VAR_auth_token"
  fi  
else
  echo 'File terraform.tfvars does not contain: auth_token="__TO_FILL__"'  
fi

