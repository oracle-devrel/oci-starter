#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install last version of NodeJS
# https://yum.oracle.com/oracle-linux-nodejs.html#InstallingNodeOnOL8
sudo dnf module install -y nodejs

# ORACLE Instant Client
# https://docs.oracle.com/en/database/oracle/oracle-database/21/lacli/install-instant-client-using-rpm.html
sudo dnf install -y oracle-instantclient-release-el8
sudo dnf install -y oracle-instantclient-basic
sudo dnf install -y oracle-instantclient-sqlplus

npm install

