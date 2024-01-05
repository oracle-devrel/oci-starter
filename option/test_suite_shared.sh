#!/bin/bash
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

# No color for terraforms logs
export nocolorarg=1

exit_on_error() {
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    echo "Success"
  else
    echo "Failed (RESULT=$RESULT)"
    exit $RESULT
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
  UI_URL=`cat /tmp/ui_url.txt`
  x=0 
  while [ $x -lt 100 ]
    do
      curl $UI_URL/app/dept -s -D /tmp/speed_json.log > /tmp/speed.json
      if grep -q -i "deptno" /tmp/speed.json; then
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
  ./build.sh > build_$BUILD_ID.log 2>&1

  CSV_NAME=$NAME
  CSV_DIR=$TEST_DIR
  CSV_DATE=`date '+%Y%m%d-%H%M%S'`
  CSV_BUILD_SECOND=$SECONDS
  CSV_HTML_OK=0
  CSV_JSON_OK=0
  CSV_RUN100_SECOND=0
  CSV_RUN100_OK=0

  echo "build_secs_$BUILD_ID=$SECONDS" >> ${TEST_DIR}_time.txt
  if [ -f /tmp/result.html ]; then
    if grep -q -i "starter" /tmp/result.html; then
      echo -e "${COLOR_GREEN}RESULT HTML: OK${COLOR_NONE}"
      CSV_HTML_OK=1
    else
      echo -e "${COLOR_RED}RESULT HTML: ***** BAD ******${COLOR_NONE}"
    fi
    if grep -q -i "deptno" /tmp/result.json; then
      echo -e "${COLOR_GREEN}RESULT JSON: OK${COLOR_NONE}                "`cat /tmp/result.json` | cut -c 1-100  
      CSV_JSON_OK=1
    else
      echo -e "${COLOR_RED}RESULT JSON: ***** BAD ******${COLOR_NONE}  "`cat /tmp/result.json` | cut -c 1-100 
    fi
    echo "RESULT INFO:                   "`cat /tmp/result.info` | cut -c 1-100
  else
    echo "No file /tmp/result.html"
  fi
  mv /tmp/result.html ${TEST_DIR}_result_$BUILD_ID.html
  mv /tmp/result.json ${TEST_DIR}_result_$BUILD_ID.json
  mv /tmp/result.info ${TEST_DIR}_result_$BUILD_ID.info
  mv /tmp/result_html.log ${TEST_DIR}_result_html_$BUILD_ID.log
  mv /tmp/result_json.log ${TEST_DIR}_result_json_$BUILD_ID.log
  mv /tmp/result_info.log ${TEST_DIR}_result_info_$BUILD_ID.log

  if [ "$CSV_JSON_OK" == "1" ]; then
    test_run_100
  fi   
}

echo_errors_csv() {
  echo "$CSV_DATE,$OPTION_DEPLOY,$OPTION_LANG,$OPTION_JAVA_FRAMEWORK,$OPTION_JAVA_VM,$OPTION_DB,$OPTION_DB_INSTALL,$OPTION_UI,$OPTION_SHAPE,$CSV_NAME,$CSV_HTML_OK,$CSV_JSON_OK,$CSV_BUILD_SECOND,$CSV_DESTROY_SECOND,$CSV_RUN100_OK,$CSV_RUN100_SECOND" >> $TEST_HOME/errors.csv 
  echo "./test_rerun.sh $TEST_DIR" >> $TEST_HOME/error_rerun.sh
}

build_test_destroy () {
  BUILD_ID=1
  build_test
  if [ "$BUILD_COUNT" = "2" ]; then
    BUILD_ID=2
    build_test
  fi  
  if [ -f $TEST_HOME/stop_token ]; then
    echo "-------------------------------------------------------"
    echo "stop_token file dectected"
    echo "Exiting before destroy.sh"
    echo "Last directory: $TEST_DIR"
    rm $TEST_HOME/stop_token
    exit
  fi  
  ./destroy.sh --auto-approve > destroy.log 2>&1  
  echo "destroy_secs=$SECONDS" >> ${TEST_DIR}_time.txt
  CSV_DESTROY_SECOND=$SECONDS
  cat ${TEST_DIR}_time.txt

  if [ "$OPTION_LANG" == "java" ]; then
    echo "$CSV_DATE,$OPTION_DEPLOY,$OPTION_LANG,$OPTION_JAVA_FRAMEWORK,$OPTION_JAVA_VM,$OPTION_DB,$OPTION_DB_INSTALL,$OPTION_UI,$OPTION_SHAPE,$CSV_NAME,$CSV_HTML_OK,$CSV_JSON_OK,$CSV_BUILD_SECOND,$CSV_DESTROY_SECOND,$CSV_RUN100_OK,$CSV_RUN100_SECOND" >> $TEST_HOME/result.csv 
  else
    echo "$CSV_DATE,$OPTION_DEPLOY,$OPTION_LANG,-,-,$OPTION_DB,$OPTION_DB_INSTALL,$OPTION_UI,$OPTION_SHAPE,$CSV_NAME,$CSV_HTML_OK,$CSV_JSON_OK,$CSV_BUILD_SECOND,$CSV_DESTROY_SECOND,$CSV_RUN100_OK,$CSV_RUN100_SECOND" >> $TEST_HOME/result.csv 
  fi
  if [ "$CSV_JSON_OK" != "1" ] || [ "$CSV_HTML_OK" != "1" ]; then
    echo_errors_csv
  fi
}

build_option() {
  mkdir_deploy
  if [ "$OPTION_DB_INSTALL" == "shared_compute" ]; then
    NAME=shared-compute-${OPTION_DB}
  elif [ "$OPTION_TLS" != "none" ]; then
    NAME=tls-${OPTION_TLS}-${OPTION_DEPLOY}
  elif [ "$OPTION_LANG" == "java" ] && [ "$OPTION_DEPLOY" != "function" ]; then
    NAME=${OPTION_LANG}-${OPTION_JAVA_FRAMEWORK}-${OPTION_JAVA_VM}-${OPTION_DB}-${OPTION_UI}
  else
    NAME=${OPTION_LANG}-${OPTION_DB}-${OPTION_UI}
  fi
  if [ "$OPTION_SHAPE" != "amd" ]; then
    NAME=${NAME}-$OPTION_SHAPE
  fi  
  NAME=${NAME/_/-}
  start_test $NAME
  cd $TEST_HOME/oci-starter
  if [ "$OPTION_GROUP_NAME" == "dummy" ]; then
    ./oci_starter.sh \
       -prefix $NAME \
       -deploy $OPTION_DEPLOY \
       -ui $OPTION_UI \
       -language $OPTION_LANG \
       -java_framework $OPTION_JAVA_FRAMEWORK \
       -java_vm $OPTION_JAVA_VM \
       -database $OPTION_DB \
       -db_password $TEST_DB_PASSWORD \
       -db_install $OPTION_DB_INSTALL \
       -group_common $OPTION_GROUP_NAME \
       -shape $OPTION_SHAPE \
       -tls $OPTION_TLS \
       -compartment_ocid $EX_COMPARTMENT_OCID \
       -vcn_ocid $TF_VAR_vcn_ocid \
       -public_subnet_ocid $TF_VAR_public_subnet_ocid \
       -private_subnet_ocid $TF_VAR_private_subnet_ocid \
       -oke_ocid $TF_VAR_oke_ocid \
       -atp_ocid $TF_VAR_atp_ocid \
       -db_ocid $TF_VAR_db_ocid \
       -mysql_ocid $TF_VAR_mysql_ocid \
       -psql_ocid $TF_VAR_psql_ocid \
       -auth_token $OCI_TOKEN \
       -apigw_ocid $TF_VAR_apigw_ocid \
       -bastion_ocid $TF_VAR_bastion_ocid \
       -fnapp_ocid $TF_VAR_fnapp_ocid > ${TEST_DIR}.log 2>&1 
  else
    ./oci_starter.sh \
       -prefix tsone \
       -deploy $OPTION_DEPLOY \
       -ui $OPTION_UI \
       -language $OPTION_LANG \
       -java_framework $OPTION_JAVA_FRAMEWORK \
       -java_vm $OPTION_JAVA_VM \
       -database $OPTION_DB \
       -db_password $TEST_DB_PASSWORD \
       -db_install $OPTION_DB_INSTALL \
       -group_common $OPTION_GROUP_NAME \
       -shape $OPTION_SHAPE \
       -tls $OPTION_TLS \
       -compartment_ocid $EX_COMPARTMENT_OCID > ${TEST_DIR}.log 2>&1 
  fi
#      -db_compartment_ocid $EX_COMPARTMENT_OCID \

  if [ -d output ]; then 
    mkdir output/target
    cp $TEST_HOME/group_common/target/ssh* output/target/.
    rm -Rf $TEST_DIR
    if [ -f ${TEST_DIR}_time.txt ]; then
      rm ${TEST_DIR}_time.txt
    fi
    mv output $TEST_DIR    
    if [ -z $GENERATE_ONLY ]; then
      build_test_destroy
    fi           
  else
    echo "ERROR: no output directory"  
    echo_errors_csv
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

  cd $TEST_HOME/oci-starter
  ./oci_starter.sh -group_name tsall -group_common atp,mysql,psql,database,fnapp,apigw,oke,db_free -compartment_ocid $EX_COMPARTMENT_OCID -db_password $TEST_DB_PASSWORD -auth_token $OCI_TOKEN
  exit_on_error
  mv output/group_common ../group_common
  cd $TEST_HOME/group_common
  ./build.sh
  exit_on_error
  date
  echo "CSV_DATE,OPTION_DEPLOY,OPTION_LANG,OPTION_JAVA_FRAMEWORK,OPTION_JAVA_VM,OPTION_DB,OPTION_DB_INSTALL,OPTION_UI,OPTION_SHAPE,CSV_NAME,CSV_HTML_OK,CSV_JSON_OK,CSV_BUILD_SECOND,CSV_DESTROY_SECOND,CSV_RUN100_OK,CSV_RUN100_SECOND" > $TEST_HOME/result.csv 
}

pre_git_refresh() {
  cd $TEST_HOME/oci-starter
  git pull origin main
}

post_test_suite() {
  date

  cd $TEST_HOME/group_common
  ./destroy.sh --auto-approve
}

