#!/bin/bash
# Add the API to the API Management Portal
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

if [ "$APIM_HOST" != "" ] && [ "$TF_VAR_ui_strategy" == "api" ]; then
  FIRST_LETTER_UPPERCASE=`echo $TF_VAR_prefix | sed -e "s/\b\(.\)/\u\1/g"`
  APIGW_URL=https://${APIGW_HOSTNAME}/${TF_VAR_prefix}  
  curl -k "https://${APIM_HOST}/ords/apim/rest/add_api?git_repo_url=${TF_VAR_git_url}&impl_name=${FIRST_LETTER_UPPERCASE}&icon_url=${TF_VAR_language}&runtime_console=https://cloud.oracle.com/api-gateway/gateways/$TF_VAR_apigw_ocid/deployments/$APIGW_DEPLOYMENT_OCID&version=${GIT_BRANCH}&endpoint_url=${APIGW_URL}/app/dept&endpoint_git_path=src/terraform/apigw_existing.tf&spec_git_path=src/app/openapi_spec.yaml&spec_type=OpenAPI"
fi