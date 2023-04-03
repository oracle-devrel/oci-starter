#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

export DB_USER=##DB_USER##
export DB_PASSWORD=##DB_PASSWORD##
export JDBC_URL="##JDBC_URL##"
export SPRING_APPLICATION_JSON='{ "db.url": "Java - SpringBoot" }'
export TF_VAR_java_vm=##TF_VAR_java_vm##

# Start Java with Native or JIT (JDK/GraalVM)
if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
  ./demo > app.log 2>&1 
else  
  java -jar demo-0.0.1-SNAPSHOT.jar > app.log 2>&1 
fi