#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../starter.sh env -no-auto -silent
. $BIN_DIR/build_common.sh
cd $SCRIPT_DIR/..
title "Config OKE"

export TARGET_OKE=$TARGET_DIR/oke
mkdir -p $TARGET_OKE

function wait_ingress() {
  # Wait for the ingress deployment
  echo "Waiting for Ingress Controller Pods..."
  kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=600s
  kubectl wait --namespace ingress-nginx --for=condition=Complete job/ingress-nginx-admission-patch  
}

# One time configuration
if [ ! -f $KUBECONFIG ]; then
  create_kubeconfig
 
  # Check if Ingress Controller is installed
  kubectl get service ingress-nginx-controller -n ingress-nginx
  if [ "$?" != "0" ]; then
    # Deploy Latest ingress-nginx
    kubectl create clusterrolebinding starter_clst_adm --clusterrole=cluster-admin --user=$TF_VAR_current_user_ocid
    echo "OKE Deploy: Role Binding created"  
    # LATEST_INGRESS_CONTROLLER=`curl --silent "https://api.github.com/repos/kubernetes/ingress-nginx/releases/latest" | jq -r .name`
    # echo LATEST_INGRESS_CONTROLLER=$LATEST_INGRESS_CONTROLLER
    # kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/$LATEST_INGRESS_CONTROLLER/deploy/static/provider/cloud/deploy.yaml
    if [ "$TF_VAR_tls" == "new_http_01" ]; then
      helm install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx \
      --namespace ingress-nginx \
      --create-namespace \
      --set controller.enableExternalDNS=true 
      wait_ingress

      # ccm-letsencrypt-prod.yaml
      sed "s&##CERTIFICATE_EMAIL##&${TF_VAR_certificate_email}&" src/oke/tls/ccm-letsencrypt-prod.yaml > $TARGET_OKE/ccm-letsencrypt-prod.yaml
      kubectl apply -f $TARGET_OKE/ccm-letsencrypt-prod.yaml --timeout=600s
      sed "s&##CERTIFICATE_EMAIL##&${TF_VAR_certificate_email}&" src/oke/tls/ccm-letsencrypt-staging.yaml > $TARGET_OKE/ccm-letsencrypt-staging.yaml
      kubectl apply -f $TARGET_OKE/ccm-letsencrypt-staging.yaml

      # external-dns-config.yaml
      sed "s&##COMPARTMENT_OCID##&${TF_VAR_compartment_ocid}&" src/oke/tls/external-dns-config.yaml > $TARGET_OKE/external-dns-config.tmp
      sed "s&##REGION##&${TF_VAR_region}&" $TARGET_OKE/external-dns-config.tmp > $TARGET_OKE/external-dns-config.yaml
      kubectl create secret generic external-dns-config --from-file=$TARGET_OKE/external-dns-config.yaml

      # external-dns.yaml
      sed "s&##COMPARTMENT_OCID##&${TF_VAR_compartment_ocid}&" src/oke/tls/external-dns.yaml > $TARGET_OKE/external-dns.tmp
      sed "s&##REGION##&${TF_VAR_region}&" $TARGET_OKE/external-dns.tmp > $TARGET_OKE/external-dns.yaml
      kubectl apply -f $TARGET_OKE/external-dns.yaml
    else
      helm install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx \
      --namespace ingress-nginx \
      --create-namespace 
      wait_ingress
    fi
    
    # Wait for the ingress external IP
    TF_VAR_ingress_ip=""
    while [ -z $TF_VAR_ingress_ip ]; do
      echo "Waiting for Ingress IP..."
      TF_VAR_ingress_ip=`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
      if [ -z "$TF_VAR_ingress_ip" ]; then
        sleep 10
      fi
    done

    date
    kubectl get all -n ingress-nginx
    sleep 5
    echo "Ingress ready: $TF_VAR_ingress_ip"
  else
    echo "OKE Deploy: Skipping creation of ingress" 
  fi  
fi

# Create secrets
kubectl delete secret ${TF_VAR_prefix}-db-secret --ignore-not-found=true
kubectl create secret generic ${TF_VAR_prefix}-db-secret --from-literal=db_user=$TF_VAR_db_user --from-literal=db_password=$TF_VAR_db_password --from-literal=db_url=$DB_URL --from-literal=jdbc_url=$JDBC_URL --from-literal=TF_VAR_compartment_ocid=$TF_VAR_compartment_ocid --from-literal=TF_VAR_nosql_endpoint=$TF_VAR_nosql_endpoint

kubectl delete secret ocirsecret  --ignore-not-found=true
if [ "$TF_VAR_auth_token" == "" ]; then
  # Create a temporary docker auth_token (valid for 1 hour)... 
  export TOKEN=`oci raw-request --region $TF_VAR_region --http-method GET --target-uri "https://${OCIR_HOST}/20180419/docker/token" | jq -r .data.token`
  echo "TOKEN=$TOKEN" | cut -c 1-50
  kubectl create secret docker-registry ocirsecret --docker-server=$OCIR_HOST --docker-username="BEARER_TOKEN" --docker-password="$TOKEN" --docker-email="$TF_VAR_email"
else
  kubectl create secret docker-registry ocirsecret --docker-server=$OCIR_HOST --docker-username="$OBJECT_STORAGE_NAMESPACE/$TF_VAR_username" --docker-password="$TF_VAR_auth_token" --docker-email="$TF_VAR_email"
fi  

# TF_ENV
tf_env_configmap
kubectl apply -f $TARGET_OKE/tf_env_configmap.yaml

# Delete the old pod, just to be sure a new image is pulled (not the best idea in the world...XXXX)
# Replaced by :latest in the docker image value.
# kubectl delete pod ${TF_VAR_prefix}-ui --ignore-not-found=true
# kubectl delete deployment ${TF_VAR_prefix}-dep --ignore-not-found=true
# Wait to be sure that the deployment is deleted before to recreate
# kubectl wait --for=delete deployment/${TF_VAR_prefix}-dep --timeout=30s

# Kubectl apply
# Using & as separator

# Call build_common to push the ${TF_VAR_prefix}-${APP_NAME}:latest and ${TF_VAR_prefix}-ui:latest to OCIR Docker registry
# ocir_docker_push

# Append a line in tf_env.sh (typically used in before_build.sh to add custom variable to pass to bastion/compute/...)
# APPS
# for APP_NAME in `app_name_list_build`; do
#   if [ -f src/app/${APP_NAME}/k8s.yaml ]; then
#     copy_replace_apply_target_oke src/app/${APP_NAME}/k8s.yaml
#   fi
#   if [ -f src/app/${APP_NAME}/k8s-ingress.yaml ]; then
#     copy_replace_apply_target_oke src/app/${APP_NAME}/k8s-ingress.yaml
#   fi
# done

