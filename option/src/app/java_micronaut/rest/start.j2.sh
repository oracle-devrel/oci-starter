#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/target
. $HOME/compute/tf_env.sh

# Start Java with Native or JIT (JDK/GraalVM)
if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
    ./demo > ../rest.log 2>&1 
else  
    java -jar demo-0.1.jar > ../rest.log 2>&1 
fi