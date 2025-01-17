#!/bin/bash
export PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export TARGET_DIR=$PROJECT_DIR/target
mkdir -p $TARGET_DIR/logs
cd $PROJECT_DIR

DATE_POSTFIX=`date '+%Y%m%d-%H%M%S'`


export ARG1=$1
export ARG2=$2
export ARG3=$3

if [ -z $ARG1 ] then
  python src/starter_menu.py
elif [ "$ARG1" == "help" ]; then
  echo "--- HELP -------------------------------------------------------------------------------------"
  echo "https://www.ocistarter.com/"
  echo "https://www.ocistarter.com/help (tutorial + how to customize)"  
  echo 
  echo "--- BUILD ------------------------------------------------------------------------------------"
  echo "./starter.sh build                    - Build and deploy all"
  echo "./starter.sh build app                - Build the application (APP)"
  echo "./starter.sh build ui                 - Build the user interface (UI)"
  echo "--- DESTROY ----------------------------------------------------------------------------------"
  echo "./starter.sh destroy                  - Destroy all"
  echo "--- SSH --------------------------------------------------------------------------------------"
  echo "target/ssh_key_starter                - SSH private key"
  echo "./starter.sh ssh compute              - SSH to compute (Deployment: Compute)"
  echo "./starter.sh ssh bastion              - SSH to bastion"
  echo "./starter.sh ssh db_node              - SSH to DB_NODE (Database: Oracle DB)"
  echo "--- TERRAFORM (or RESOURCE MANAGER ) ---------------------------------------------------------"
  echo "./starter.sh terraform plan           - Plan"
  echo "./starter.sh terraform apply          - Apply"
  echo "./starter.sh terraform destroy        - Destroy"
  echo "--- GENERATE ---------------------------------------------------------------------------------"
  echo "./starter.sh generate auth_token      - Create OCI Auth Token (ex: docker login)"
  echo "--- DEPLOY -----------------------------------------------------------------------------------"
  echo "./starter.sh deploy bastion           - Deploy the bastion (+create DB tables)"
  echo "./starter.sh deploy compute           - Deploy APP and UI on Compute (Deployment: Compute)"
  echo "./starter.sh deploy oke               - Deploy APP and UI on OKE     (Deployment: Kubernetes)"
  echo "--- KUBECTL ----------------------------------------------------------------------------------"
  echo "./starter.sh env                      - Set environment variable like KUBECONFIG for Kubernetes"
  echo "kubectl get pods                      - Example of a command to check the PODs"
  echo "--- LOGS -------------------------------------------------------------------------------------"
  echo "cat target/build.log                  - Show last build log"
  echo "cat target/destroy.log                - Show last destroy log"
  echo
  exit
fi

if [ "$ARG1" == "build" ]; then
  if [ "$ARG2" == "" ]; then
    export LOG_NAME=$TARGET_DIR/logs/build.${DATE_POSTFIX}.log
    # Show the log and save it to target/build.log and target/logs
    ln -sf $LOG_NAME $TARGET_DIR/build.log
    bin/build_all.sh $@ 2>&1 | tee $LOG_NAME
  elif [ "$ARG2" == "app" ]; then
    src/app/build_app.sh ${@:2}
  elif [ "$ARG2" == "ui" ]; then
    src/ui/build_ui.sh ${@:2}
  else 
    echo "Unknown command: $ARG1 $ARG2"
  fi    


elif [ "$ARG1" == "destroy" ]; then
  LOG_NAME=$TARGET_DIR/logs/destroy.${DATE_POSTFIX}.log
  # Show the log and save it to target/build.log and target/logs
  ln -sf $LOG_NAME $TARGET_DIR/destroy.log
  bin/destroy_all.sh $@ 2>&1 | tee $LOG_NAME
elif [ "$ARG1" == "ssh" ]; then
  if [ "$ARG2" == "compute" ]; then
    bin/ssh_compute.sh
  elif [ "$ARG2" == "bastion" ]; then
    bin/ssh_bastion.sh
  elif [ "$ARG2" == "db_node" ]; then
    bin/ssh_db_node.sh
  else 
    echo "Unknown command: $ARG1 $ARG2"
  fi    
elif [ "$ARG1" == "terraform" ]; then
  if [ "$ARG2" == "plan" ]; then
    bin/terraform_plan.sh ${@:2}
  elif [ "$ARG2" == "apply" ]; then
    bin/terraform_apply.sh ${@:2}
  elif [ "$ARG2" == "destroy" ]; then
    bin/terraform_destroy.sh ${@:2}
  else 
    echo "Unknown command: $ARG1 $ARG2"
  fi    
elif [ "$ARG1" == "generate" ]; then
  if [ "$ARG2" == "auth_token" ]; then
    bin/gen_auth_token.sh
  else 
    echo "Unknown command: $ARG1 $ARG2"
  fi    
elif [ "$ARG1" == "deploy" ]; then
  if [ "$ARG2" == "compute" ]; then
    bin/deploy_compute.sh
  elif [ "$ARG2" == "bastion" ]; then
    bin/deploy_bastion.sh
  elif [ "$ARG2" == "oke" ]; then
    bin/deploy_oke.sh
  else 
    echo "Unknown command: $ARG1 $ARG2"
    exit 1
  fi    
elif [ "$ARG1" == "env" ]; then
  bash --rcfile ./env.sh ${@:2}
else 
  echo "Unknown command: $ARG1"
  exit 1
fi
# Return the exit code 
exit ${PIPESTATUS[0]}