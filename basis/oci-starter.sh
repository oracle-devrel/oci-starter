#!/bin/bash
export PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export TARGET_DIR=$PROJECT_DIR/target
mkdir -p $TARGET_DIR
cd $PROJECT_DIR

export ARG1=$1
export ARG2=$2
export ARG3=$3

if [ -z $ARG1 ] || [ "$ARG1" == "help" ]; then
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

if [ "$ARG1" == "build" ]; then
  # Show the log and save it in target/build.log
  bin/build_all.sh ${@:2} 2>&1 | tee $TARGET_DIR/build.log
elif [ "$ARG1" == "destroy" ]; then
  bin/destroy_all.sh ${@:2} 2>&1 | tee $TARGET_DIR/destroy.log
elif [ "$ARG1" == "ssh" ]; then
  if [ "$ARG2" == "compute" ]; then
    bin/ssh_compute.sh
  elif [ "$ARG2" == "bastion" ]; then
    bin/ssh_bastion.sh
  elif [ "$ARG2" == "db_node" ]; then
    bin/ssh_db_node.sh
  else 
    echo "Unknow command: $ARG1 $ARG2"
  fi    
elif [ "$ARG1" == "terraform" ]; then
  if [ "$ARG2" == "plan" ]; then
    src/terraform/plan.sh $ARG3
  elif [ "$ARG2" == "apply" ]; then
    src/terraform/apply.sh $ARG3
  elif [ "$ARG2" == "destroy" ]; then
    src/terraform/destroy.sh $ARG3
  else 
    echo "Unknow command: $ARG1 $ARG2"
  fi    
elif [ "$ARG1" == "generate" ]; then
  if [ "$ARG2" == "auth_token" ]; then
    bin/gen_auth_token.sh
  else 
    echo "Unknow command: $ARG1 $ARG2"
  fi    
elif [ "$ARG1" == "deploy" ]; then
  if [ "$ARG2" == "compute" ]; then
    bin/deploy_compute.sh
  elif [ "$ARG2" == "bastion" ]; then
    bin/deploy_bastion.sh
  elif [ "$ARG2" == "oke" ]; then
    bin/deploy_oke.sh
  else 
    echo "Unknow command: $ARG1 $ARG2"
    exit 1
  fi    
else 
  echo "Unknow command: $ARG1"
  exit 1
fi
# Return the exit code 
exit ${PIPESTATUS[0]}