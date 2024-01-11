#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
export TEST_HOME=$SCRIPT_DIR/test_group_all
. $SCRIPT_DIR/test_suite_shared.sh
export BUILD_COUNT=1

loop_ui() {
  if [ "$OPTION_LANG" == "php" ]; then
    OPTION_UI=php 
    build_option
  elif [ "$OPTION_LANG" == "apex" ]; then
    OPTION_UI=apex 
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
    if [ "$OPTION_LANG" == "node" ] && [ "$OPTION_DB" == "atp" ]; then
      OPTION_UI=api
      build_option
    fi     
  fi
}

loop_shape() {
  OPTION_SHAPE=amd 
  loop_ui
  if [ "$OPTION_DEPLOY" == "compute" ] && [ "$OPTION_DB" == "none" ]; then
    OPTION_SHAPE=ampere
    loop_ui
  fi
}

loop_db() {
  if [ "$OPTION_DEPLOY" != "instance_pool" ] ; then
    # OPTION_DB=database 
    # loop_ui  
    OPTION_DB=atp 
    loop_shape
    OPTION_DB=psql 
    loop_shape  
    OPTION_DB=mysql
    loop_shape
  fi  
  OPTION_DB=none
  loop_shape
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
  if [ "$OPTION_DEPLOY" == "compute" ]; then
    OPTION_LANG=apex
    OPTION_DB=atp 
    loop_shape
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

loop_shared_compute() {
  # Shared compute / LiveLabs Green Button
  OPTION_SHAPE=amd
  OPTION_LANG=java
  OPTION_JAVA_VM=jdk
  OPTION_JAVA_FRAMEWORK=springboot
  OPTION_DB_INSTALL=shared_compute
  OPTION_UI=html
  OPTION_DB=db_free
  build_option  
  OPTION_DB=mysql
  build_option   

  # Helidon 4
  OPTION_DB_INSTALL=default
  OPTION_DB=atp
  OPTION_JAVA_FRAMEWORK=helidon4 
  build_option   
}

loop_tls_deploy() {
  OPTION_DEPLOY=compute
  build_option  
  OPTION_DEPLOY=kubernetes
  build_option  
  OPTION_DEPLOY=instance_pool
  build_option  
  OPTION_DEPLOY=container_instance
  build_option  
  OPTION_DEPLOY=function
  build_option  
}

loop_tls() {
  # TLS
  OPTION_GROUP_NAME=none
  OPTION_LANG=java
  OPTION_JAVA_VM=jdk
  OPTION_JAVA_FRAMEWORK=springboot
  OPTION_UI=html
  OPTION_DB=none
  OPTION_TLS=existing_dir
  loop_tls_deploy
  # existing_ocid is part of existing_dir

  OPTION_TLS=new_http_01
  OPTION_DEPLOY=compute
  build_option  

  OPTION_TLS=new_dns_01
  OPTION_DEPLOY=container_instance
  build_option  

  OPTION_GROUP_NAME=dummy
}

loop_deploy() {
  OPTION_DEPLOY=compute
  loop_shared_compute
  loop_lang  
  OPTION_DEPLOY=kubernetes
  loop_lang
  OPTION_DEPLOY=instance_pool 
  OPTION_LANG=java
  OPTION_JAVA_FRAMEWORK=springboot
  OPTION_DB=atp 
  loop_shape  
  OPTION_DEPLOY=container_instance 
  loop_lang
  OPTION_DEPLOY=function 
  loop_lang

  loop_tls
}

generate_only() {
  if [ -d $TEST_HOME ]; then    
    echo "$TEST_HOME directory detected"
  else
    echo "$TEST_HOME does not exist"
    exit
  fi
  rm -rf $TEST_HOME/compute $TEST_HOME/kubernetes $TEST_HOME/container_instance $TEST_HOME/function
  export GENERATE_ONLY=true
}

pre_test_suite
# pre_git_refresh
# generate_only
cd $TEST_HOME
. ./group_common_env.sh
# export TEST_ERROR_ONLY=TRUE
loop_deploy
post_test_suite
