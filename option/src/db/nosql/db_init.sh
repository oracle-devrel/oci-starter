#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install oci-sdk
sudo dnf -y install oraclelinux-developer-release-el8
sudo dnf -y install python36-oci-cli

# OCI CLI config file
mkdir $HOME/.oci
touch $HOME/.oci/config 
oci setup repair-file-permissions --file $HOME/.oci/config 

export TF_VAR_compartment_ocid=`curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r .compartmentId`
export TF_VAR_region=`curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r .region`
export OCI_CLI_AUTH=instance_principal
# oci nosql table create -c $TF_VAR_compartment_ocid --name dept --ddl-statement "CREATE TABLE dept(deptno LONG, dname STRING, loc STRING, PRIMARY KEY (SHARD(deptno)) ) USING TTL 1 DAYS"  --table-limits "{  \"maxReadUnits\": 50,  \"maxStorageInGBs\": 1,\"maxWriteUnits\": 1}"
oci nosql query execute -c $TF_VAR_compartment_ocid --statement 'INSERT INTO dept (deptno, dname, loc) values (10, "ACCOUNTING", "BRUSSELS")' --auth instance_principal
oci nosql query execute -c $TF_VAR_compartment_ocid --statement 'INSERT INTO dept (deptno, dname, loc) values (20, "RESEARCH", "NOSQL")'
oci nosql query execute -c $TF_VAR_compartment_ocid --statement 'INSERT INTO dept (deptno, dname, loc) values (30, "SALES", "ROME")'
oci nosql query execute -c $TF_VAR_compartment_ocid --statement 'INSERT INTO dept (deptno, dname, loc) values (40, "OPERATIONS", "MADRID")'
oci nosql query execute -c $TF_VAR_compartment_ocid --statement 'SELECT * FROM dept'
