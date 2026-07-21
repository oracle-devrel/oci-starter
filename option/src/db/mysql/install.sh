#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
. $HOME/compute/shared_compute.sh

# Install mysql-shell
sudo dnf install https://repo.mysql.com/mysql84-community-release-el10.rpm
sudo dnf install -y mysql-shell

# Install the tables
mysqlsh $DB_USER@$DB_URL --password=$DB_PASSWORD --sql < mysql.sql