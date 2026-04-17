#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

. $HOME/compute/shared_compute.sh

help() {
    echo "List of Apps:"
    cd $HOME/app
    for APP_DIR in `app_dir_list`; do
        APP_NAME="${APP_DIR//\//-}"
        echo "-- APP: $APP_DIR - $APP_NAME ---------------------------------------"
        sudo systemctl status $APP_NAME --no-pager
    done 
    echo    
    echo "Command:"
    echo "- Help : ./helper.sh "
    echo "- App  : ./helper.sh <start/stop/restart/status> <app>"
}

APP_NAME=$2
if [ "$1" == "" ] || [ "$1" == "info" ]; then
    help
elif [ "$1" == "start" ]; then
    sudo systemctl start $APP_NAME
elif [ "$1" == "stop" ]; then
    sudo systemctl stop $APP_NAME
elif [ "$1" == "restart" ]; then
    sudo systemctl restart $APP_NAME
elif [ "$1" == "status" ]; then
    if [ "$APP_NAME" == "" ]; then
        for APP_DIR in `app_dir_list`; do
            APP_NAME="${APP_DIR//\//-}" 
            sudo systemctl status $APP_NAME --no-pager
        done 
    else
        sudo systemctl status $APP_NAME --no-pager
    fi
else
    help
    echo
    echo "ERROR: Unknown command: $1"
fi 
