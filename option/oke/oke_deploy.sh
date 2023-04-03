#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../bin/build_common.sh
cd $SCRIPT_DIR/..

# Call build_common to push the ${TF_VAR_prefix}-app:latest and ${TF_VAR_prefix}-ui:latest to OCIR Docker registry
ocir_docker_push

# One time configuration
if [ ! -f $KUBECONFIG ]; then
  create_kubeconfig
 
  # Deploy ingress-nginx
  kubectl create clusterrolebinding starter_clst_adm --clusterrole=cluster-admin --user=$TF_VAR_user_ocid
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.4.0/deploy/static/provider/cloud/deploy.yaml
  kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=240s
  kubectl wait --namespace ingress-nginx --for=condition=Complete job/ingress-nginx-admission-patch  
  # Wait for the ingress external IP
  external_ip=""
  while [ -z $external_ip ]; do
    echo "Waiting for external IP..."
    external_ip=$(kubectl get svc -n ingress-nginx ingress-nginx-controller --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
    if [ -z "$external_ip" ]; then
      sleep 10
    fi
  done

  date
  kubectl get all -n ingress-nginx
  sleep 5
  echo "Ingress ready: $external_ip"

  # Create secrets
  kubectl create secret docker-registry ocirsecret --docker-server=$TF_VAR_ocir --docker-username="$TF_VAR_namespace/$TF_VAR_username" --docker-password="$TF_VAR_auth_token" --docker-email="$TF_VAR_email"
  # XXXX - This should be by date 
  kubectl delete secret ${TF_VAR_prefix}-db-secret
  kubectl create secret generic ${TF_VAR_prefix}-db-secret --from-literal=db_user=$TF_VAR_db_user --from-literal=db_password=$TF_VAR_db_password --from-literal=db_url=$DB_URL --from-literal=jdbc_url=$JDBC_URL --from-literal=spring_application_json='{ "db.info": "Java - SpringBoot" }'
fi

# Using & as separator
sed "s&##DOCKER_PREFIX##&${DOCKER_PREFIX}&" src/app/app.yaml > $TARGET_DIR/app.yaml
sed "s&##DOCKER_PREFIX##&${DOCKER_PREFIX}&" src/ui/ui.yaml > $TARGET_DIR/ui.yaml

# If present, replace the ORDS URL
ORDS_HOST=`basename $(dirname $ORDS_URL)`
sed -i "s&##ORDS_HOST##&$ORDS_HOST&" $TARGET_DIR/app.yaml
sed "s&##ORDS_HOST##&$ORDS_HOST&" src/oke/ingress-app.yaml > $TARGET_DIR/ingress-app.yaml

# delete the old pod, just to be sure a new image is pulled
kubectl delete pod ${TF_VAR_prefix}-app ${TF_VAR_prefix}-ui
# Wait to be sure that the pod is deleted before to recreate
kubectl wait --for=delete pod/${TF_VAR_prefix}-app --timeout=30s

# Create objects in Kubernetes
kubectl apply -f $TARGET_DIR/app.yaml
kubectl apply -f $TARGET_DIR/ui.yaml
kubectl apply -f $TARGET_DIR/ingress-app.yaml
kubectl apply -f src/oke/ingress-ui.yaml

