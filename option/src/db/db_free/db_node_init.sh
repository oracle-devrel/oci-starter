# sudo dnf install -y podman
# podman run -d -p 1521:1522 -p 1522:1522 -p 8443:8443 -p 27017:27017 -e WORKLOAD_TYPE='ATP' -e WALLET_PASSWORD=LiveLab_123 -e ADMIN_PASSWORD=LiveLab_123 --cap-add SYS_ADMIN --device /dev/fuse --name adb-free --volume adb_container_volume:/u01/data container-registry.oracle.com/database/adb-free:latest-23ai
# alias adb-cli="podman exec adb-free adb-cli"

# Doc: https://docs.oracle.com/en/database/oracle/oracle-database/23/xeinl/installing-oracle-database-free.html
# Run as root
dnf install -y oraclelinux-developer-release-el8
dnf config-manager --set-enabled ol8_developer 
sudo dnf install -y oracle-database-preinstall-23ai
wget https://download.oracle.com/otn-pub/otn_software/db-free/oracle-database-free-23ai-1.0-1.el8.x86_64.rpm
# wget https://download.oracle.com/otn-pub/otn_software/db-free/oracle-database-free-23c-1.0-1.el8.x86_64.rpm
dnf -y localinstall oracle-database-free-23ai-1.0-1.el8.x86_64.rpm

# echo DB_PASSWORD=$DB_PASSWORD
(echo "${DB_PASSWORD}"; echo "${DB_PASSWORD}";) | /etc/init.d/oracle-free-23ai configure

ls -al /usr/local/bin
if [ "$TF_VAR_language" = "apex" ]; then
  # Install ORDS in silent mode
  dnf install -y graalvm22-ee-17-jdk
  dnf install -y ords
  cat > $HOME/password.txt << EOF
${DB_PASSWORD}
${DB_PASSWORD}
EOF
  # Does not work with 23ai
  # XXX
  /usr/local/bin/ords --config /etc/ords/config install --admin-user SYS --proxy-user --db-hostname localhost --db-port 1521 --db-servicename FREE --log-folder /etc/ords/logs --feature-sdw true --feature-db-api true --feature-rest-enabled-sql true --password-stdin < password.txt
  /etc/init.d/ords start
  firewall-cmd --zone=public --add-port=8080/tcp --permanent
else
  echo "TF_VAR_language=$TF_VAR_language. APEX not installed."
fi

# Open the Firewall
firewall-cmd --zone=public --add-port=1521/tcp --permanent
firewall-cmd --reload

cat >> /home/opc/.bash_profile << EOF

# Setup Oracle Free environment
export ORACLE_SID=FREE 
export ORAENV_ASK=NO 
. /opt/oracle/product/23ai/dbhomeFree/bin/oraenv
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

