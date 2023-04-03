#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
sed "s/XX_TERRAFORM_STATE_URL_XX/$TF_VAR_terraform_state_url/g" terraform.template.tf > terraform/terraform.tf

cd terraform
terraform init -no-color
terraform apply --auto-approve