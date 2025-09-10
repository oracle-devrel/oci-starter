#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# FN uses more variable like OCIR_HOST that are not available with ./env.sh -no-auto
. $SCRIPT_DIR/../../starter.sh env 
. $BIN_DIR/build_common.sh

# fn -v deploy --app ${TF_VAR_prefix}-fn-application
# fn invoke ${TF_VAR_prefix}-fn-application ${TF_VAR_prefix}-fn-function
# fn config function ${TF_VAR_prefix}-fn-application fn-starter DB_USER $TF_VAR_db_user
# fn config function ${TF_VAR_prefix}-fn-application fn-starter DB_PASSWORD $TF_VAR_db_password
# fn config function ${TF_VAR_prefix}-fn-application fn-starter DB_URL $JDBC_URL
# Function eu-frankfurt-1.ocir.io/frsxwtjslf35/fn-starter:0.0.30 built successfully.
# fn invoke mg-fn-application go-atp-html-fn-function

# Deploy with terraform
# Then Work-around: terraforms is not able to create a APIGW with dynamic multiple backends
{%- if language == "ords" %}
# ORDS: OCI Function is not used. Nothing to do
{%- else %}
build_function
{%- endif %}
exit_on_error "build_function"

