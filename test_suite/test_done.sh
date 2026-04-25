#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/done_orig.sh

title "Testsuite - test_done.sh - Checking if the app works"
if [ "$UI_URL" != "" ]; then
    export TMP_PATH="/tmp/$TF_VAR_prefix"
    rm -Rf $TMP_PATH     
    mkdir -p $TMP_PATH 
    echo $UI_URL > $TMP_PATH/ui_url.txt
    echo "URL = $UI_URL"

    if [ "$TF_VAR_deploy_type" == "kubernetes" ]; then
        kubectl wait --for=condition=ready pod ${TF_VAR_prefix}-app
        kubectl wait --for=condition=ready pod ${TF_VAR_prefix}-ui
        kubectl get all
        sleep 5
    fi

    # Retry several time. Needed for ORDS or Go or Tomcat that takes more time to start
    x=1
    title "Testing: $UI_URL/app/dept"
    while [ $x -le 20 ]
    do
        rm -f $TMP_PATH/cookie.txt
        if [ "$TF_VAR_ui_type" == "langgraph" ]; then
            echo "Testsuite - LangGraph"
            curl -sS -c "$TMP_PATH/cookie.txt" -b "$TMP_PATH/cookie.txt" \
                -H 'Content-Type: application/json' \
                -H 'Authorization: User customer' \
                -X POST "$UI_URL/app/threads" \
                -d '{}' > $TMP_PATH/thread.json
            thread_id="$(jq -r '.thread_id // empty' $TMP_PATH/thread.json)"
            if [[ -n "$thread_id" ]]; then
                echo "Created thread_id=$thread_id"
                response_file=$TMP_PATH/result_dept.json
                curl -sS -N -c "$TMP_PATH/cookie.txt" -b "$TMP_PATH/cookie.txt" \
                    -H 'Content-Type: application/json' \
                    -H 'Authorization: User customer' \
                    -X POST "$UI_URL/app/threads/$thread_id/runs/stream" \
                    -d '{"assistant_id":"agent","input":{"messages":[{"role":"human","content":"get departments"}]}}' \
                    > $TMP_PATH/result_dept.json
            fi
        elif [ "$TF_VAR_language" == "apex" ]; then
            echo "Testsuite - apex - $UI_URL/app/dept"
            wget $UI_URL/app/dept -o $TMP_PATH/result_dept.log -O $TMP_PATH/result_dept.json
        else
            echo "Testsuite - default - $UI_URL/app/dept"
            curl $UI_URL/app/dept -b $TMP_PATH/cookie.txt -c $TMP_PATH/cookie.txt -L -D $TMP_PATH/result_dept.log > $TMP_PATH/result_dept.json
        fi      

        # Check (Same test is also done test_suite_shared)
        if grep -q -i "deptno" $TMP_PATH/result_dept.json; then
            echo -e "\u2705 deptno detected"
            break
        else 
            echo -e "Waiting 5 secs: deptno not found"
        fi
        sleep 5  
        x=$(( $x + 1 ))
    done
    if [ "$x" == "20" ]; then
        echo -e "\u2705 deptno not detected in $UI_URL/app/dept"  
    fi
    echo "See $TMP_PATH/result_dept.json"

    title "Testing: $UI_URL/"
    if [ "$TF_VAR_ui_type" != "api" ] && [ "$TF_VAR_ui_type" != "jsp" ] && [ "$TF_VAR_language" != "apex" ]; then
        if [ -f "$TMP_PATH/cookie.txt" ]; then
            rm $TMP_PATH/cookie.txt
        fi  
        curl $UI_URL/ -b $TMP_PATH/cookie.txt -c $TMP_PATH/cookie.txt -L --retry 5 --retry-max-time 20 -D $TMP_PATH/result_html.log > $TMP_PATH/result_html.html
    else 
        echo "OCI Starter" > $TMP_PATH/result_html.html
    fi 

    # Check (Same test is also done test_suite_shared)
    if grep -qiE "starter|deptno|messages" "$TMP_PATH/result_html.html"; then
        echo -e "\u2705 starter or deptno or messages detected in $UI_URL"
        CSV_HTML_OK=1
    else
        echo -e "\u274C $UI_URL does not contain starter or deptno or department" 
    fi
    echo "See $TMP_PATH/result_html.html"

    title "Testing: $UI_URL/app/info"
    if [ -f "$TMP_PATH/cookie.txt" ]; then
        rm $TMP_PATH/cookie.txt
    fi  
    if [ "$TF_VAR_language" == "apex" ]; then
        wget $UI_URL/app/info -o $TMP_PATH/result_info.log -O $TMP_PATH/result.info
    else
        curl $UI_URL/app/info -b $TMP_PATH/cookie.txt -c $TMP_PATH/cookie.txt -L --retry 5 --retry-max-time 20 -D $TMP_PATH/result_info.log > $TMP_PATH/result_info.html
    fi      
    echo "See $TMP_PATH/result.info"

    if [ "$TF_VAR_deploy_type" == "public_compute" ] || [ "$TF_VAR_deploy_type" == "private_compute" ]; then
        # Get the compute logs
        eval "$(ssh-agent -s)"      
        ssh-add $TF_VAR_ssh_private_path
        scp -r -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" opc@$COMPUTE_IP:/home/opc/compute/*.log target/.
        scp -r -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" opc@$COMPUTE_IP:/home/opc/app/*/*.log target/.
        if [ "$TF_VAR_language" == "java" ]; then
            if [ "$TF_VAR_java_framework" == "tomcat" ]; then
                ssh -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" opc@$COMPUTE_IP "sudo cp -r /opt/tomcat/logs $TMP_PATH/tomcat_logs; sudo chown -R opc $TMP_PATH/tomcat_logs"
                scp -r -o StrictHostKeyChecking=no -oProxyCommand="$BASTION_PROXY_COMMAND" opc@$COMPUTE_IP:$TMP_PATH/tomcat_logs target/.
            fi
        fi
    fi
else
    echo "<test_done.sh> UI_URL not detected"    
fi
