#!/bin/bash
if [ "$PROJECT_DIR" = "" ]; then
  echo "Error: PROJECT_DIR not set. Please use ./starter.sh build"
  exit 1
fi
cd $PROJECT_DIR
SECONDS=0
BUILD_MODE="ALL"

before_terraform() {
  # Custom code before terraform
  if [ -f $PROJECT_DIR/src/before_terraform.sh ]; then
    $PROJECT_DIR/src/before_terraform.sh
  fi

  # Build all
  # Generate sshkeys if not part of a Common Resources project 
  if [ "$TF_VAR_ssh_private_path" == "" ]; then
    . $BIN_DIR/sshkey_generate.sh
  fi
  
  . starter.sh env
  if [ "$TF_VAR_tls" != "" ]; then
    title "Certificate"
    certificate_dir_before_terraform
  fi  
}

terraform() {
  title "Terraform Apply"
  $BIN_DIR/terraform_apply.sh $1 -no-color 
  exit_on_error
}

build_deploy() {
  . starter.sh env
  # Run config command on the DB directly (ex RAC)
  if [ -f $BIN_DIR/deploy_db_node.sh ]; then
    title "Deploy DB Node"
    $BIN_DIR/deploy_db_node.sh
  fi 

  # Build the DB tables (via Bastion)
  if [ -d src/db ]; then
    title "Deploy Bastion"
    $BIN_DIR/deploy_bastion.sh
  fi  

  # Init target/compute
  if is_deploy_compute; then
    mkdir -p target/compute
    cp -r src/compute target/compute/.
  fi

  # Build all app* directories
  for APP_DIR in `app_dir_list`; do
    title "Build App $APP_DIR"
    src/${APP_DIR}/build_app.sh
    exit_on_error
  done

  if [ -f src/ui/build_ui.sh ]; then
    title "Build UI"
    src/ui/build_ui.sh 
    exit_on_error
  fi

  # Deploy
  title "Deploy $TF_VAR_deploy_type"
  if [ "$TF_VAR_deploy_type" == "public_compute" ] || [ "$TF_VAR_deploy_type" == "private_compute" ]; then
    $BIN_DIR/deploy_compute.sh
    exit_on_error
  elif [ "$TF_VAR_deploy_type" == "instance_pool" ]; then
    $BIN_DIR/deploy_compute.sh
    exit_on_error    
  elif [ "$TF_VAR_deploy_type" == "kubernetes" ]; then
    $BIN_DIR/oke_deploy.sh
    exit_on_error
  elif [ "$TF_VAR_deploy_type" == "container_instance" ]; then
    $BIN_DIR/ci_deploy.sh
    exit_on_error
  fi
}

terraform2() {
  if [ "$TF_VAR_deploy_type" == "instance_pool" ]; then
    export TF_VAR_compute_ready="true"
    $BIN_DIR/terraform_apply.sh --auto-approve -no-color
    exit_on_error
  fi
}

after_build() {
  . starter.sh env    
  if [ "$TF_VAR_tls" != "" ]; then
    title "Certificate - Post Deploy"
    certificate_post_deploy 
  fi

  $BIN_DIR/add_api_portal.sh

  # Custom code after build
  if [ -f $PROJECT_DIR/src/after_build.sh ]; then
    $PROJECT_DIR/src/after_build.sh
  fi
}

. starter.sh env -no-auto
title "OCI Starter - Build"

if [ "$1" == "--before_terraform" ]; then
  before_terraform
elif [ "$1" == "--build_deploy" ]; then
  build_deploy
elif [ "$1" == "--after_build" ]; then
  after_build
else
  before_terraform
  terraform $1
  # Running ./starter.sh build to create a resource manager stack, apply it in resource manager (for test-suite for example)
  if [ "$TF_VAR_infra_as_code" != "from_resource_manager" ]; then
    build_deploy
    terraform2 
    after_build
  fi
  title "Done"
  $BIN_DIR/done.sh
fi

