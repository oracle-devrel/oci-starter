#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# https://yum.oracle.com/oracle-linux-python.html
sudo dnf install -y python3 python3-devel
sudo pip3 install -r requirements.txt
