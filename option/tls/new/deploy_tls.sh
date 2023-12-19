#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

# Generate a certificate on compute or bastion
generate_certificate()
{
  if [ -z "$CERTIFICATE_GENERATE_EMAIL" ]; then
    echo "Error: CERTIFICATE_GENERATE_EMAIL is not defined."
    exit 1
  fi   
  if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
      # Generate the certificate with Let'Encrypt on the COMPUTE
      TLS_IP=$COMPUTE_IP
  else
      # Generate the certificate with Let'Encrypt on the BASTION
      TLS_IP=$BASTION_IP
  fi
  scp -r -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path bin/tls opc@$TLS_IP:/home/opc/.
  ssh -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path opc@$TLS_IP "export TF_VAR_dns_name=\"$TF_VAR_dns_name\";export CERTIFICATE_GENERATE_DNS=\"$CERTIFICATE_GENERATE_EMAIL\"; bash tls/tls_init.sh 2>&1 | tee -a tls/tls_init.log"
  scp -r -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path opc@$TLS_IP:tls/certificate target/.
  export CERTIFICATE_PATH=$PROJECT_DIR/target/certificate/$TF_VAR_dns_name
}

if [ -z $TF_VAR_dns_name ]; then
  echo "Error: TF_VAR_dns_name is not defined."
  exit 1
fi

# Associate the IP with the DNS
# Done in Terraform

# For compute, it is simpler. Generate a new certificate on the compute. Done.
if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  generate_certificate
  exit 
fi

# XXXXX
# Maybe check 
# - if the validaty is more than 15 days then do nothing 
# - else refresh the certificate
# XXXXX

if [ "$TF_VAR_certificate_ocid" != "" ]; then
  CERT_DATE_VALIDITY=`oci certs-mgmt certificate list --all --compartment-id $TF_VAR_compartment_ocid --name $TF_VAR_dns_name | jq -r '.data.items[0]["current-version-summary"].validity["time-of-validity-not-after"]'`
  CERT_VALIDITY_DAY=`echo $((($(date -d $CERT_VALIDITY +%s) - $(date +%s))/86400))`
  echo "OCI Certificate for $TF_VAR_dns_name exists already. OCID: $TF_VAR_certificate_ocid"
  echo "Certificate valid until: $CERT_DATE_VALIDITY"
  echo "Days left: $CERT_VALIDITY_DAY"
  echo "Done"
  exit
else 
  if [ -z "$CERTIFICATE_PATH" ]; then
    # Generate the certificate with Let'Encrypt ?
    generate_certificate
  fi  
  certificate_create
fi

# Use the certificate in the compute/APIGW/or LB based on the type of deployment
if [ "$TF_VAR_deploy_strategy" == "instance_pool" ]; then
  echo "Attach the certificate to the LB"
  # Attach the certificate to the LB
  # terraform apply ?
else 
  echo "Attach the certificate to APIGW"
  if [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
    # Modify the APIGW in front of the instacnce with the certificate 
    export INGRESS_LB_IP=`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
    export INGRESS_LB_OCID=`oci lb load-balancer list --compartment-id $TF_VAR_compartment_ocid | jq -r '.data[] | select(.["ip-addresses"][0]["ip-address"]=="'$LB_IP'") | .id'`  
  fi
  # Modify the APIGW in front with the certificate 
  # terraform apply
fi


