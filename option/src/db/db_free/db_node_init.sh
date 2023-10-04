# Doc: https://docs.oracle.com/en/database/oracle/oracle-database/23/xeinl/installing-oracle-database-free.html
# Run as root
dnf install -y oraclelinux-developer-release-el8
dnf config-manager --set-enabled ol8_developer 
sudo dnf install -y oracle-database-preinstall-23c
wget https://download.oracle.com/otn-pub/otn_software/db-free/oracle-database-free-23c-1.0-1.el8.x86_64.rpm
dnf -y localinstall oracle-database-free-23c-1.0-1.el8.x86_64.rpm

echo DB_PASSWORD=$DB_PASSWORD
(echo "${DB_PASSWORD}"; echo "${DB_PASSWORD}";) | /etc/init.d/oracle-free-23c configure

cat >> $HOME/.bash_profile << EOF

# Setup Oracle Free environment
export ORACLE_SID=FREE 
export ORAENV_ASK=NO 
. /opt/oracle/product/23c/dbhomeFree/bin/oraenv
unset ORAENV_ASK

EOF

# -- Root container
# sqlplus sys/SysPassword1@//localhost:1521/free as sysdba
# -- Pluggable database
# sqlplus sys/SysPassword1@//localhost:1521/freepdb1 as sysdba
# /etc/init.d/oracle-free-23c stop
# /etc/init.d/oracle-free-23c start

# export ORACLE_SID=FREE 
# export ORAENV_ASK=NO 
# . /opt/oracle/product/23c/dbhomeFree/bin/oraenv

