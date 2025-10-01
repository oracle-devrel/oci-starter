#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
. $HOME/bin/env_oci_starter_testsuite.sh
export BUILD_COUNT=1
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_NONE='\033[0m' 

# Default
OPTION_TLS=none
OPTION_GROUP_NAME=dummy
OPTION_DB_INSTALL=default
OPTION_SHAPE=amd
OPTION_INFRA_AS_CODE=terraform_local
OPTION_JAVA_FRAMEWORK=springboot
OPTION_JAVA_VM=jdk
OPTION_TSONE_ID=0

# No color for terraforms logs
export nocolorarg=1

exit_on_error() {
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    echo "Success - $1"
  else
    echo "EXIT ON ERROR - HISTORY - $1 "
    history 2 | cut -c1-256
    echo "Command Failed (RESULT=$RESULT)"
    exit
  fi  
}

start_test() {
  export TEST_NAME=$1
  if [ "$OPTION_GROUP_NAME" != "none" ]; then
    export TEST_DIR=$TEST_HOME/$OPTION_DEPLOY/$TEST_NAME
  else
    export TEST_DIR=$TEST_HOME/no_group/$OPTION_DEPLOY/$TEST_NAME
    mkdir -p $TEST_DIR
  fi
  echo "-- TEST: $OPTION_DEPLOY - $TEST_NAME ---------------------------------------"   
}

# Speed test of 100 calls 
test_run_100() {
  START=$(date +%s.%N)
  UI_URL=`cat $TMP_PATH/ui_url.txt`
  x=0 
  while [ $x -lt 100 ]
    do
      curl $UI_URL/app/dept -s -D $TMP_PATH/speed_json.log > $TMP_PATH/speed.json
      if grep -q -i "deptno" $TMP_PATH/speed.json; then
         CSV_RUN100_OK=$(( $CSV_RUN100_OK + 1 ))
      fi
      x=$(( $x + 1 ))
    done  
  END=$(date +%s.%N)
  CSV_RUN100_SECOND=`echo "scale=2;($END-$START)/1" | bc`  
  echo "CSV_RUN100_SECOND=$CSV_RUN100_SECOND"
  echo "CSV_RUN100_OK=$CSV_RUN100_OK"
}

build_test () {
  SECONDS=0
  # Change to the TEST_HOME directory first in case that the creation of TEST_DIR failed
  cd $TEST_HOME
  cd $TEST_DIR
  pwd
  ./starter.sh build --auto-approve > build_$BUILD_ID.log 2>&1

  CSV_NAME=$PREFIX
  CSV_DIR=$TEST_DIR
  CSV_DATE=`date '+%Y%m%d-%H%M%S'`
  CSV_BUILD_SECOND=$SECONDS
  CSV_HTML_OK=0
  CSV_JSON_OK=0
  CSV_RUN100_SECOND=0
  CSV_RUN100_OK=0
  TMP_PATH="/tmp/$PREFIX"

  echo "build_secs_$BUILD_ID=$SECONDS" >> ${TEST_DIR}_time.txt
  if [ -f $TMP_PATH/result_html.html ]; then
    if grep -q -i "starter" $TMP_PATH/result_html.html; then
      echo -e "${COLOR_GREEN}RESULT HTML: OK${COLOR_NONE}"
      CSV_HTML_OK=1
    elif grep -q -i "deptno" $TMP_PATH/result_html.html; then
      echo -e "${COLOR_GREEN}RESULT HTML: OK${COLOR_NONE}"
      CSV_HTML_OK=1
    else
      echo -e "${COLOR_RED}RESULT HTML: ***** BAD ******${COLOR_NONE}"
    fi
    if grep -q -i "deptno" $TMP_PATH/result_dept.json; then
      echo -e "${COLOR_GREEN}RESULT JSON: OK${COLOR_NONE}                "`cat $TMP_PATH/result_dept.json` | cut -c 1-100  
      CSV_JSON_OK=1
    else
      echo -e "${COLOR_RED}RESULT JSON: ***** BAD ******${COLOR_NONE}  "`cat $TMP_PATH/result_dept.json` | cut -c 1-100 
    fi
    echo "RESULT INFO:                   "`cat $TMP_PATH/result_info.html` | cut -c 1-100
  else
    echo -e "${COLOR_RED}ERROR: No file $TMP_PATH/result_html.html${COLOR_NONE}"
  fi
  mv $TMP_PATH/result_html.html ${TEST_DIR}_${BUILD_ID}_result_html.html 2>/dev/null;
  mv $TMP_PATH/result_dept.json ${TEST_DIR}_${BUILD_ID}_result_dept.json 2>/dev/null;
  mv $TMP_PATH/result_info.html ${TEST_DIR}_${BUILD_ID}_result_info.html 2>/dev/null;
  mv $TMP_PATH/result_html.log  ${TEST_DIR}_${BUILD_ID}_result_html.log 2>/dev/null;
  mv $TMP_PATH/result_dept.log  ${TEST_DIR}_${BUILD_ID}_result_dept.log 2>/dev/null;
  mv $TMP_PATH/result_info.log  ${TEST_DIR}_${BUILD_ID}_result_info.log 2>/dev/null;

  if [ "$CSV_JSON_OK" == "1" ]; then
    test_run_100
  fi   
}

add_inprogress_rerun() {
  echo "./test_rerun.sh $TEST_DIR" >> $TEST_HOME/inprogress_rerun.sh
}

add_errors_rerun() {
  echo "./test_rerun.sh $TEST_DIR" >> $TEST_HOME/errors_rerun.sh
  # Remove from inprogress_rerun
  sed -i "\#$TEST_DIR#d" $TEST_HOME/inprogress_rerun.sh          
}

add_ok_rerun() {
  echo "./test_rerun.sh $TEST_DIR" >> $TEST_HOME/ok_rerun.sh
  # Remove from inprogress_rerun
  sed -i "\#$TEST_DIR#d" $TEST_HOME/inprogress_rerun.sh          
  # Remove from errors_rerun
  if grep -q "$TEST_DIR" $TEST_HOME/errors_rerun.sh; then
    sed -i "\#$TEST_DIR#d" $TEST_HOME/errors_rerun.sh          
    echo "./test_rerun.sh $TEST_DIR" >> $TEST_HOME/errors_old.sh
  fi  
}

build_test_destroy () {
  BUILD_ID=1
  build_test
  if [ "$BUILD_COUNT" = "2" ]; then
    BUILD_ID=2
    build_test
  fi  
  if [ -f $TEST_HOME/stop_after_build ]; then
    echo "-------------------------------------------------------"
    echo "stop_after_build file dectected"
    echo "Exiting before destroy_all.sh"
    echo "Last directory: $TEST_DIR"
    rm $TEST_HOME/stop_after_build
    exit
  fi  
  SECONDS=0
  ./starter.sh destroy --auto-approve > destroy.log 2>&1  
  if [ -d "target" ]; then
    # Avoid to have a lot of left resource in the tenancy after a lot of destroy that failed
    echo "FATAL ERROR: target directory not fully destroyed"
    echo "Last directory: $TEST_DIR"
    exit
  fi

  echo "destroy_secs=$SECONDS" >> ${TEST_DIR}_time.txt
  CSV_DESTROY_SECOND=$SECONDS
  cat ${TEST_DIR}_time.txt

  if [ "$OPTION_LANG" == "java" ]; then
    echo "$CSV_DATE,$OPTION_DEPLOY,$OPTION_LANG,$OPTION_JAVA_FRAMEWORK,$OPTION_JAVA_VM,$OPTION_DB,$OPTION_DB_INSTALL,$OPTION_UI,$OPTION_SHAPE,$CSV_NAME,$CSV_HTML_OK,$CSV_JSON_OK,$CSV_BUILD_SECOND,$CSV_DESTROY_SECOND,$CSV_RUN100_OK,$CSV_RUN100_SECOND" >> $TEST_HOME/result.csv 
  else
    echo "$CSV_DATE,$OPTION_DEPLOY,$OPTION_LANG,-,-,$OPTION_DB,$OPTION_DB_INSTALL,$OPTION_UI,$OPTION_SHAPE,$CSV_NAME,$CSV_HTML_OK,$CSV_JSON_OK,$CSV_BUILD_SECOND,$CSV_DESTROY_SECOND,$CSV_RUN100_OK,$CSV_RUN100_SECOND" >> $TEST_HOME/result.csv 
  fi
  if [ "$CSV_JSON_OK" != "1" ] || [ "$CSV_HTML_OK" != "1" ]; then
    echo "$CSV_DATE,$OPTION_DEPLOY,$OPTION_LANG,$OPTION_JAVA_FRAMEWORK,$OPTION_JAVA_VM,$OPTION_DB,$OPTION_DB_INSTALL,$OPTION_UI,$OPTION_SHAPE,$CSV_NAME,$CSV_HTML_OK,$CSV_JSON_OK,$CSV_BUILD_SECOND,$CSV_DESTROY_SECOND,$CSV_RUN100_OK,$CSV_RUN100_SECOND" >> $TEST_HOME/errors.csv 
    add_errors_rerun
  else 
    add_ok_rerun  
  fi

  if [ -f $TEST_HOME/stop_all_after_destroy ]; then
    echo "-------------------------------------------------------"
    echo "stop_all_after_destroy file dectected"
    echo "Last directory: $TEST_DIR"
    # rm $TEST_HOME/stop_all_after_destroy
    exit
  fi  
}

build_option() {
  mkdir_deploy
  if [ "$OPTION_TLS" != "none" ]; then
    NAME=tls-${OPTION_TLS}-${OPTION_DEPLOY}
  elif [ "$OPTION_LANG" == "java" ] && [ "$OPTION_DEPLOY" != "function" ]; then
    NAME=${OPTION_LANG}-${OPTION_JAVA_FRAMEWORK}-${OPTION_JAVA_VM}-${OPTION_DB}-${OPTION_UI}
  else
    NAME=${OPTION_LANG}-${OPTION_DB}-${OPTION_UI}
  fi
  if [ "$OPTION_SHAPE" != "amd" ]; then
    NAME=${NAME}-$OPTION_SHAPE
  fi  
  if [ "$OPTION_INFRA_AS_CODE" == "resource_manager" ]; then
    NAME=${NAME}-rm
  elif [ "$OPTION_INFRA_AS_CODE" == "from_resource_manager" ]; then
    NAME=${NAME}-frm
  fi  
  NAME=${NAME/_/-}
  NAME=${NAME/_/-}
  NAME=${NAME/_/-}
  start_test $NAME
  if [ "$TEST_DIRECTORY_ONLY" != "" ]; then
    if [ "$TEST_DIRECTORY_ONLY" == "$TEST_DIR" ]; then
      echo "FOUND TEST_DIRECTORY_ONLY: $TEST_DIR" 
    else
      echo "SKIP: $TEST_DIR" 
      return
    fi
  else 
    if grep -q "$TEST_DIR" $TEST_HOME/inprogress_rerun.sh; then
        echo "SKIP - FOUND in inprogress_rerun.sh: $TEST_DIR" 
        return
    fi  
    if grep -q "$TEST_DIR" $TEST_HOME/ok_rerun.sh; then
        echo "SKIP - FOUND in ok_rerun.sh: $TEST_DIR" 
        return
    fi  
    if [ "$TEST_ERRORS_ONLY" = "" ]; then
        if grep -q "$TEST_DIR" $TEST_HOME/errors_rerun.sh; then
            echo "SKIP - FOUND in errors_rerun.sh: $TEST_DIR" 
            return
        fi
    fi
  fi
    
  add_inprogress_rerun

  # Prevent to have undeleted resource when rerunning the test_suite
  if [ -d $TEST_DIR/target ]; then
     cd $TEST_DIR
     ./starter.sh destroy --auto-approve > destroy_before_refresh.log 2>&1  
     if [ -d $TEST_DIR/target ]; then
       echo "ERROR: Existing target directory detected. Destroy failed."
       exit 1
     fi
  fi

  # Prevent to start test build if the group_common was not finished
  if [ ! -f $TEST_HOME/group_common_env.sh ]; then
    echo "ERROR: $TEST_HOME/group_common_env.sh not found"
    exit 1
  fi 

  # Avoid 2 parallel creations of code
  while [ -f $TEST_HOME/oci_starter_busy ]; do
    echo "FOUND oci_starter_busy - Waiting"
    sleep 5
  done
  touch $TEST_HOME/oci_starter_busy

  cd $TEST_HOME/oci-starter
  if [ "$OPTION_GROUP_NAME" == "dummy" ]; then
    PREFIX=$NAME
    echo ./oci_starter.sh\
       -prefix $PREFIX \
       -deploy $OPTION_DEPLOY \
       -ui $OPTION_UI \
       -language $OPTION_LANG \
       -java_framework $OPTION_JAVA_FRAMEWORK \
       -java_vm $OPTION_JAVA_VM \
       -database $OPTION_DB \
       -db_password $TEST_DB_PASSWORD \
       -db_install $OPTION_DB_INSTALL \
       -group_common $OPTION_GROUP_NAME \
       -infra_as_code $OPTION_INFRA_AS_CODE \
       -shape $OPTION_SHAPE \
       -tls $OPTION_TLS \
       -compartment_ocid $EX_COMPARTMENT_OCID \
       -vcn_ocid $TF_VAR_vcn_ocid \
       -web_subnet_ocid $TF_VAR_web_subnet_ocid \
       -app_subnet_ocid $TF_VAR_app_subnet_ocid \
       -db_subnet_ocid $TF_VAR_db_subnet_ocid \
       -oke_ocid $OKE_OCID \
       -atp_ocid $TF_VAR_atp_ocid \
       -db_ocid $TF_VAR_db_ocid \
       -mysql_ocid $TF_VAR_mysql_ocid \
       -psql_ocid $TF_VAR_psql_ocid \
       -opensearch_ocid $TF_VAR_opensearch_ocid \
       -nosql_ocid $TF_VAR_nosql_ocid \
       -apigw_ocid $TF_VAR_apigw_ocid \
       -bastion_ocid $TF_VAR_bastion_ocid \
       -fnapp_ocid $TF_VAR_fnapp_ocid > ${TEST_DIR}.log 2>&1   
    ./oci_starter.sh \
       -prefix $PREFIX \
       -deploy $OPTION_DEPLOY \
       -ui $OPTION_UI \
       -language $OPTION_LANG \
       -java_framework $OPTION_JAVA_FRAMEWORK \
       -java_vm $OPTION_JAVA_VM \
       -database $OPTION_DB \
       -db_password $TEST_DB_PASSWORD \
       -db_install $OPTION_DB_INSTALL \
       -group_common $OPTION_GROUP_NAME \
       -infra_as_code $OPTION_INFRA_AS_CODE \
       -shape $OPTION_SHAPE \
       -tls $OPTION_TLS \
       -compartment_ocid $EX_COMPARTMENT_OCID \
       -vcn_ocid $TF_VAR_vcn_ocid \
       -web_subnet_ocid $TF_VAR_web_subnet_ocid \
       -app_subnet_ocid $TF_VAR_app_subnet_ocid \
       -db_subnet_ocid $TF_VAR_db_subnet_ocid \
       -oke_ocid $OKE_OCID \
       -atp_ocid $TF_VAR_atp_ocid \
       -db_ocid $TF_VAR_db_ocid \
       -mysql_ocid $TF_VAR_mysql_ocid \
       -psql_ocid $TF_VAR_psql_ocid \
       -opensearch_ocid $TF_VAR_opensearch_ocid \
       -nosql_ocid $TF_VAR_nosql_ocid \
       -apigw_ocid $TF_VAR_apigw_ocid \
       -bastion_ocid $TF_VAR_bastion_ocid \
       -fnapp_ocid $TF_VAR_fnapp_ocid >> ${TEST_DIR}.log 2>&1 
  else
    # Unique name to allow more generations of TLS certificates. The prefix is used as hostname for TLS http_01.
    OPTION_TSONE_ID=$((OPTION_TSONEID+1))
    PREFIX=tsone${OPTION_TSONE_ID}
    ./oci_starter.sh \
       -prefix $PREFIX \
       -deploy $OPTION_DEPLOY \
       -ui $OPTION_UI \
       -language $OPTION_LANG \
       -java_framework $OPTION_JAVA_FRAMEWORK \
       -java_vm $OPTION_JAVA_VM \
       -database $OPTION_DB \
       -db_password $TEST_DB_PASSWORD \
       -db_install $OPTION_DB_INSTALL \
       -group_common $OPTION_GROUP_NAME \
       -infra_as_code $OPTION_INFRA_AS_CODE \
       -shape $OPTION_SHAPE \
       -tls $OPTION_TLS \
       -compartment_ocid $EX_COMPARTMENT_OCID > ${TEST_DIR}.log 2>&1 
  fi
#      -db_compartment_ocid $EX_COMPARTMENT_OCID \
  rm $TEST_HOME/oci_starter_busy

  RESULT=$?
  if [ $RESULT -eq 0 ] && [ -d output ]; then 
    mkdir output/target
    cp $TEST_HOME/group_common/target/ssh* output/target/.
    rm -Rf $TEST_DIR
    if [ -f ${TEST_DIR}_time.txt ]; then
      rm ${TEST_DIR}_*
    fi
    mv output $TEST_DIR    
    cp $SCRIPT_DIR/test_after_build.sh $TEST_DIR/src/after_build.sh
    if [ -z $GENERATE_ONLY ]; then
      build_test_destroy
    fi           
  else
    echo -e "${COLOR_RED}ERROR ./oci_starter.sh failed.${COLOR_NONE}"
    echo "Check ${TEST_DIR}.log"
    add_errors_rerun
  fi  

  # Stop after finding the TEST_DIRECTORY_ONLY
  if [ "$TEST_DIRECTORY_ONLY" != "" ]; then
    exit
  fi
}

# Create the $OPTION_DEPLOY directory
mkdir_deploy() {
  if [ ! -d $TEST_HOME/$OPTION_DEPLOY ]; then
    mkdir $TEST_HOME/$OPTION_DEPLOY
    echo '. $PROJECT_DIR/../../group_common_env.sh' > $TEST_HOME/$OPTION_DEPLOY/group_common_env.sh
    chmod +x $TEST_HOME/$OPTION_DEPLOY/group_common_env.sh
  fi
}


pre_test_suite() {
  if [ -d $TEST_HOME ]; then
    echo "$TEST_HOME directory already exists"
    exit;
  fi

  # Avoid already set variables
  unset "${!TF_VAR@}"

  mkdir $TEST_HOME
  cd $TEST_HOME
  git clone https://github.com/mgueury/oci-starter

  SHAPE_GROUP="amd"
  if [[ `arch` == "aarch64" ]]; then
    SHAPE_GROUP="arm"
  fi
  GROUP_NAME="ts${SHAPE_GROUP}"

  cd $TEST_HOME/oci-starter
  ./oci_starter.sh -group_name $GROUP_NAME -group_common atp,mysql,psql,opensearch,nosql,database,fnapp,apigw,oke -compartment_ocid $EX_COMPARTMENT_OCID -db_password $TEST_DB_PASSWORD -shape $SHAPE_GROUP
  exit_on_error "oci_starter.sh"
  mv output/group_common ../group_common
  cd $TEST_HOME/group_common
  echo "# Test Suite use 2 nodes to avoid error: Too Many Pods (110 pods/node K8s limit)" >> terraform.tfvars
  echo "node_pool_size=2" >> terraform.tfvars
  echo "" >> terraform.tfvars
  ./starter.sh build --auto-approve
  exit_on_error "starter.sh build"
  date
  echo "CSV_DATE,OPTION_DEPLOY,OPTION_LANG,OPTION_JAVA_FRAMEWORK,OPTION_JAVA_VM,OPTION_DB,OPTION_DB_INSTALL,OPTION_UI,OPTION_SHAPE,CSV_NAME,CSV_HTML_OK,CSV_JSON_OK,CSV_BUILD_SECOND,CSV_DESTROY_SECOND,CSV_RUN100_OK,CSV_RUN100_SECOND" > $TEST_HOME/result.csv 
}

pre_git_refresh() {
  cd $TEST_HOME/oci-starter
  git pull origin main
  echo "----------------------------------------------------------------------------" >> $TEST_HOME/errors_rerun.sh
}

post_test_suite() {
  date

  cd $TEST_HOME/group_common
  ./starter.sh destroy --auto-approve
}

