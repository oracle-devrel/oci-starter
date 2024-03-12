#!/bin/bash
set -e

infra_as_code_plan() {
  if [ "$TF_VAR_infra_as_code" == "resource_manager" ]; then
     resource_manager_plan
  else
    if [ "$TF_VAR_infra_as_code" == "terraform_object_storage" ]; then
      sed "s/XX_TERRAFORM_STATE_URL_XX/$TF_VAR_terraform_state_url/g" terraform.template.tf > terraform/terraform.tf
    fi  
    terraform init -no-color
    terraform plan
  fi
}

infra_as_code_apply() {
  if [ "$TF_VAR_infra_as_code" == "resource_manager" ]; then
    resource_manager_create_or_update
    resource_manager_apply
    exit_on_error
  else
    if [ "$TF_VAR_infra_as_code" == "terraform_object_storage" ]; then
      sed "s/XX_TERRAFORM_STATE_URL_XX/$TF_VAR_terraform_state_url/g" terraform.template.tf > terraform/terraform.tf
    fi  
    terraform init -no-color -upgrade
    terraform apply $@
    exit_on_error
  fi
}

infra_as_code_destroy() {
  if [ "$TF_VAR_infra_as_code" == "resource_manager" ]; then
    resource_manager_destroy
  else
    terraform init -upgrade
    terraform destroy $@
  fi
}

resource_manager_get_stack() {
  if [ ! -f $TARGET_DIR/resource_manager_stackid ]; then
    rs_echo "Stack does not exists ( file target/resource_manager_stackid not found )"
    exit
  fi    
  source $TARGET_DIR/resource_manager_stackid
}

rs_echo() {
  echo "Resource Manager: $1"
}

resource_manager_create_or_update() {
  rs_echo "Create Stack"

  ZIP_FILE_PATH=$TARGET_DIR/resource_manager_$TF_VAR_prefix.zip
  VAR_FILE_PATH=$TARGET_DIR/resource_manager_variables.json
  if [ -f $TARGET_DIR/resource_manager_stackid ]; then
     echo "Stack exists already ( file target/resource_manager_stackid found )"
     DATE_POSTFIX=`date '+%Y%m%d-%H%M%S'`
     mv $ZIP_FILE_PATH $ZIP_FILE_PATH.$DATE_POSTFIX
     mv $VAR_FILE_PATH $VAR_FILE_PATH.$DATE_POSTFIX
  fi    

  if [ -f $ZIP_FILE_PATH ]; then
    rm $ZIP_FILE_PATH
  fi  
  zip -r $ZIP_FILE_PATH * -x "*.sh"

  # Transforms the variables in a JSON format
  # This is a complex way to get them. But it works for multi line variables like TF_VAR_private_key
  excluded=$(env | sed -n 's/^\([A-Z_a-z][0-9A-Z_a-z]*\)=.*/\1/p' | grep -v 'TF_VAR_')
  sh -c 'unset $1; export -p' sh "$excluded" > $TARGET_DIR/tf_var.sh
  # Nasty WA trick for OCI Devops (not a proper fix)
  sed -i "s/export maven.home//" $TARGET_DIR/tf_var.sh

  echo -n "{" > $VAR_FILE_PATH
  cat $TARGET_DIR/tf_var.sh | sed "s/export TF_VAR_/\"/g" | sed "s/=\"/\": \"/g" | sed ':a;N;$!ba;s/\"\n/\", /g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/$/}/'>> $VAR_FILE_PATH

  if [ -f $TARGET_DIR/resource_manager_stackid ]; then
    if cmp -s $ZIP_FILE_PATH $ZIP_FILE_PATH.$DATE_POSTFIX; then
      rs_echo "Zip files are identical"
      if cmp -s $VAR_FILE_PATH $VAR_FILE_PATH.$DATE_POSTFIX; then
        rs_echo "Var files are identical"
        exit
      else 
        rs_echo "Var files are different"
      fi 
    else 
      rs_echo "Zip files are different"
    fi
    resource_manager_get_stack
  	STACK_ID=$(oci resource-manager stack update --stack-id $STACK_ID --config-source $ZIP_FILE_PATH --variables file://$VAR_FILE_PATH --force --query 'data.id' --raw-output)
    rs_echo "Updated stack id: ${STACK_ID}"
  else 
  	STACK_ID=$(oci resource-manager stack create --compartment-id $TF_VAR_compartment_ocid --config-source $ZIP_FILE_PATH --display-name $TF_VAR_prefix-resource-manager  --variables file://$VAR_FILE_PATH --query 'data.id' --raw-output)
    rs_echo "Created stack id: ${STACK_ID}"
    echo "export STACK_ID=$STACK_ID" > $TARGET_DIR/resource_manager_stackid
  fi  
}

resource_manager_plan() {
  resource_manager_get_stack

  rs_echo "Create Plan Job"
  CREATED_PLAN_JOB_ID=$(oci resource-manager job create-plan-job --stack-id $STACK_ID --wait-for-state SUCCEEDED --wait-for-state FAILED --query 'data.id' --raw-output)
  echo "Created Plan Job Id: ${CREATED_PLAN_JOB_ID}"

  rs_echo "Get Job Logs"
  echo $(oci resource-manager job get-job-logs --job-id $CREATED_PLAN_JOB_ID) > $TARGET_DIR/plan_job_logs.txt
  echo "Saved Job Logs"
}

resource_manager_apply() {
  resource_manager_get_stack 

  rs_echo "Create Apply Job"
  # Max 2000 secs wait time (1200 secs is sometimes too short for OKE+DB)
  CREATED_APPLY_JOB_ID=$(oci resource-manager job create-apply-job --stack-id $STACK_ID --execution-plan-strategy=AUTO_APPROVED --wait-for-state SUCCEEDED --wait-for-state FAILED --max-wait-seconds 2000 --query 'data.id' --raw-output)
  echo "Created Apply Job Id: ${CREATED_APPLY_JOB_ID}"

  rs_echo "Get job"
  STATUS=$(oci resource-manager job get --job-id $CREATED_APPLY_JOB_ID  --query 'data."lifecycle-state"' --raw-output)
  
  oci resource-manager job get-job-logs-content --job-id $CREATED_APPLY_JOB_ID | tee > $TARGET_DIR/tf_apply.log

  rs_echo "Get stack state"
  oci resource-manager stack get-stack-tf-state --stack-id $STACK_ID --file $TARGET_DIR/terraform.tfstate

  # Check the result of the destroy JOB and stop deletion if required
  if [ "$STATUS" != "SUCCEEDED" ]; then
    rs_echo "ERROR: Status ($STATUS) is not SUCCEEDED"
    exit 1 # Exit with error
  fi  
}

resource_manager_destroy() {
  resource_manager_get_stack 
  
  rs_echo "Create Destroy Job"
  CREATED_DESTROY_JOB_ID=$(oci resource-manager job create-destroy-job --stack-id $STACK_ID --execution-plan-strategy=AUTO_APPROVED --wait-for-state SUCCEEDED --wait-for-state FAILED --query 'data.id' --raw-output)
  echo "Created Destroy Job Id: ${CREATED_DESTROY_JOB_ID}"

  rs_echo "Get job"
  STATUS=$(oci resource-manager job get --job-id $CREATED_DESTROY_JOB_ID  --query 'data."lifecycle-state"' --raw-output)

  oci resource-manager job get-job-logs-content --job-id $CREATED_DESTROY_JOB_ID | tee > $TARGET_DIR/tf_destroy.log

  # Check the result of the destroy JOB and stop deletion if required
  if [ "$STATUS" != "SUCCEEDED" ]; then
    rs_echo "ERROR: Status ($STATUS) is not SUCCEEDED"
    exit 1 # Exit with error
  fi  

  rs_echo "Delete Stack"
  oci resource-manager stack delete --stack-id $STACK_ID --force
  echo "Deleted Stack Id: ${STACK_ID}"
  rm $TARGET_DIR/resource_manager_stackid
}

# echo "Creating Import Tf State Job"
# CREATED_IMPORT_JOB_ID=$(oci resource-manager job create-import-tf-state-job --stack-id $STACK_ID --tf-state-file "$JOB_TF_STATE" --wait-for-state SUCCEEDED --query 'data.id' --raw-output)
# echo "Created Import Tf State Job Id: ${CREATED_IMPORT_JOB_ID}"
