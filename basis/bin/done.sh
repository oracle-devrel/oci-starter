#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

if [ -z "$TF_VAR_deploy_type" ]; then
  . ./env.sh -silent
else
  . bin/shared_bash_function.sh
fi 

get_ui_url

echo 
echo "Build done"

if [ ! -z "$UI_URL" ]; then
  # Check the URL if running in the test_suite
  if [ ! -z "$TEST_NAME" ]; then
    echo $UI_URL > /tmp/ui_url.txt
    
    if [ "$TF_VAR_deploy_type" == "kubernetes" ]; then
      kubectl wait --for=condition=ready pod ${TF_VAR_prefix}-app
      kubectl wait --for=condition=ready pod ${TF_VAR_prefix}-ui
      kubectl get all
      sleep 5
    fi

    # Retry several time. Needed for ORDS or Go or Tomcat that takes more time to start
    x=1
    while [ $x -le 20 ]
    do
      if [ -f "/tmp/cookie.txt" ]; then
        rm /tmp/cookie.txt
      fi  
      curl $UI_URL/app/dept -b /tmp/cookie.txt -c /tmp/cookie.txt -L -D /tmp/result_json.log > /tmp/result.json
      if grep -q -i "deptno" /tmp/result.json; then
        echo "----- OK ----- deptno detected in $UI_URL/app/dept"
       	break
      fi
      sleep 5  
      x=$(( $x + 1 ))
    done
    if [ "$TF_VAR_ui_type" != "api" ]; then
      if [ -f "/tmp/cookie.txt" ]; then
        rm /tmp/cookie.txt
      fi  
      curl $UI_URL/ -b /tmp/cookie.txt -c /tmp/cookie.txt -L --retry 5 --retry-max-time 20 -D /tmp/result_html.log > /tmp/result.html
    else 
      echo "OCI Starter" > /tmp/result.html
    fi  
    if [ -f "/tmp/cookie.txt" ]; then
      rm /tmp/cookie.txt
    fi  
    curl $UI_URL/app/info -b /tmp/cookie.txt -c /tmp/cookie.txt -L --retry 5 --retry-max-time 20 -D /tmp/result_info.log > /tmp/result.info

    if [ "$TF_VAR_deploy_type" == "compute" ]; then
      # Get the compute logs
      scp -r -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path opc@$COMPUTE_IP:/home/opc/*.log target/.
      scp -r -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path opc@$COMPUTE_IP:/home/opc/app/*.log target/.
      if [ "$TF_VAR_language" == "java" ]; then
        if [ "$TF_VAR_java_framework" == "tomcat" ]; then
            ssh -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path opc@$COMPUTE_IP "sudo cp -r /opt/tomcat/logs /tmp/tomcat_logs; sudo chown -R opc /tmp/tomcat_logs"
            scp -r -o StrictHostKeyChecking=no -i $TF_VAR_ssh_private_path opc@$COMPUTE_IP:/tmp/tomcat_logs target/.
        fi
      fi
    fi 
  fi
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
  if [ "$TF_VAR_deploy_type" == "compute" ] && [ "$TF_VAR_ui_type" == "api" ]; then   
    export APIGW_URL=https://${APIGW_HOSTNAME}/${TF_VAR_prefix}  
    echo - API Gateway URL : $APIGW_URL/app/dept 
  fi
  if [ "$TF_VAR_language" == "java" ] && [ "$TF_VAR_java_framework" == "springboot" ] && [ "$TF_VAR_ui_type" == "html" ] && [ "$TF_VAR_db_node_count" == "2" ]; then
    echo - RAC Page        : $UI_URL/rac.html
  fi
fi

if [ -f $PROJECT_DIR/src/after_done.sh ]; then
  $PROJECT_DIR/src/after_done.sh
fi
