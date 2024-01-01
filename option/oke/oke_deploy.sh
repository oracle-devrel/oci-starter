#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../env.sh -no-auto
. $BIN_DIR/build_common.sh
cd $SCRIPT_DIR/..

# Call build_common to push the ${TF_VAR_prefix}-app:latest and ${TF_VAR_prefix}-ui:latest to OCIR Docker registry
ocir_docker_push

# One time configuration
if [ ! -f $KUBECONFIG ]; then
  create_kubeconfig
 
  # Deploy Latest ingress-nginx
  kubectl create clusterrolebinding starter_clst_adm --clusterrole=cluster-admin --user=$TF_VAR_user_ocid
  LATEST_INGRESS_CONTROLLER=`curl --silent "https://api.github.com/repos/kubernetes/ingress-nginx/releases/latest" | jq -r .name`
  echo LATEST_INGRESS_CONTROLLER=$LATEST_INGRESS_CONTROLLER
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/$LATEST_INGRESS_CONTROLLER/deploy/static/provider/cloud/deploy.yaml
  
  # Wait for the deployment
  echo "Waiting for Ingress Controller..."
  kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=600s
  kubectl wait --namespace ingress-nginx --for=condition=Complete job/ingress-nginx-admission-patch  
  
  # Wait for the ingress external IP
  TF_VAR_ingress_ip=""
  while [ -z $TF_VAR_ingress_ip ]; do
    echo "Waiting for external IP..."
    TF_VAR_ingress_ip=`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
    if [ -z "$TF_VAR_ingress_ip" ]; then
      sleep 10
    fi
  done

  date
  kubectl get all -n ingress-nginx
  sleep 5
  echo "Ingress ready: $TF_VAR_ingress_ip"

  # Create secrets
  kubectl create secret docker-registry ocirsecret --docker-server=$TF_VAR_ocir --docker-username="$TF_VAR_namespace/$TF_VAR_username" --docker-password="$TF_VAR_auth_token" --docker-email="$TF_VAR_email"
  # XXXX - This should be by date 
  kubectl delete secret ${TF_VAR_prefix}-db-secret  --ignore-not-found=true
  kubectl create secret generic ${TF_VAR_prefix}-db-secret --from-literal=db_user=$TF_VAR_db_user --from-literal=db_password=$TF_VAR_db_password --from-literal=db_url=$DB_URL --from-literal=jdbc_url=$JDBC_URL --from-literal=spring_application_json='{ "db.info": "Java - SpringBoot" }'
fi

# Using & as separator
sed "s&##DOCKER_PREFIX##&${DOCKER_PREFIX}&" src/app/app.yaml > $TARGET_DIR/app.yaml
sed "s&##DOCKER_PREFIX##&${DOCKER_PREFIX}&" src/ui/ui.yaml > $TARGET_DIR/ui.yaml
cp src/oke/ingress-app.yaml $TARGET_DIR/ingress-app.yaml

# If present, replace the ORDS URL
if [ "$ORDS_URL" != "" ]; then
  ORDS_HOST=`basename $(dirname $ORDS_URL)`
  sed -i "s&##ORDS_HOST##&$ORDS_HOST&" $TARGET_DIR/app.yaml
  sed -i "s&##ORDS_HOST##&$ORDS_HOST&" $TARGET_DIR/ingress-app.yaml
fi 

# delete the old pod, just to be sure a new image is pulled
kubectl delete pod ${TF_VAR_prefix}-ui --ignore-not-found=true
kubectl delete deployment ${TF_VAR_prefix}-dep --ignore-not-found=true
# Wait to be sure that the deployment is deleted before to recreate
kubectl wait --for=delete deployment/${TF_VAR_prefix}-dep --timeout=30s

# Create objects in Kubernetes
kubectl apply -f $TARGET_DIR/app.yaml
kubectl apply -f $TARGET_DIR/ui.yaml
kubectl apply -f $TARGET_DIR/ingress-app.yaml
kubectl apply -f src/oke/ingress-ui.yaml

