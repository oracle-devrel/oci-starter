#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install last version of NodeJS
# https://yum.oracle.com/oracle-linux-nodejs.html#InstallingNodeOnOL8
sudo dnf module enable -y nodejs:18
sudo dnf module install -y nodejs

npm install

