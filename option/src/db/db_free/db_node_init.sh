# Doc: https://docs.oracle.com/en/database/oracle/oracle-database/23/xeinl/installing-oracle-database-free.html
# Run as root
dnf install -y oraclelinux-developer-release-el8
dnf config-manager --set-enabled ol8_developer 
sudo dnf install -y oracle-database-preinstall-23c
wget https://download.oracle.com/otn-pub/otn_software/db-free/oracle-database-free-23c-1.0-1.el8.x86_64.rpm
dnf -y localinstall oracle-database-free-23c-1.0-1.el8.x86_64.rpm

# echo DB_PASSWORD=$DB_PASSWORD
(echo "${DB_PASSWORD}"; echo "${DB_PASSWORD}";) | /etc/init.d/oracle-free-23c configure

# Install ORDS in silent mode
dnf install -y graalvm22-ee-11-jdk ords
cat >> $HOME/password.txt << EOF
${DB_PASSWORD}
${DB_PASSWORD}
EOF
ords --config /etc/ords/config install --admin-user SYS --proxy-user --db-hostname localhost --db-port 1521 --db-servicename FREE --log-folder /etc/ords/logs --feature-sdw true --feature-db-api true --feature-rest-enabled-sql true --password-stdin < password.txt
/etc/init.d/ords start

# Open the Firewall
firewall-cmd --zone=public --add-port=1521/tcp --permanent
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload


cat >> /home/opc/.bash_profile << EOF

# Setup Oracle Free environment
export ORACLE_SID=FREE 
export ORAENV_ASK=NO 
. /opt/oracle/product/23c/dbhomeFree/bin/oraenv
unset ORAENV_ASK
EOF

# -- Root container
# sqlplus sys/$DB_PASSWORD@//localhost:1521/free as sysdba
# -- Pluggable database
# sqlplus sys/$DB_PASSWORD@//localhost:1521/freepdb1 as sysdba
# /etc/init.d/oracle-free-23c stop
# /etc/init.d/oracle-free-23c start

# export ORACLE_SID=FREE 
# export ORAENV_ASK=NO 
# . /opt/oracle/product/23c/dbhomeFree/bin/oraenv

