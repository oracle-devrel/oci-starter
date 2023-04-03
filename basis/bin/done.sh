#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

if [ -z "$TF_VAR_deploy_strategy" ]; then
  . ./env.sh -silent
else
  . bin/shared_bash_function.sh
fi 

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  get_output_from_tfstate UI_URL ui_url  
elif [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
  export UI_URL=http://`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`/${TF_VAR_prefix}
elif [ "$TF_VAR_deploy_strategy" == "function" ] || [ "$TF_VAR_deploy_strategy" == "container_instance" ]; then  
  export UI_URL=https://${APIGW_HOSTNAME}/${TF_VAR_prefix}
fi

echo 
echo "Build done"
if [ ! -z "$UI_URL" ]; then
  # Check the URL if running in the test_suite
  if [ ! -z "$TEST_NAME" ]; then
    echo $UI_URL > /tmp/ui_url.txt
    
    if [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
      kubectl wait --for=condition=ready pod ${TF_VAR_prefix}-app
      kubectl wait --for=condition=ready pod ${TF_VAR_prefix}-ui
      kubectl get all
      sleep 5
    fi

    # Retry several time. Needed for ORDS or Go or Tomcat that takes more time to start
    x=1
    while [ $x -le 5 ]
    do
      curl $UI_URL/app/dept -L --retry 5 --retry-max-time 20 -D /tmp/result_json.log > /tmp/result.json
      if grep -q -i "deptno" /tmp/result.json; then
        echo "OK"
       	break
      fi
      echo "WARNING: /app/dept does not contain 'deptno'. Retrying in 10 secs"
      sleep 10  
      x=$(( $x + 1 ))
    done
    if [ "$TF_VAR_ui_strategy" != "api" ]; then
      curl $UI_URL/         -L --retry 5 --retry-max-time 20 -D /tmp/result_html.log > /tmp/result.html
    else 
      echo "OCI Starter" > /tmp/result.html
    fi  
    curl $UI_URL/app/info -L --retry 5 --retry-max-time 20 -D /tmp/result_info.log > /tmp/result.info
  fi
  if [ "$TF_VAR_ui_strategy" != "api" ]; then
    echo - User Interface  : $UI_URL/
  fi  
  echo - Rest DB API     : $UI_URL/app/dept
  echo - Rest Info API   : $UI_URL/app/info
  if [ "$TF_VAR_language" == "php" ]; then
    echo - PHP Page        : $UI_URL/app/index.php
  elif [ "$TF_VAR_language" == "java" ] && [ "$TF_VAR_java_framework" == "tomcat" ] ; then
    echo - JSP Page        : $UI_URL/app/index.jsp
  elif [ "$TF_VAR_deploy_strategy" == "compute" ] && [ "$TF_VAR_ui_strategy" == "api" ]; then   
    export APIGW_URL=https://${APIGW_HOSTNAME}/${TF_VAR_prefix}  
    echo - API Gateway URL : $APIGW_URL/app/dept 
  fi
fi


