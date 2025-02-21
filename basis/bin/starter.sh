#!/bin/bash

# Set project_dir and bin_dir when not called from starter.sh
if [ "$PROJECT_DIR" == "" ]; then
  if [ -f env.sh ]; then
    export PROJECT_DIR="$(pwd)"
  else 
    echo "ERROR: env.sh file not found."
    exit 1
  fi
fi
if [ "$BIN_DIR" == "" ]; then
  export BIN_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
fi

export TARGET_DIR=$PROJECT_DIR/target
mkdir -p $TARGET_DIR/logs
DATE_POSTFIX=`date '+%Y%m%d-%H%M%S'`

export ARG1=$1
export ARG2=$2
export ARG3=$3

if [ -z $ARG1 ]; then
  COMMAND_FILE=$TARGET_DIR/command.txt 
  if [ -f $COMMAND_FILE ]; then
    rm $COMMAND_FILE
  fi
  if [ ! -f $COMMAND_FILE ]; then
    python $BIN_DIR/starter_menu.py 
    if [ -f $COMMAND_FILE ]; then
      COMMAND=$(cat $COMMAND_FILE)
      rm $COMMAND_FILE
      # Execute the command from bash to avoid issue with terminal prompt
      eval "$COMMAND"    
    fi
  fi
elif [ "$ARG1" == "help" ]; then
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
  echo "--- START/STOP -------------------------------------------------------------------------------"
  echo "./starter.sh start                    - Start all resources"
  echo "./starter.sh stop                     - Stop all resources"
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
  echo "--- HELP -------------------------------------------------------------------------------------"
  echo "https://www.ocistarter.com/"
  echo "https://www.ocistarter.com/help (tutorial + how to customize)"  
  echo 
  exit

elif [ "$ARG1" == "build" ]; then
  if [ "$ARG2" == "" ]; then
    export LOG_NAME=$TARGET_DIR/logs/build.${DATE_POSTFIX}.log
    # Show the log and save it to target/build.log and target/logs
    ln -sf $LOG_NAME $TARGET_DIR/build.log
    $BIN_DIR/build_all.sh ${@:2} 2>&1 | tee $LOG_NAME
  elif [ "$ARG2" == "app" ]; then
    $PROJECT_DIR/src/app/build_app.sh ${@:2}
  elif [ "$ARG2" == "ui" ]; then
    $PROJECT_DIR/src/ui/build_ui.sh ${@:2}
  else 
    echo "Unknown command: $ARG1 $ARG2"
  fi    


elif [ "$ARG1" == "destroy" ]; then
  LOG_NAME=$TARGET_DIR/logs/destroy.${DATE_POSTFIX}.log
  # Show the log and save it to target/build.log and target/logs
  ln -sf $LOG_NAME $TARGET_DIR/destroy.log
  $BIN_DIR/destroy_all.sh ${@:2} 2>&1 | tee $LOG_NAME
elif [ "$ARG1" == "ssh" ]; then
  if [ "$ARG2" == "compute" ]; then
    $BIN_DIR/ssh_compute.sh
  elif [ "$ARG2" == "bastion" ]; then
    $BIN_DIR/ssh_bastion.sh
  elif [ "$ARG2" == "db_node" ]; then
    $BIN_DIR/ssh_db_node.sh
  else 
    echo "Unknown command: $ARG1 $ARG2"
  fi    
elif [ "$ARG1" == "terraform" ]; then
  if [ "$ARG2" == "plan" ]; then
    $BIN_DIR/terraform_plan.sh ${@:2}
  elif [ "$ARG2" == "apply" ]; then
    $BIN_DIR/terraform_apply.sh ${@:2}
  elif [ "$ARG2" == "destroy" ]; then
    $BIN_DIR/terraform_destroy.sh ${@:2}
  else 
    echo "Unknown command: $ARG1 $ARG2"
  fi    
elif [ "$ARG1" == "start" ]; then
    $BIN_DIR/start_stop.sh start $ARG1 $ARG2
elif [ "$ARG1" == "stop" ]; then
    $BIN_DIR/start_stop.sh start $ARG1 $ARG2
elif [ "$ARG1" == "generate" ]; then
  if [ "$ARG2" == "auth_token" ]; then
    $BIN_DIR/gen_auth_token.sh
  else 
    echo "Unknown command: $ARG1 $ARG2"
  fi    
elif [ "$ARG1" == "deploy" ]; then
  if [ "$ARG2" == "compute" ]; then
    $BIN_DIR/deploy_compute.sh
  elif [ "$ARG2" == "bastion" ]; then
    $BIN_DIR/deploy_bastion.sh
  elif [ "$ARG2" == "oke" ]; then
    $BIN_DIR/deploy_oke.sh
  else 
    echo "Unknown command: $ARG1 $ARG2"
    exit 1
  fi    
elif [ "$ARG1" == "env" ]; then
  # Check if sourced or not
  (return 0 2>/dev/null) && SOURCED=1 || SOURCED=0
  if [ "$SOURCED" == "1" ]; then
    . $BIN_DIR/auto_env.sh ${@:2}
    return
  else
    bash --rcfile $BIN_DIR/auto_env.sh ${@:2}
  fi
elif [ "$ARG1" == "upgrade" ]; then
  $BIN_DIR/upgrade.sh 
else 
  echo "Unknown command: $ARG1"
  exit 1
fi
# Return the exit code 
exit ${PIPESTATUS[0]}