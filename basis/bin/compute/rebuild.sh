SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
start_time=$(date +%s)

. ./shared_compute.sh

TARGET_OKE="$HOME/target/oke"
mkdir -p $TARGET_OKE
export DOCKER_LOGGED=false

chmod +x */*.sh

cd $HOME/app
for APP_DIR in `app_dir_list`; do
    APP_NAME="${APP_DIR//\//-}"
    title "Rebuild - App: $APP_NAME"
    if [ -f ${APP_NAME}/build.sh ]; then
        if [ -f ${APP_NAME}/Dockerfile ] && [ "DOCKER_LOGGED" == "false" ]; then 
            export DOCKER_LOGGED=true
            docker_login
        fi
        # Build in bastion
        $APP_NAME/build.sh
    elif [ "APP_NAME" == "db" ]; then
        # Database
        title "Rebuild - $APP_NAME: Install"
        ${APP_DIR}/install.sh
    elif [ -f $APP_DIR/install.sh ] && [ is_deploy_compute ]; then
        # Build in terraform - compute 
        title "Rebuild: $APP_NAME: Install"
        ${APP_DIR}/install.sh
    fi
    if is_deploy_compute; then
        if [ -f ${APP_DIR}/restart.sh ]; then
            title "Rebuild - $APP_NAME: Restart"
            ${APP_DIR}/restart.sh
        fi
    elif [ "$TF_VAR_deploy_type" != "kubernetes" ] ; then 
        echo "Rebuild - TF_VAR_deploy_type: $TF_VAR_deploy_type is not supported. It requires terraform to redeploy."
    fi
done

end_time=$(date +%s)
echo
echo "<rebuild.sh> Time taken: $((end_time - start_time)) seconds"