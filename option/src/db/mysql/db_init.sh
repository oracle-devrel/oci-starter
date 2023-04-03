#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install mysql-shell
sudo dnf install -y mysql-shell

# Install the tables
mysqlsh $DB_USER@$DB_URL --password=$DB_PASSWORD --sql < mysql.sql