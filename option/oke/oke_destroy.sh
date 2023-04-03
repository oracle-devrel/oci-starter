#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../bin/build_common.sh
cd $BIN_DIR/..

if [ ! -f $ROOT_DIR/src/terraform/oke.tf ]; then
  echo "oke.tf not found"
  echo "Nothing to delete. This was an existing OKE installation"
  exit
fi  

echo "OKE DESTROY"

if [ "$1" != "--auto-approve" ]; then
  echo "Error: Please call this script via destroy.sh"
  exit
fi

if [ ! -f $KUBECONFIG ]; then
  create_kubeconfig
fi

# The goal is to destroy all LoadBalancers created by OKE in OCI before to delete OKE.
#
# Delete all ingress, services
kubectl delete ingress,services --all

# Delete the ingress controller
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.4.0/deploy/static/provider/cloud/deploy.yaml

