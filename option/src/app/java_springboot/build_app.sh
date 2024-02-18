#!/bin/bash
# Build_app.sh
#
# Compute:
# - build the code 
# - create a $ROOT/target/compute/$APP_DIR directory with the compiled files
# - and a start.sh to start the program
# Docker:
# - build the image
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../../env.sh -no-auto
. $BIN_DIR/build_common.sh
java_build_common

mkdir src/main/resources
cp application.properties.tmpl src/main/resources/application.properties
replace_db_user_password_in_file src/main/resources/application.properties

if is_deploy_compute; then

  if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
    # Native Build about 14 mins. Output is ./demo
    mvn -Pnative native:compile
  else 
    mvn package -DskipTests
  fi
  exit_on_error

  # Replace the user and password
  cp start.sh install.sh target/.

  mkdir -p ../../target/compute/$APP_DIR
  cp -r target/* ../../target/compute/$APP_DIR/.
  replace_db_user_password_in_file ../../target/compute/$APP_DIR/start.sh  
else
  docker image rm ${TF_VAR_prefix}-app:latest
 
  if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
    mvn -Pnative spring-boot:build-image -Dspring-boot.build-image.imageName=${TF_VAR_prefix}-app:latest
  else
    # It does not use mvn build image. Else no choice of the JIT
    # mvn spring-boot:build-image -Dspring-boot.build-image.imageName=${TF_VAR_prefix}-app:latest
    mvn package -DskipTests
    exit_on_error
    docker build -t ${TF_VAR_prefix}-app:latest . 
  fi
  exit_on_error
fi  
