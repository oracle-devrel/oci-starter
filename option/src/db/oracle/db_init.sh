#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install SQL*Plus
sudo dnf install -y oracle-instantclient-release-el8
sudo dnf install -y oracle-instantclient-basic
sudo dnf install -y oracle-instantclient-sqlplus

# Install the tables
cat > tnsnames.ora <<EOT
DB  = $DB_URL
EOT

export TNS_ADMIN=$SCRIPT_DIR
sqlplus -L $DB_USER/$DB_PASSWORD@DB @oracle.sql
