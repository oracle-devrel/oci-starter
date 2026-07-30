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
        # Deploy Latest istio-gateway
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
                echo "Istiod is Running ($ELAPSED secs)"
                break
            fi
            ELAPSED=$((ELAPSED + 5 ))
            if [ $ELAPSED -gt 300 ]; then
                exit_error "Istiod not started after 300 secs"
            fi
            echo "Waiting 5 secs..."
            sleep 5
        done

        # Create a Gateway
        kubectl apply -f src/oke/gateway.yaml
        # Wait 
        echo "Waiting for Gateway to be ready..."
        kubectl wait --for=condition=Programmed gateway/oke-gateway -n gateway --timeout=120s
        exit_on_error "Gateway Programmed State"

        # Get the IP
        oke_get_gateway_ip
        echo "Gateway ready: $TF_VAR_gateway_ip"
    else
        echo "OKE Deploy: Skipping creation of Gateway" 
    fi  
fi

if ! grep -q "TF_VAR_gateway_ip" $TARGET_DIR/tf_env.sh; then
    oke_get_gateway_ip
    echo "export TF_VAR_gateway_ip=$TF_VAR_gateway_ip" >> $TARGET_DIR/tf_env.sh
fi

# Create secrets
kubectl delete secret ${TF_VAR_prefix}-db-secret --ignore-not-found=true
kubectl create secret generic ${TF_VAR_prefix}-db-secret --from-literal=db_user=$TF_VAR_db_user --from-literal=db_password=$TF_VAR_db_password --from-literal=db_url=$DB_URL --from-literal=jdbc_url=$JDBC_URL --from-literal=TF_VAR_compartment_ocid=$TF_VAR_compartment_ocid --from-literal=TF_VAR_nosql_endpoint=$TF_VAR_nosql_endpoint

# Create ocirsecret with DOCKER_TOKEN 
k8s_create_ocirsecret

# TF_ENV
tf_env_configmap
kubectl apply -f $TARGET_OKE/tf_env_configmap.yaml
