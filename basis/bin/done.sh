#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

if [ -z "$TF_VAR_deploy_type" ]; then
  . starter.sh env -silent
else
  . starter.sh env -no-auto
fi 

get_ui_url

echo 
echo "Build done"

if [ -f $PROJECT_DIR/src/after_done.sh ]; then
  # Unset UI_URL in after_done to remove the standard output
  . $PROJECT_DIR/src/after_done.sh
elif [ ! -z "$UI_URL" ]; then
  if [ "$TF_VAR_ui_type" != "api" ]; then
    echo - User Interface: $UI_URL/
  fi  
  if [ "$UI_HTTP" != "" ]; then
    echo - HTTP : $UI_HTTP/
  fi
  for APP_DIR in `app_dir_list`; do
    if [ -f  $PROJECT_DIR/src/$APP_DIR/openapi_spec.yaml ]; then
      python3 $BIN_DIR/openapi_list.py $PROJECT_DIR/src/$APP_DIR/openapi_spec.yaml $UI_URL
    fi  
    # echo - Rest DB API     : $UI_URL/$APP_DIR/dept
    # echo - Rest Info API   : $UI_URL/$APP_DIR/info
  done
  if [[ ("$TF_VAR_deploy_type" == "public_compute" || "$TF_VAR_deploy_type" == "private_compute") && "$TF_VAR_ui_type" == "api" ]]; then   
    export APIGW_URL=https://${APIGW_HOSTNAME}/${TF_VAR_prefix}  
    echo - API Gateway URL : $APIGW_URL/app/dept 
  fi
  if [ "$TF_VAR_language" == "java" ] && [ "$TF_VAR_java_framework" == "springboot" ] && [ "$TF_VAR_ui_type" == "html" ] && [ "$TF_VAR_db_node_count" == "2" ]; then
    echo - RAC Page        : $UI_URL/rac.html
  fi
  if [ "$TF_VAR_language" == "apex" ]; then
    echo "-----------------------------------------------------------------------"
    echo "APEX login:"
    echo
    echo "APEX Workspace"
    echo "$UI_URL/ords/_/landing"
    echo "  Workspace: APEX_APP"
    echo "  User: APEX_APP"
    echo "  Password: $TF_VAR_db_password"
    echo
    echo "APEX APP"
    echo "$UI_URL/ords/r/apex_app/apex_app/"
    echo "  User: APEX_APP / $TF_VAR_db_password"
  fi
fi

