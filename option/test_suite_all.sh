#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
export TEST_HOME=$SCRIPT_DIR/test_all
. $HOME/bin/env_oci_starter_testsuite.sh

# No color for terraforms logs
export nocolorarg=1

start_test () {
  export TEST_NAME=$1
  export TEST_DIR=$TEST_HOME/$OPTION_DEPLOY/$TEST_NAME
  echo "-- TEST: $OPTION_DEPLOY - $TEST_NAME ---------------------------------------"   
}

build_test () {
  SECONDS=0
  # Change to the TEST_HOME directory first in case that the creation of TEST_DIR failed
  cd $TEST_HOME
  cd $TEST_DIR
  pwd
  ./build.sh > build_$BUILD_ID.log 2>&1  
  echo "build_secs_$BUILD_ID=$SECONDS" >> ${TEST_DIR}_time.txt
  if [ -f /tmp/result.html ]; then
    if grep -q -i "starter" /tmp/result.html; then
      echo "RESULT HTML: OK"
    else
      echo "RESULT HTML: ***** BAD ******"
    fi
    if grep -q -i "deptno" /tmp/result.json; then
      echo "RESULT JSON: OK                "`cat /tmp/result.json | cut -c 1-80`... 
    else
      echo "RESULT JSON: ***** BAD ******  "`cat /tmp/result.json | cut -c 1-80`... 
    fi
    echo "RESULT INFO:                   "`cat /tmp/result.info | cut -c 1-80`
  else
    echo "No file /tmp/result.html"
  fi
  mv /tmp/result.html ${TEST_DIR}_result_$BUILD_ID.html
  mv /tmp/result.json ${TEST_DIR}_result_$BUILD_ID.json
  mv /tmp/result.info ${TEST_DIR}_result_$BUILD_ID.info
  mv /tmp/result_html.log ${TEST_DIR}_result_html_$BUILD_ID.log
  mv /tmp/result_json.log ${TEST_DIR}_result_json_$BUILD_ID.log
  mv /tmp/result_info.log ${TEST_DIR}_result_info_$BUILD_ID.log
}

build_test_destroy () {
  BUILD_ID=1
  build_test
  BUILD_ID=2
  build_test
  ./destroy.sh --auto-approve > destroy.log 2>&1  
  echo "destroy_secs=$SECONDS" >> ${TEST_DIR}_time.txt
  cat ${TEST_DIR}_time.txt
}

build_option() {
  if [ "$OPTION_LANG" == "java" ] && [ "$OPTION_DEPLOY" != "function" ]; then
    NAME=${OPTION_LANG}-${OPTION_JAVA_FRAMEWORK}-${OPTION_JAVA_VM}-${OPTION_DB}-${OPTION_UI}
  else
    NAME=${OPTION_LANG}-${OPTION_DB}-${OPTION_UI}
  fi
  start_test $NAME
  cd $TEST_HOME/oci-starter
  ./oci_starter.sh \
       -prefix $NAME \
       -deploy $OPTION_DEPLOY \
       -ui $OPTION_UI \
       -language $OPTION_LANG \
       -java_framework $OPTION_JAVA_FRAMEWORK \
       -java_vm $OPTION_JAVA_VM \
       -database $OPTION_DB \
       -db_password $TEST_DB_PASSWORD \
       -compartment_ocid $EX_COMPARTMENT_OCID \
       -vcn_ocid $EX_VNC_OCID \
       -public_subnet_ocid $EX_SUBNET_OCID \
       -private_subnet_ocid $EX_SUBNET_OCID \
       -oke_ocid $EX_OKE_OCID \
       -atp_ocid $EX_ATP_OCID \
       -mysql_ocid $EX_MYSQL_OCID \
       -db_ocid $EX_DB_OCID \
       -db_compartment_ocid $EX_DB_COMPARTMENT_OCID \
       -auth_token $OCI_TOKEN \
       -apigw_ocid $EX_APIGW_OCID \
       -bastion_ocid $EX_BASTION_OCID \
       -fnapp_ocid $EX_FNAPP_OCID > ${TEST_DIR}.log 2>&1 
  if [ -d output ]; then 
    mv output $TEST_DIR               
    build_test_destroy
  else
    echo "Error: no output directory"  
  fi  
}

loop_ui() {
  if [ "$OPTION_LANG" == "php" ]; then
    OPTION_UI=php 
    build_option
  else
    OPTION_UI=html 
    build_option
    # Test all the UIs with ORDS only
    if [ "$OPTION_DEPLOY" == "kubernetes" ] && [ "$OPTION_LANG" == "ords" ]; then
      OPTION_UI=reactjs
      build_option
      OPTION_UI=angular
      build_option
      OPTION_UI=jet
      build_option
    fi 
    if [ "$OPTION_JAVA_FRAMEWORK" == "tomcat" ]; then
      OPTION_UI=jsp
      build_option
    fi  
  fi
}

loop_db() {
  OPTION_DB=atp 
  loop_ui
  OPTION_DB=mysql
  loop_ui
  if [ "$OPTION_DEPLOY" == "kubernetes" ] || [ "$OPTION_DEPLOY" == "function" ] ; then
    OPTION_DB=none
    loop_ui
  fi 
}

loop_java_vm() {
  OPTION_JAVA_VM=jdk 
  loop_db
  if [ "$OPTION_JAVA_FRAMEWORK" == "springboot" ] ; then
    OPTION_JAVA_VM=graalvm
    loop_db
  fi  
}

loop_java_framework () {
  OPTION_JAVA_FRAMEWORK=springboot 
  loop_java_vm
  OPTION_JAVA_FRAMEWORK=helidon 
  loop_java_vm
  OPTION_JAVA_FRAMEWORK=micronaut
  loop_java_vm
  OPTION_JAVA_FRAMEWORK=tomcat
  loop_db
  # Reset the value to default
  OPTION_JAVA_FRAMEWORK=springboot
}

loop_lang () {
  mkdir $TEST_HOME/$OPTION_DEPLOY
  if [ "$OPTION_DEPLOY" == "kubernetes" ]; then
    export EX_MYSQL_OCID=$EX_OKE_MYSQL_OCID
    export EX_VNC_OCID=$EX_OKE_VNC_OCID
    export EX_SUBNET_OCID=$EX_OKE_SUBNET_OCID
    export EX_ATP_OCID=$EX_OKE_ATP_OCID
  else
    export EX_MYSQL_OCID=$EX_SHARED_MYSQL_OCID
    export EX_VNC_OCID=$EX_SHARED_VNC_OCID
    export EX_SUBNET_OCID=$EX_SHARED_SUBNET_OCID
    export EX_ATP_OCID=$EX_OKE_ATP_OCID
  fi

  OPTION_LANG=java 
  OPTION_JAVA_VM=jdk 
  if [ "$OPTION_DEPLOY" == "function" ]; then
    # Dummy value, not used
    OPTION_JAVA_FRAMEWORK=helidon
    loop_db
  else
    loop_java_framework
  fi
  if [ "$OPTION_DEPLOY" != "function" ]; then
    OPTION_LANG=php
    loop_db
  fi  
  OPTION_LANG=go
  loop_db  
  OPTION_LANG=node 
  loop_db
  OPTION_LANG=python
  loop_db
  OPTION_LANG=dotnet
  loop_db
  # XXXX ORDS works only with ATP (DBSystems is not test/done)
  OPTION_LANG=ords
  OPTION_DB=atp 
  loop_ui
}

loop_deploy() {
  OPTION_DEPLOY=container_instance 
  loop_lang
  OPTION_DEPLOY=function 
  loop_lang
  OPTION_DEPLOY=kubernetes
  loop_lang
  OPTION_DEPLOY=compute
  loop_lang
}

if [ -d $TEST_HOME ]; then
  echo "$TEST_HOME directory already exists"
  exit;
fi

# Avoid already set variables
unset "${!TF_VAR@}"

mkdir $TEST_HOME
cd $TEST_HOME
git clone https://github.com/mgueury/oci-starter


date
loop_deploy
date