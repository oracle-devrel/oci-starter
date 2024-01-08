#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh

## declare an array variable
declare -a arr=("element1" "element2" "element3")

PARAM_LIST=""
## now loop through the above array
for i in "${PARAMS[@]}"
do
   echo "$i"
   PARAM_LIST=" ${PARAM_LIST} -${i} ${!i}"
done
echo "./oci_starter.sh$PARAM_LIST"


echo
echo "original command"
echo "./oci_starter.sh -deploy compute -compartment_ocid $EX_COMPARTMENT_OCID -database atp -ui html -language apex -db_password $TEST_DB_PASSWORD -tls existing_ocid"
