#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install DB_FREE
sudo ./install_root.sh

# Install Table
. $HOME/compute/tf_env.sh
install_tnsname

export ORAENV_ASK=NO
export ORACLE_SID=FREE
. oraenv
sqlplus $DB_USER/$DB_PASSWORD@$DB_URL @oracle

