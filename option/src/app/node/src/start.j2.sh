#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

{%- if db_family == "nosql" -%}
export TF_VAR_compartment_ocid=`curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r .compartmentId`
export TF_VAR_region=`curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r .region`
{%- else -%}
export DB_USER="##DB_USER##"
export DB_PASSWORD="##DB_PASSWORD##"
export DB_URL="##DB_URL##"
{%- endif -%}

node rest.js > app.log 2>&1 

