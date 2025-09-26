#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

. starter.sh env -silent

get_ui_url

title "After Build"
if [ "$UI_URL" != "" ]; then
  echo "TEST URLs" > $FILE_DONE
  append_done "- UI URL: $UI_URL"
  if [ "$TF_VAR_ui_type" != "api" ]; then
  # Check the URL if running in the test_suite
    if [ "$TEST_NAME" != "" ]; then
      export TMP_PATH="/tmp/$TF_VAR_prefix"
      rm -Rf $TMP_PATH     
      mkdir -p $TMP_PATH 
      echo $UI_URL > $TMP_PATH/ui_url.txt
    
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
        if [ -f "$TMP_PATH/cookie.txt" ]; then
          rm $TMP_PATH/cookie.txt
        fi  
        if [ "$TF_VAR_language" == "apex" ]; then
          wget $UI_URL/app/dept -o $TMP_PATH/result_json.log -O $TMP_PATH/result.json
        else
          curl $UI_URL/app/dept -b $TMP_PATH/cookie.txt -c $TMP_PATH/cookie.txt -L -D $TMP_PATH/result_json.log > $TMP_PATH/result.json
        fi      
        if grep -q -i "deptno" $TMP_PATH/result.json; then
          echo "----- OK ----- deptno detected in $UI_URL/app/dept"
       	  break
        fi
        sleep 5  
        x=$(( $x + 1 ))
      done
      if [ "$TF_VAR_ui_type" != "api" ] && [ "$TF_VAR_language" != "apex" ]; then
        if [ -f "$TMP_PATH/cookie.txt" ]; then
          rm $TMP_PATH/cookie.txt
        fi  
        curl $UI_URL/ -b $TMP_PATH/cookie.txt -c $TMP_PATH/cookie.txt -L --retry 5 --retry-max-time 20 -D $TMP_PATH/result_html.log > $TMP_PATH/result.html
      else 
        echo "OCI Starter" > $TMP_PATH/result.html
      fi  
      if [ -f "$TMP_PATH/cookie.txt" ]; then
        rm $TMP_PATH/cookie.txt
      fi  
      if [ "$TF_VAR_language" == "apex" ]; then
        wget $UI_URL/app/info -o $TMP_PATH/result_info.log -O $TMP_PATH/result.info
      else
        curl $UI_URL/app/info -b $TMP_PATH/cookie.txt -c $TMP_PATH/cookie.txt -L --retry 5 --retry-max-time 20 -D $TMP_PATH/result_info.log > $TMP_PATH/result.info
      fi      

      if [ "$TF_VAR_deploy_type" == "public_compute" ] || [ "$TF_VAR_deploy_type" == "private_compute" ]; then
        # Get the compute logs
        eval "$(ssh-agent -s)"      
        ssh-add $TF_VAR_ssh_private_path
        scp -r -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" opc@$COMPUTE_IP:/home/opc/compute/*.log target/.
        scp -r -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" opc@$COMPUTE_IP:/home/opc/*.log target/.
        scp -r -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" opc@$COMPUTE_IP:/home/opc/app/*.log target/.
        if [ "$TF_VAR_language" == "java" ]; then
          if [ "$TF_VAR_java_framework" == "tomcat" ]; then
            ssh -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" opc@$COMPUTE_IP "sudo cp -r /opt/tomcat/logs $TMP_PATH/tomcat_logs; sudo chown -R opc $TMP_PATH/tomcat_logs"
            scp -r -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" opc@$COMPUTE_IP:$TMP_PATH/tomcat_logs target/.
          fi
        fi
      fi
    fi
  fi
fi