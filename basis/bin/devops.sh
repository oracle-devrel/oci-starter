SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

if "$TF_VAR_auth_token"=="" then
  echo "TF_VAR_auth_token not set"
  exit
fi

export STATE_FILE=$TARGET_DIR/devops.tfstate

cd $BIN_DIR/devops

terraform apply 

git config --local user.email "test@example.com"
git config --local user.name "${OCI_USERNAME}"
git add .
git commit -m "OCI Starter"
git push origin main