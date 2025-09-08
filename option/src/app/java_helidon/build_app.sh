#!/usr/bin/env bash
# Build_app.sh
#
# Compute:
# - build the code 
# - create a $ROOT/target/compute/$APP_DIR directory with the compiled files
# - and a start.sh to start the program
# Docker:
# - build the image
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../../starter.sh env -no-auto
. $BIN_DIR/build_common.sh

java_build_common

# XXXX microprofile-config.properties values should all go in start.sh like JDBC_USER
cp microprofile-config.properties.tmpl src/main/resources/META-INF/microprofile-config.properties
replace_db_user_password_in_file src/main/resources/META-INF/microprofile-config.properties
if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
  # XXXX The sample use Helidon+JPA 3.1 that is not supported with GraalVM Native 22.3
  # There are 2 issues with Work-arounds
  # (1) OracleDialect constructor in reflect-config.json 
  # (2) env var JAVAX_SQL_DATASOURCE_DS1_DATASOURCE_URL is not detected (Helidon bug logged) 
  sed -i "s&##JDBC_URL##&$JDBC_URL&" src/main/resources/META-INF/microprofile-config.properties
fi

if is_deploy_compute; then
  # -Dnet.bytebuddy.experimental=true is needed in helidon 3 for Java 21
  if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
    mvn package -Pnative-image -Dnative.image.buildStatic -DskipTests -Dnet.bytebuddy.experimental=true 
  else 
    mvn package -DskipTests -Dnet.bytebuddy.experimental=true
  fi
  exit_on_error "mvn package"
  cp start.sh install.sh target/.
  mkdir -p ../../target/compute/$APP_DIR
  cp -r target/* ../../target/compute/$APP_DIR/.
else
  docker image rm ${TF_VAR_prefix}-app:latest
  if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
    docker build -f Dockerfile.native -t ${TF_VAR_prefix}-app:latest . 
  else
    docker build -t ${TF_VAR_prefix}-app:latest . 
  fi
  exit_on_error "docker build"  
fi  

