#!/bin/bash
if [ "$PROJECT_DIR" = "" ]; then
  echo "Error: PROJECT_DIR not set. Please use ./starter.sh build"
  exit 1
fi
cd $PROJECT_DIR
SECONDS=0

. starter.sh env -no-auto
title "OCI Starter - Build"

# First build is auto-approved. Else you need to pass --auto-approve flag.
if [ "$1" != "--auto-approve" ]; then
   export TERRAFORM_FLAG="--auto-approve"
elif [ -f $STATE_FILE ]; then
   echo "$STATE_FILE detected."
else
   export TERRAFORM_FLAG="--auto-approve"
fi

# Custom code before build
if [ -f $PROJECT_DIR/src/before_build.sh ]; then
  $PROJECT_DIR/src/before_build.sh
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

title "Terraform Apply"
$BIN_DIR/terraform_apply.sh -no-color $TERRAFORM_FLAG
exit_on_error

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
    export TF_VAR_compute_ready="true"
    $BIN_DIR/terraform_apply.sh --auto-approve -no-color
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

# Custom code after build
if [ -f $PROJECT_DIR/src/after_build.sh ]; then
  $PROJECT_DIR/src/after_build.sh
fi

title "Done"
$BIN_DIR/done.sh

