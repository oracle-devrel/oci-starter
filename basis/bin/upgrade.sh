#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh

## Remove variable that should not be exposed
export `compgen -A variable | grep _ocid | grep _ocid | sed 's/$/=__TO_FILL__/'`
export TF_VAR_db_password=__TO_FILL__
export TF_VAR_auth_token=__TO_FILL__

PARAM_LIST=""

IFS=','
read -ra ARR <<<"$OCI_STARTER_PARAMS" 
for p in "${ARR[@]}"; 
do  
  VAR_NAME="TF_VAR_${p}"
  VAR_VALUE=${!VAR_NAME}
  echo "$p - $VAR_NAME - $VAR_VALUE"
  if [ "$VAR_VALUE" != "" ]; then
    PARAM_LIST="${PARAM_LIST}${p}=${!VAR_NAME}&"
  fi
done
PARAM_LIST=`echo $PARAM_LIST|sed 's/&$//'`

echo "curl -k https://www.ocistarter.com/app/zip?$PARAM_LIST"

UPGRADE_DIR="upgrade$(date +%Y%m%d%H%M%S)"

cd $PROJECT_DIR
mkdir $UPGRADE_DIR
cd $UPGRADE_DIR
curl -k "https://www.ocistarter.com/app/zip?$PARAM_LIST" --output upgrade.zip
unzip upgrade.zip
rm upgrade.zip
mv $TF_VAR_prefix/* $TF_VAR_prefix/.*  .
rmdir $TF_VAR_prefix
mkdir orig
mv src orig
mv env.sh orig
cp -r ../src .
cp ../env.sh .

echo
echo "Upgrade directory created: $UPGRADE_DIR"
