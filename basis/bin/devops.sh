SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

if [ "$TF_VAR_auth_token" == "" ]; then
  echo "TF_VAR_auth_token not set"
  exit
fi

if test "$#" -ne 1; then
    echo
    echo "Syntax: ./devops.sh build or ./devops.sh destroy"
    exit
fi

echo "Action: $1"
read -p "Do you want to proceed? (yes/no) " yn
case $yn in 
	yes ) echo;; 
	no ) echo Exiting...;
		exit;;
	* ) echo Invalid response;
		exit 1;;
esac

cd $BIN_DIR/devops

if [ "$1" == "build" ]; then

  terraform init -no-color -upgrade
  terraform apply --auto-approve
  exit_on_error

  export STATE_FILE=$TARGET_DIR/devops.tfstate
  get_output_from_tfstate "DEVOPS_GIT_URL" "devops_git_url"

  # Clone the directory in the devops git repository
  GIT_TMP_DIR=/tmp/ocistarter_git
  rm -Rf $GIT_TMP_DIR
  mkdir $GIT_TMP_DIR
  cd $GIT_TMP_DIR
  git clone $DEVOPS_GIT_URL
  cd ${TF_VAR_prefix}
  cp -r $PROJECT_DIR/* .
  rm -Rf target
  cp bin/devops/build_devops.yaml .
  sed -i "s/terraform_local/resource_manager/" env.sh
  git config --local user.email "dummy@ocistarter.com"
  git config --local user.name "${TF_VAR_username}"
  git add .
  git commit -m "OCI Starter"
  git push origin main

elif [ "$1" == "destroy" ]; then

  terraform init -no-color -upgrade
  terraform destroy --auto-approve
  exit_on_error

fi
