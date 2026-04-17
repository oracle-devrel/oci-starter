#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

. $HOME/compute/shared_compute.sh
install_instant_client
export TNS_ADMIN=$SCRIPT_DIR
sqlplus -L $DB_USER/$DB_PASSWORD@DB @oracle.sql $DB_PASSWORD
