#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# From How To Setup And Use DBMS_CLOUD Package (Doc ID 2748362.1)
if [ "$DB_PASSWORD" == "" ]; then
   echo "ERROR: DB_PASSWORD not set."
   exit
fi

cd /u01/app/oracle
if [ -d apex ]; then
  echo "ERROR: apex directory detected"
  exit
fi

# Install APEX
export APEX_ZIP=apex_24.1_en.zip
# export APEX_ZIP=apex_latest.zip

echo "--- Downloading $APEX_ZIP"
wget -nv https://download.oracle.com/otn_software/apex/$APEX_ZIP
unzip $APEX_ZIP

echo "--- Add PDB1 to tnsnames.ora"
cat >> $ORACLE_HOME/network/admin/tnsnames.ora <<EOT

PDB1  = $DB_URL

EOT

echo "--- Running apexins.sql"
cd apex; 
sqlplus sys/$DB_PASSWORD@pdb1 as sysdba <<EOF
@apexins.sql SYSAUX SYSAUX TEMP /i/
exit
EOF

echo "--- Unlocking APEX_PUBLIC_USER"
sqlplus sys/$DB_PASSWORD@pdb1 as sysdba <<EOF
ALTER USER APEX_PUBLIC_USER ACCOUNT UNLOCK
/
ALTER USER APEX_PUBLIC_USER IDENTIFIED BY $DB_PASSWORD
/
EOF

echo "--- Resetting APEX password"
# WA to change the password (Issue because of the HIDE)
cp apxchpwd.sql apxchpwd.sql.orig
sed -i "s/ HIDE//" apxchpwd.sql

sqlplus sys/$DB_PASSWORD@pdb1 as sysdba <<EOF
@apxchpwd.sql
admin
spam@oracle.com
$DB_PASSWORD
exit
EOF

echo "--- Setting APEX image prefix"
cd utilities
sqlplus sys/$DB_PASSWORD@pdb1 as sysdba @reset_image_prefix.sql <<EOF

EOF

# Install DBMS_CLOUD
cd $SCRIPT_DIR
pwd

echo "--- Running dbms_cloud_install.sql"
mkdir $HOME/dbc
$ORACLE_HOME/perl/bin/perl $ORACLE_HOME/rdbms/admin/catcon.pl -u sys/$DB_PASSWORD --force_pdb_mode 'READ WRITE' -b dbms_cloud_install -d $HOME/dbc -l $HOME/dbc $SCRIPT_DIR/dbms_cloud_install.sql

echo "--- Check"
sqlplus / as sysdba <<EOF
select con_id, owner, object_name, status, sharing, oracle_maintained from cdb_objects where object_name = 'DBMS_CLOUD' order by con_id;
select owner, object_name, status, sharing, oracle_maintained from dba_objects where object_name = 'DBMS_CLOUD';
exit
EOF

echo "--- Importing certificates in Wallet"
export DB_CERT_DIR=$HOME/dbc_certs
export WALLET_DIR=$HOME/wallet

mkdir $DB_CERT_DIR
cd $DB_CERT_DIR
wget -nv https://objectstorage.us-phoenix-1.oraclecloud.com/p/QsLX1mx9A-vnjjohcC7TIK6aTDFXVKr0Uogc2DAN-Rd7j6AagsmMaQ3D3Ti4a9yU/n/adwcdemo/b/CERTS/o/dbc_certs.tar
tar xf dbc_certs.tar

mkdir -p $WALLET_DIR
cd $WALLET_DIR

orapki wallet create -wallet . -pwd $DB_PASSWORD -auto_login
#! /bin/bash
for i in $DB_CERT_DIR/*cer 
do
orapki wallet add -wallet . -trusted_cert -cert $i -pwd $DB_PASSWORD
done
orapki wallet display -wallet .
cd $ORACLE_HOME/network/admin

sed  '/SQLNET.EXPIRE_TIME=10/a WALLET_LOCATION=(SOURCE=(METHOD=FILE)(METHOD_DATA=(DIRECTORY=$WALLET_DIR)))' -i $ORACLE_HOME/network/admin/sqlnet.ora

cd $SCRIPT_DIR
pwd

echo "--- Running dcs_aces.sql"
sqlplus / as sysdba @dcs_aces.sql

echo "--- Running dcs_test.sql"
sqlplus / as sysdba @dcs_test.sql $DB_PASSWORD

