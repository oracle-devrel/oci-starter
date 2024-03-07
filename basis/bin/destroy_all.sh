#!/bin/bash
if [[ -z "${PROJECT_DIR}" ]]; then
  echo "Error: PROJECT_DIR not set"
  exit
fi
cd $PROJECT_DIR
SECONDS=0

# Call the script with --auto-approve to destroy without prompt

. env.sh -no-auto
title "OCI Starter - Destroy"
echo 
echo "Warning: This will destroy all the resources created by Terraform."
echo 
if [ "$1" != "--auto-approve" ]; then
  read -p "Do you want to proceed? (yes/no) " yn

  case $yn in 
  	yes ) echo Deleting;;
	no ) echo Exiting...;
		exit;;
	* ) echo Invalid response;
		exit 1;;
  esac
fi

. env.sh

# Check if there is something to destroy.
if [ -f $STATE_FILE ]; then
  export TF_RESOURCE=`cat $STATE_FILE | jq ".resources | length"`
  if [ "$TF_RESOURCE" == "0" ]; then
    echo "No resource in terraform state file. Nothing to destroy."
    exit 
  fi
else
  echo "File $STATE_FILE does not exist. Nothing to destroy."
  exit 
fi

if [ -f $PROJECT_DIR/src/terraform/oke.tf ]; then
  title "OKE Destroy"
  bin/oke_destroy.sh --auto-approve
elif [ "$TF_VAR_deploy_type" == "function" ]; then
  title "Delete Object Storage files"
  oci os object bulk-delete -bn ${TF_VAR_prefix}-public-bucket --force
fi

title "Terraform Destroy"
src/terraform/destroy.sh --auto-approve -no-color
exit_on_error

echo "Destroy time: ${SECONDS} secs"