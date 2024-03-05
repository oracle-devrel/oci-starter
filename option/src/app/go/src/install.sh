#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# ORACLE Instant Client 
if [[ "$JDBC_URL" == *"jdbc:oracle"* ]]; then
    if [[ `arch` == "aarch64" ]]; then
        sudo dnf install -y oracle-release-el8
        sudo dnf install -y oracle-instantclient19.19-basic oracle-instantclient19.19-devel
    else
        sudo dnf install -y oracle-instantclient-release-el8
        sudo dnf install -y oracle-instantclient-basic oracle-instantclient-devel
    fi
fi

# Install last version of GoLang
# https://yum.oracle.com/oracle-linux-golang.html
sudo dnf module enable go-toolset:ol8addon
sudo dnf module install -y go-toolset
# sudo dnf install -y git gcc 

go get .
go build .

# sudo sh -c "echo /usr/lib/oracle/18.3/client64/lib > /etc/ld.so.conf.d/oracle-instantclient.conf" 
# sudo ldconfig
