#!/bin/bash
export PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
$MODE=$1
$ARG2=$2
if [ -z $MODE ] || [ "$MODE" == "help" ]; then
  echo "Command requires an argument:"
  echo 
  echo "--- BUILD --------------------------------"
  echo "./ocistarter.sh build"
  echo "./ocistarter.sh build app"
  echo "./ocistarter.sh build ui"
  echo 
  echo "--- DESTROY ------------------------------"
  echo "./ocistarter.sh destroy"
  echo 
  echo "--- SSH ----------------------------------"
  echo "./ocistarter.sh ssh compute"
  echo "./ocistarter.sh ssh bastion"
  echo "./ocistarter.sh ssh db_node"
  echo 
  echo "--- TERRAFORM ----------------------------"
  echo "./ocistarter.sh terraform plan"
  echo "./ocistarter.sh terraform apply"
  echo "./ocistarter.sh terraform destroy"
  echo 
  echo "--- GENERATE -----------------------------"
  echo "./ocistarter.sh generate auth_token"
  echo "./ocistarter.sh generate password"
  echo 
  echo "--- DEPLOY -------------------------------"
  echo "./ocistarter.sh deploy bastion"
  echo "./ocistarter.sh deploy compute"
  echo "./ocistarter.sh deploy oke"
  echo 
  echo "--- KUBECTL ------------------------------"
  echo ". ./env.sh"
  echo "kubectl get pods"
  exit
fi

if [ "$MODE" == "build" ]; then
  ./build.sh
elif [ "$MODE" == "destroy" ]; then
  ./destroy.sh
else 
  echo "Unknow command: $MODE"
fi