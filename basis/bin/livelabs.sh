#!/bin/bash
#
# For LiveLabs only, auto-fill automatically
# - TF_VAR_compartment_ocid, 
# - TF_VAR_vcn_ocid 
# - TF_VAR_public_subnet_ocid, TF_VAR_private_subnet_ocid
export BIN_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export PROJECT_DIR=${BIN_DIR%/*}

# Shared BASH Functions
. $BIN_DIR/shared_bash_function.sh

if grep -q '# export TF_VAR_compartment_ocid=ocid1.compartment.xxxxx' $PROJECT_DIR/env.sh; then
  get_user_details
  if [[ $TF_VAR_username =~ ^LL.*-USER$ ]]; then
    echo "GREEN BUTTON detected"
  else
    echo "GREEN BUTTON not detected. Exiting"
    exit
  fi

  export USER_BASE=`echo "${TF_VAR_username/-USER/}"` 
  echo USER_BASE=$USER_BASE

  export TF_VAR_compartment_ocid=`oci iam compartment list --compartment-id-in-subtree true --all | jq -c -r '.data[] | select(.name | contains("'$USER_BASE'")) | .id'`
  echo TF_VAR_compartment_ocid=$TF_VAR_compartment_ocid

  if [ "$TF_VAR_compartment_ocid" != "" ]; then
    sed -i "s&# export TF_VAR_compartment_ocid=ocid1.compartment.xxxxx&export TF_VAR_compartment_ocid=\"$TF_VAR_compartment_ocid\"&" $PROJECT_DIR/env.sh
    echo "TF_VAR_compartment_ocid stored in env.sh"
  fi  

  export TF_VAR_vcn_ocid=`oci network vcn list --compartment-id $TF_VAR_compartment_ocid | jq -c -r '.data[].id'`
  echo TF_VAR_vcn_ocid=$TF_VAR_vcn_ocid  
  if [ "$TF_VAR_vcn_ocid" != "" ]; then
    sed -i "s&TF_VAR_vcn_ocid=\"__TO_FILL__\"&TF_VAR_vcn_ocid=\"$TF_VAR_vcn_ocid\"&" $PROJECT_DIR/env.sh
    echo "TF_VAR_vcn_ocid stored in env.sh"
  fi  

  export TF_VAR_subnet_ocid=`oci network subnet list --compartment-id $TF_VAR_compartment_ocid | jq -c -r '.data[].id'`
  echo TF_VAR_subnet_ocid=$TF_VAR_subnet_ocid  
  if [ "$TF_VAR_subnet_ocid" != "" ]; then
    sed -i "s&TF_VAR_public_subnet_ocid=\"__TO_FILL__\"&TF_VAR_public_subnet_ocid=\"$TF_VAR_subnet_ocid\"&" $PROJECT_DIR/env.sh
    sed -i "s&TF_VAR_private_subnet_ocid=\"__TO_FILL__\"&TF_VAR_private_subnet_ocid=\"$TF_VAR_subnet_ocid\"&" $PROJECT_DIR/env.sh
    echo "TF_VAR_subnet_ocid stored in env.sh"
  fi  
else
  echo 'File env.sh does not contain: # export TF_VAR_compartment_ocid=ocid1.compartment.xxxxx'  
fi
