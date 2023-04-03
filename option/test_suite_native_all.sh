#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
export TEST_HOME=$SCRIPT_DIR/test_group_all
. $SCRIPT_DIR/test_suite_shared.sh

loop_ui() {
  OPTION_UI=html 
  build_option
}

loop_db() {
  # OPTION_DB=database 
  # loop_ui  
  OPTION_DB=atp 
  loop_ui
  OPTION_DB=mysql
  loop_ui
  OPTION_DB=none
  loop_ui  
}

loop_java_vm() {
  OPTION_JAVA_VM=graalvm-native
  loop_db
}

loop_java_framework () {
  OPTION_JAVA_FRAMEWORK=springboot 
  loop_java_vm
  OPTION_JAVA_FRAMEWORK=helidon 
  loop_java_vm
  OPTION_JAVA_FRAMEWORK=micronaut
  loop_java_vm
}

loop_lang () {
  mkdir_deploy

  OPTION_LANG=java 
  OPTION_JAVA_VM=jdk 
  loop_java_framework
}

loop_deploy() {
  OPTION_DEPLOY=kubernetes
  loop_lang
  OPTION_DEPLOY=compute
  loop_lang
  OPTION_DEPLOY=container_instance
  loop_lang
}

pre_test_suite
# pre_git_refresh
cd $TEST_HOME
. ./group_common_env.sh
loop_deploy
post_test_suite
