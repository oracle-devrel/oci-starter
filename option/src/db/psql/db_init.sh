#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install PostgreSQL client
sudo yum -y install postgresql 
export PGPASSWORD=$DB_PASSWORD
psql -h $DB_URL -d postgres -U $DB_USER -f psql.sql

