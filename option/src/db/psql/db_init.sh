#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install PostgreSQL client
sudo yum -y install postgresql 
export PGPASSWORD=$DB_PASSWORD
psql -h $DB_URL -p 5432 -d db1 -U $DB_USER << psql.sql

