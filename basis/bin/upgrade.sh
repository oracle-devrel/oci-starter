#!/bin/bash
if [ "$PROJECT_DIR" == "" ]; then
  echo "ERROR: PROJECT_DIR undefined. Please use starter.sh upgrade"
  exit 1
fi  
cd $PROJECT_DIR


if cat env.sh | grep -q "PROJECT_DIR="; then
  . env.sh -no-auto
else
  . starter.sh env -no-auto
fi

title "OCI Starter - Upgrade"

export UPGRADE_DIR=$PROJECT_DIR/upgrade
if [ -d upgrade ]; then
  echo "ERROR: $UPGRADE_DIR exists already"
  exit
fi

if [ "$1" != "--auto-approve" ]; then
  echo "Warning: Use at your own risk."
  echo "Upgrade the bin directory (OCI-Starter) to the latest one."
  read -p "Do you want to proceed? (yes/no) " yn

  case $yn in 
  	yes ) echo Upgrading;;
	no ) echo Exiting...;
		exit;;
	* ) echo Invalid response;
		exit 1;;
  esac
fi

# if cat env.sh | grep -q "PROJECT_DIR="; then
#   . env.sh
# else
#   . starter.sh env
# fi

if [ -d $TARGET_DIR ]; then
  echo
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

export LINE_OCI_STARTER_CREATION_DATE=`grep "export OCI_STARTER_CREATION_DATE" env.sh`
export LINE_OCI_STARTER_VERSION=`grep "export OCI_STARTER_VERSION" env.sh`

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

# Remove lines in env.sh
title "Removing unneeded lines in env.sh"
sed -i "/PROJECT_DIR=/d" env.sh
sed -i "/export BIN_DIR=/d" env.sh
sed -i "/# Get other env variables/d" env.sh 
sed -i '/. $BIN_DIR\/auto_env.sh/d' env.sh 

# Change the OCI_STARTER_CREATION_DATE / VERSION

title "Remove call to group_common_env.sh (now in auto_env.sh)"
sed -i '/..\/group_common_env.sh/d' env.sh  
sed -i '/elif [ -f $HOME\/.oci_starter_profile ]/c if [ -f $HOME/.oci_starter_profile ]; then'  env.sh  

title "Replacing OCI_STARTER versions with the downloaded version"
sed -i "/export OCI_STARTER_CREATION_DATE/c $LINE_OCI_STARTER_CREATION_DATE" env.sh
sed -i "/export OCI_STARTER_VERSION/c $LINE_OCI_STARTER_VERSION" env.sh

title "Replacing OCI_STARTER versions with the downloaded version"
sed -i 's/export TF_VAR_deploy_type="compute"/export TF_VAR_deploy_type="public_compute"/' env.sh

# Calls to env.sh
title "Replacing calls to env.sh"
function upgrade_calls_to_env_sh()
{
  FILE_NAME=$1
  FILE_PATH=`dirname -- "$FILE_NAME"`
  if [ -f $FILE_NAME ]; then
     echo "Replacing env.sh by starter.sh env in $FILE_NAME" 
     mkdir -p not_used/env/$FILE_PATH
     cp $FILE_NAME not_used/env/$FILE_PATH/.
     sed -i "s/env.sh/starter.sh env/" $FILE_NAME 
     diff not_used/env/$FILE_PATH $FILE_NAME  
  fi  
}

# Replace env.sh by starter.sh env  
for APP_DIR in `app_dir_list`; do
  upgrade_calls_to_env_sh src/$APP_DIR/build_app.sh
done
upgrade_calls_to_env_sh src/ui/build_ui.sh
upgrade_calls_to_env_sh src/after_done.sh

# Remove *.sh from src/terraform
rm src/terraform/*.sh

if [ -f ../build.sh ]; then
  echo "Adding build.sh and destroy.sh pointing to starter.sh"
  echo './starter.sh build $@' > build.sh
  echo './starter.sh destroy $@' > destroy.sh
  chmod 755 *.sh
fi

echo "Done. New version in directory upgrade"
echo 

read -p "Do you want to replace the current directory by the upgrade directory ? (yes/no) " yn
echo 
case $yn in 
	yes ) cd ..
          mkdir orig
          mv * orig
          mv orig/upgrade/* .
          echo "\norig" >> .gitignore
          echo "Next steps:"
          ;;
    no ) echo "Next steps:"
         echo "cd upgrade"
         ;;
esac
echo "./starter.sh build"




