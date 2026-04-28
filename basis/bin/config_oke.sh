#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../starter.sh env -no-auto -silent
. $BIN_DIR/build_common.sh
cd $SCRIPT_DIR/..
title "Config OKE"

export TARGET_OKE=$TARGET_DIR/oke
mkdir -p $TARGET_OKE

# One time configuration
if [ ! -f $KUBECONFIG ]; then
    create_kubeconfig
    
    # Check if Gateway Controller is installed
    kubectl get gateway oke-gateway -n default
    if [ "$?" != "0" ]; then
        # Deploy Latest ingress-nginx
        kubectl create clusterrolebinding starter_clst_adm --clusterrole=cluster-admin --user=$TF_VAR_current_user_ocid
        echo "OKE Deploy: Role Binding created"  

        # See: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengworkingwithistioaddonforgatewayapi.htm

        # Install Gateway API CRDs
        kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml
        kubectl get crd gateways.gateway.networking.k8s.io
        # Deploy the Istio cluster add-on
        oci ce cluster install-addon --addon-name Istio --cluster-id $OKE_OCID --from-json file://src/oke/istio_addon.json
        oci ce cluster list-addons --cluster-id $OKE_OCID
        # Wait istiod
        echo "Waiting for istiod pod to be Running..."

        ELAPSED=0
        while true; do
            STATUS=$(kubectl get pods -n istio-system -l app=istiod -o jsonpath='{.items[0].status.phase}' 2>/dev/null)

            if [ "$STATUS" = "Running" ]; then
                echo "istiod is Running!"
                break
            fi
              ELAPSED=$((ELAPSED + 5 ))
              if [ $ELAPSED -gt 300 ]; then
                  exit_error "Istiod not started after 300 secs"
              fi
              echo "Waiting 5 secs..."
              sleep 5
        done
        echo "Istiod is Running ($ELAPSED secs)"

        # Create a Gateway
        kubectl apply -f src/oke/gateway.yaml
        # Wait 
        echo "Waiting for Gateway to be ready..."
        kubectl wait --for=condition=Programmed gateway/oke-gateway -n default --timeout=120s
        exit_on_error "Gateway not reacing Programmed State"

        # Get the IP
        TF_VAR_ingress_ip=$(kubectl get gateway oke-gateway -n default -o jsonpath='{.status.addresses[0].value}' 2>/dev/null)
        echo "Gateway ready: $TF_VAR_ingress_ip"
    else
        echo "OKE Deploy: Skipping creation of Gateway" 
    fi  
fi

if ! grep -q "TF_VAR_ingress_ip" $TARGET_DIR/tf_env.sh; then
    if [ "$TF_VAR_ingress_ip" == "" ]; then
        export TF_VAR_ingress_ip=$(kubectl get gateway oke-gateway -n default -o jsonpath='{.status.addresses[0].value}' 2>/dev/null)
    fi 
    echo "export TF_VAR_ingress_ip=$TF_VAR_ingress_ip" >> $TARGET_DIR/tf_env.sh
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
