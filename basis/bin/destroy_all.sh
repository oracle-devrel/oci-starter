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

# Confidential APP
get_attribute_from_tfstate "CONFIDENTIAL_APP_OCID" "starter_confidential_app" "id"
if [ "$CONFIDENTIAL_APP_OCID" != "" ]; then
  # Disable the app before destroy... (Bug?) if not destroy fails...
  echo "Confidential app: set active to false"
  get_output_from_tfstate "IDCS_URL" "idcs_url"
  # Remove trailing /
  IDCS_URL=${IDCS_URL::-1}
  oci identity-domains app-status-changer put --active false --app-status-changer-id $CONFIDENTIAL_APP_OCID --schemas '["urn:ietf:params:scim:schemas:oracle:idcs:AppStatusChanger"]' --endpoint $IDCS_URL  --force
fi

# OKE
if [ -f $PROJECT_DIR/src/terraform/oke.tf ]; then
  title "OKE Destroy"
  bin/oke_destroy.sh --auto-approve
fi

# Buckets
cleanBucket() {
  BUCKET_NAME=$1
  export TF_OBJECT_STORAGE=`cat $STATE_FILE | jq -r '.resources[] | select(.instances[0].attributes.name=="'${BUCKET_NAME}'") | .instances[].attributes.bucket_id'`
  if [ "$TF_OBJECT_STORAGE" != "" ] && [ "$TF_OBJECT_STORAGE" != "null" ]; then
    title "Delete Object Storage"
    oci os bucket delete --bucket-name $BUCKET_NAME --namespace-name $TF_VAR_namespace --empty --force
  else
    echo "No Object storage $BUCKET_NAME"
  fi  
}
for BUCKET_NAME in `cat $STATE_FILE | jq -r '.resources[] | select(.type=="oci_objectstorage_bucket") | .instances[].attributes.name'`;
do
   cleanBucket $BUCKET_NAME
done;

title "Terraform Destroy"
bin/terraform_destroy.sh --auto-approve -no-color
exit_on_error

echo "Destroy time: ${SECONDS} secs"
