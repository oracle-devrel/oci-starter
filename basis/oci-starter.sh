#!/bin/bash
export PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export TARGET_DIR=$PROJECT_DIR/target
mkdir -p $TARGET_DIR
cd $PROJECT_DIR

export ARG1=$1
export ARG2=$2
export ARG3=$3

if [ -z $ARG1 ] || [ "$ARG1" == "help" ]; then
  echo "Help:"
  echo 
  echo "--- BUILD -------------------------------------------------------------------------"
  echo "./starter.sh build                    - Build all"
  echo "./starter.sh build app                - Build the application"
  echo "./starter.sh build ui                 - Build the user interface"
  echo
  echo "--- DESTROY -----------------------------------------------------------------------"
  echo "./starter.sh destroy                  - Destroy all"
  echo
  echo "--- SSH ---------------------------------------------------------------------------"
  echo "./starter.sh ssh compute              - SSH to compute (Compute mode)"
  echo "./starter.sh ssh bastion              - SSH to bastion"
  echo "./starter.sh ssh db_node              - SSH to DB_NODE (OCI Oracle Base DB)"
  echo
  echo "--- TERRAFORM (or RESOURCE MANAGER ) ----------------------------------------------"
  echo "./starter.sh terraform plan           - Plan"
  echo "./starter.sh terraform apply          - Apply"
  echo "./starter.sh terraform destroy        - Destroy"
  echo
  echo "--- GENERATE ----------------------------------------------------------------------"
  echo "./starter.sh generate auth_token      - Create OCI Auth Token (ex: docker login)"
  echo
  echo "--- DEPLOY ------------------------------------------------------------------------"
  echo "./starter.sh deploy bastion           - Deploy the bastion (+create DB tables)"
  echo "./starter.sh deploy compute           - Deploy APP and UI on Compute (Compute mode)"
  echo "./starter.sh deploy oke               - Deploy APP and UI on OKE     (OKE mode)"
  echo
  echo "--- KUBECTL -----------------------------------------------------------------------"
  echo ". ./env.sh                            - Set kubeconfig to connect to Kubernetes"
  echo "kubectl get pods                      - Example of a command to check the PODs"
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