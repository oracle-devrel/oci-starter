#!/bin/bash
if [[ -z "${PROJECT_DIR}" ]]; then
  echo "Error: PROJECT_DIR not set"
  exit
fi
cd $PROJECT_DIR
SECONDS=0

. env.sh -no-auto
title "OCI Starter - Build"

# Build all
# Generate sshkeys if not part of a Common Resources project 
if [ "$TF_VAR_ssh_private_path" == "" ]; then
  . $BIN_DIR/sshkey_generate.sh
fi

. env.sh
if [ "$TF_VAR_tls" != "" ]; then
  title "Certificate"
  certificate_dir_before_terraform
fi  

title "Terraform Apply"
src/terraform/apply.sh --auto-approve -no-color
exit_on_error

. env.sh
# Run config command on the DB directly (ex RAC)
if [ -f bin/deploy_db_node.sh ]; then
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
    cp src/compute/* target/compute/.
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
if [ "$TF_VAR_deploy_type" == "compute" ]; then
    $BIN_DIR/deploy_compute.sh
    exit_on_error
elif [ "$TF_VAR_deploy_type" == "instance_pool" ]; then
    $BIN_DIR/deploy_compute.sh
    exit_on_error
    export TF_VAR_compute_ready="true"
    src/terraform/apply.sh --auto-approve -no-color
    exit_on_error
elif [ "$TF_VAR_deploy_type" == "kubernetes" ]; then
    $BIN_DIR/oke_deploy.sh
    exit_on_error
elif [ "$TF_VAR_deploy_type" == "container_instance" ]; then
    $BIN_DIR/ci_deploy.sh
    exit_on_error
fi

if [ "$TF_VAR_tls" != "" ]; then
  title "Certificate - Post Deploy"
  certificate_post_deploy
fi

$BIN_DIR/add_api_portal.sh

title "Done"
$BIN_DIR/done.sh

