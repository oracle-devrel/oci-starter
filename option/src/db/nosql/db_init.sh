#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install oci-sdk
sudo dnf -y install oraclelinux-developer-release-el8
sudo dnf -y install python36-oci-cli

# oci nosql table create -c $TF_VAR_compartment_ocid --name dept --ddl-statement "CREATE TABLE dept(deptno LONG, dname STRING, loc STRING, PRIMARY KEY (SHARD(deptno)) ) USING TTL 1 DAYS"  --table-limits "{  \"maxReadUnits\": 50,  \"maxStorageInGBs\": 1,\"maxWriteUnits\": 1}"
oci nosql query execute --statement 'INSERT INTO dept (deptno, dname, loc) values (10, "ACCOUNTING", "BRUSSELS")'
oci nosql query execute --statement 'INSERT INTO dept (deptno, dname, loc) values (20, "RESEARCH", "NOSQL")'
oci nosql query execute --statement 'INSERT INTO dept (deptno, dname, loc) values (30, "SALES", "ROME")'
oci nosql query execute --statement 'INSERT INTO dept (deptno, dname, loc) values (40, "OPERATIONS", "MADRID")'
oci nosql query execute --statement 'SELECT * FROM dept'
