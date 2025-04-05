#!/bin/bash
if [ "$PROJECT_DIR" == "" ]; then
  echo "ERROR: PROJECT_DIR undefined. Please use starter.sh upgrade"
  exit 1
fi  
cd $PROJECT_DIR


# Call the script with --auto-approve to upgrade without prompt
. starter.sh env -no-auto
title "OCI Starter - Upgrade"
echo 
echo 

export UPGRADE_DIR=$PROJECT_DIR/upgrade
if [ -d upgrade ]; then
  echo "ERROR: $UPGRADE_DIR exists already"
  exit
di

if [ "$1" != "--auto-approve" ]; then
  echo "Warning: Use at your own risk."
  echo "It tries to upgrade the OCI-Starter version used to the latest one."
  read -p "Do you want to proceed? (yes/no) " yn

  case $yn in 
  	yes ) echo Upgrading;;
	no ) echo Exiting...;
		exit;;
	* ) echo Invalid response;
		exit 1;;
  esac
fi
. starter.sh env

if [ -d $TARGET_DIR ]; then
  read -p "Warning: Target dir detected. Are you sure that you want to continue (yes/no) " yn
  case $yn in 
  	yes ) echo Upgrading;;
	no ) echo Exiting...;
		exit;;
	* ) echo Invalid response;
		exit 1;;
  esac
fi

title "Remove variable that should not be exposed"

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

title "Call OCI Starter Website to get the latest OCI starter script with the same parameters"
echo "curl -k https://www.ocistarter.com/app/zip?$PARAM_LIST"


cd $PROJECT_DIR
mkdir $UPGRADE_DIR
cd $UPGRADE_DIR
curl -k "https://www.ocistarter.com/app/zip?$PARAM_LIST" --output upgrade.zip
unzip upgrade.zip
rm upgrade.zip
mv $TF_VAR_prefix/* $TF_VAR_prefix/.*  .
rmdir $TF_VAR_prefix

title "Upgrade directory"
mkdir not_used
mv src not_used
echo "Saved upgrade/src to upgrade/not_used/src"

mv env.sh not_used
echo "Saved upgrade/env.sh to upgrade/not_used/env.sh"

cp -r ../src .
echo "Replaced the upgrade/src directory by src"

cp ../env.sh .
echo "Replaced the upgrade/env.sh directory by env.sh"

echo "Done."
echo 
echo "Next steps:"
echo "cd upgrade"
echo "./starter.sh build"
echo 
echo "If OK:"
echo "cd .."
echo "mkdir orig"
echo "mv * orig"
echo "mv orig/upgrade/* ."
echo "echo orig > .gitignore" 

