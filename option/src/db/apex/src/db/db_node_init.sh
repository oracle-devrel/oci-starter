#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

export DB_PASSWORD

# Install APEX and DBMS_CLOUD
sudo su - root -c "export DB_PASSWORD=$DB_PASSWORD; $SCRIPT_DIR/root_install_apex.sh"
sudo su - oracle -c "export DB_PASSWORD=$DB_PASSWORD; $SCRIPT_DIR/oracle_install_apex.sh"
