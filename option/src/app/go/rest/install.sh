#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

install_instant_client

# Install last version of GoLang
# https://yum.oracle.com/oracle-linux-golang.html
sudo dnf install -y go
# sudo dnf install -y git gcc 

go get .
go build .

# sudo sh -c "echo /usr/lib/oracle/18.3/client64/lib > /etc/ld.so.conf.d/oracle-instantclient.conf" 
# sudo ldconfig
