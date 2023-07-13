#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install SQLCL (Java program)
wget https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip
rm -Rf sqlcl
unzip sqlcl-latest.zip
sudo dnf install -y java-17 

# Create the script to install the APEX Application
cat > import_application.sql << EOF 
create user apex_app identified by "$DB_PASSWORD" default tablespace USERS quota unlimited on USERS temporary tablespace TEMP
/
grant resource to apex_app;
/
begin
    apex_instance_admin.add_workspace(
     p_workspace_id   => null,
     p_workspace      => 'APEX_APP',
     p_primary_schema => 'APEX_APP');
end;
/
begin
    apex_application_install.set_workspace('APEX_APP');
    apex_application_install.set_application_id(1001);
    apex_application_install.generate_offset();
    apex_application_install.set_schema('APEX_APP');
    apex_application_install.set_application_alias('APEX_APP');
    apex_application_install.set_auto_install_sup_obj( true );
end;
/
@apex_app.sql
quit
EOF

# Run SQLCl
# Install the tables
cat > tnsnames.ora <<EOT
DB  = $DB_URL
EOT

export TNS_ADMIN=$HOME/db
sqlcl/bin/sql $DB_USER/$DB_PASSWORD@DB @import_application.sql

