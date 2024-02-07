#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

{% import "start_sh.j2_macro" as m with context %}
{{ m.env() }}

if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
  ./demo > app.log 2>&1 
else  
  java -jar demo-0.1.jar > app.log 2>&1 
fi