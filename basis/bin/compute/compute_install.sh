#!/usr/bin/env bash
# compute_install.sh 
#
# Init of a compute
#
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

export ARCH=`rpm --eval '%{_arch}'`
echo "ARCH=$ARCH"

# Shared Install Function
. ./shared_compute.sh
title "Compute Install"

if ! grep -q "export LC_CTYPE" $HOME/.bashrc; then
    # Set VI and NANO in utf8
    echo "export LC_CTYPE=en_US.UTF-8" >> $HOME/.bashrc
    echo "shopt -s direxpand" >> $HOME/.bashrc

    # Disable SELinux
    # XXXXXX Since OL8, the service does not start if SELINUX=enforcing XXXXXX
    sudo setenforce 0
    sudo sed -i s/^SELINUX=.*$/SELINUX=permissive/ /etc/selinux/config

    # Resize the boot volume (if >47GB)
    sudo /usr/libexec/oci-growfs -y

    # Build_host = bastion
    if [ "$TF_VAR_build_host" == "bastion" ]; then 
        # Kubernetes
        if [ "$TF_VAR_deploy_type" == "kubernetes" ]; then 
            install_docker_tools
            echo "export KUBECONFIG=$HOME/compute/kubeconfig_starter" >> $HOME/.bashrc
        fi 
        # Create a git branch 
        sudo dnf install -y git
        cd $HOME/app
        cp $HOME/compute/git/gitignore .gitignore
        chmod +x $HOME/compute/git/git_push.sh
        cp $HOME/compute/git/git_push.sh .
        git init
        git add .
        git commit -m "bastion app"

        # Create a bare repo (this could be gitlab, github, bitbucket, oci devops, ...). This is easier to set up like this 
        git clone --bare $HOME/app/.git $HOME/app.git
        cp $HOME/compute/git/post-receive ~/app.git/hooks
        chmod +x ~/app.git/hooks/post-receive
        chmod +x ~/app.git/hooks/post-receive
    fi
fi

# -- App --------------------------------------------------------------------
# Application Specific installation
# Build all app* directories
$HOME/compute/rebuild.sh

# -- app/start*.sh -----------------------------------------------------------
if is_deploy_compute; then 
    title "Compute Install - create restart.sh"
    cd $HOME/app
    for APP_DIR in `app_dir_list`; do
    # if [ -f $APP_DIR/restart.sh ]; then
    #  echo "$APP_DIR/restart.sh exists already"
    # else
        rm -f $APP_DIR/restart.sh 

        if [ -f $APP_DIR/start.sh ]; then
            APP_NAME="${APP_DIR//\//-}"
            echo "Creating restart.sh for APP_DIR=$APP_DIR / APP_NAME=$APP_NAME"
            # Hardcode the connection to the DB in the start.sh
            chmod +x $APP_DIR/start.sh

            # Create an "app.service" that starts when the machine starts.
            cat > /tmp/$APP_NAME.service << EOT
[Unit]
Description=App
After=network.target

[Service]
Type=simple
ExecStart=/home/opc/app/$APP_DIR/start.sh
TimeoutStartSec=0
User=opc

[Install]
WantedBy=default.target
EOT
            sudo cp /tmp/$APP_NAME.service /etc/systemd/system
            sudo chmod 664 /etc/systemd/system/$APP_NAME.service
            sudo systemctl daemon-reload
            sudo systemctl enable $APP_NAME.service
            echo "sudo systemctl restart $APP_NAME" >> $APP_DIR/restart.sh 
        fi  
    # fi  
    if [ -f $APP_DIR/restart.sh ]; then
        chmod +x $APP_DIR/restart.sh  
        $APP_DIR/restart.sh
    fi
    done 
fi

