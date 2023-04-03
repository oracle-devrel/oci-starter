#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Call the script with --auto-approve to destroy without prompt

echo "WARNING"
echo 
echo "This will destroy all the resources created by Terraform."
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
if [ -f $ROOT_DIR/src/terraform/oke.tf ]; then
  bin/oke_destroy.sh --auto-approve
elif [ "$TF_VAR_deploy_strategy" == "function" ]; then
  # delete the UI website
  oci os object bulk-delete -bn ${TF_VAR_prefix}-public-bucket --force
fi

src/terraform/destroy.sh --auto-approve -no-color
