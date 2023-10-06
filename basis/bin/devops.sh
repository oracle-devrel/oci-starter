SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

if [ "$TF_VAR_auth_token" == "" ]; then
  echo "TF_VAR_auth_token not set"
  exit
fi

export STATE_FILE=$TARGET_DIR/devops.tfstate
cd $BIN_DIR/devops

terraform init -no-color -upgrade
terraform apply 
exit_on_error

get_output_from_tfstate "DEVOPS_GIT_URL" "devops_git_url"

# Clone the directory in the devops git repository
GIT_TMP_DIR=/tmp/ocistarter_git
rm -Rf $GIT_TMP_DIR
mkdir $GIT_TMP_DIR
cd $GIT_TMP_DIR
git clone $DEVOPS_GIT_URL
cd ${PREFIX}-git
cp -r $PROJECT_DIR/* .
rm -Rf target
cp bin/devops/build_devops.yaml .
git config --local user.email "dummy@ocistarter.com"
git config --local user.name "${TF_VAR_username}"
git add .
git commit -m "OCI Starter"
git push origin main
