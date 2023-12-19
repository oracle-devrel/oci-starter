#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

# Associate the IP with the DNS
if [-n "$DNS_ZONE_NAME" ]; then
    # ocid1.dns-zone.oc1..cc94d47db85349df89083034b50e45e6
    # Compute and Instance Pool are created during the 1rst terraform build.
    # - Not possible to OKE
    # - To do for Functions / Container Instance 
    if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
       echo "Deployment compute"
    else
       get_ui_url
       DNS_IP
    fi
fi

# Generate the certificate with Let'Encrypt ?
if [-n "$CERTIFICATE_GENERATE_DNS" ]; then
    if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
        # Generate the certificate with Let'Encrypt on the COMPUTE
        SSL_IP=$COMPUTE_IP
    else
        # Generate the certificate with Let'Encrypt on the BASTION
        SSL_IP=$BASTION_IP
    fi
    scp -r -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path bin/ssl opc@$SSL_IP:/home/opc/.
    ssh -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path opc@$SSL_IP "export TF_VAR_dns_name=\"$TF_VAR_dns_name\";export CERTIFICATE_GENERATE_DNS=\"$CERTIFICATE_GENERATE_EMAIL\"; bash ssl/ssl_init.sh 2>&1 | tee -a ssl/ssl_init.log"
    scp -r -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path opc@$SSL_IP:ssl/certificate target/.
    export CERTIFICATE_PATH=$PROJECT_DIR/target/certificate/$TF_VAR_dns_name
fi

# Create or get the CERTIFICATE OCID
if [ -n "$CERTIFICATE_OCID" ]; then
    echo "Using existing OCI Certificate"  
elif [ -n "$CERTIFICATE_PATH" ]; then
    CERT_CERT=$(cat $CERTIFICATE_PATH/cert1.pem)
    CERT_CHAIN=$(cat $CERTIFICATE_PATH/chain1.pem)
    CERT_PRIVKEY=$(cat $CERTIFICATE_PATH/privkey1.pem)
    oci certs-mgmt certificate create-by-importing-config --compartment-id=$TF_VAR_compartment_ocid  --name=${TF_VAR_prefix}-certificate --cert-chain-pem="$CERT_CHAIN" --certificate-pem="$CERT_CERT"  --private-key-pem="$CERT_PRIVKEY" --wait-for-state ACTIVE --wait-for-state FAILED
    exit_on_error
else   
    echo "ERROR: CERTIFICATE_OCID or CERTIFICATE_PATH should be defined"
    exit
fi

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  echo "Deployment compute"
elif [ "$TF_VAR_deploy_strategy" == "instance_pool" ]; then
  # Modify the LB in front of the instacnce with the certificate 
elif [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
  # Modify the LB in front of the instacnce with the certificate 
  export LB_IP=`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
  export LB_OCID=`oci lb load-balancer list --compartment-id $TF_VAR_compartment_ocid | jq -r '.data[] | select(.["ip-addresses"][0]["ip-address"]=="'$LB_IP'") | .id'`  
  
elif [ "$TF_VAR_deploy_strategy" == "function" ] || [ "$TF_VAR_deploy_strategy" == "container_instance" ]; then  
  # Modify the LB in front of the instacnce with the certificate 
  export UI_URL=https://${APIGW_HOSTNAME}/${TF_VAR_prefix}
fi


