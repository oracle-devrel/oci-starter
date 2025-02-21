# sudo dnf install -y podman
# podman run -d -p 1521:1522 -p 1522:1522 -p 8443:8443 -p 27017:27017 -e WORKLOAD_TYPE='ATP' -e WALLET_PASSWORD=LiveLab_123 -e ADMIN_PASSWORD=LiveLab_123 --cap-add SYS_ADMIN --device /dev/fuse --name adb-free --volume adb_container_volume:/u01/data container-registry.oracle.com/database/adb-free:latest-23ai
# alias adb-cli="podman exec adb-free adb-cli"

# Doc: https://docs.oracle.com/en/database/oracle/oracle-database/23/xeinl/installing-oracle-database-free.html
# Run as root
if [ `arch` != "aarch64" ]; then
  FREEDB_RPM=oracle-database-free-23ai-1.0-1.el8.x86_64.rpm
else
  FREEDB_RPM=oracle-database-free-23ai-1.0-1.el8.aarch64.rpm
fi

if [ -f ${FREEDB_RPM} ]; then
  echo "SKIPPING DB INSTALL - File ${FREEDB_RPM} already downloaded"
  exit
fi 

dnf install -y oraclelinux-developer-release-el8
dnf config-manager --set-enabled ol8_developer 
sudo dnf install -y oracle-database-preinstall-23ai

wget -nv https://download.oracle.com/otn-pub/otn_software/db-free/${FREEDB_RPM} 
dnf -y localinstall ${FREEDB_RPM} 

# echo DB_PASSWORD=$DB_PASSWORD
(echo "${DB_PASSWORD}"; echo "${DB_PASSWORD}";) | /etc/init.d/oracle-free-23ai configure

cat >> /home/oracle/.bash_profile << EOF

# Setup Oracle Free environment
export ORACLE_SID=FREE 
export ORAENV_ASK=NO 
. /opt/oracle/product/23ai/dbhomeFree/bin/oraenv
unset ORAENV_ASK
EOF

ls -al /usr/local/bin
if [ "$TF_VAR_language" = "apex" ]; then
  # Install ORDS in silent mode
  dnf install -y java-17
  dnf install -y ords
  chown oracle /etc/ords 
  cat > /tmp/password.txt << EOF
${DB_PASSWORD}
${DB_PASSWORD}
EOF

  su - oracle -c "/usr/local/bin/ords --config /etc/ords/config install --admin-user SYS --proxy-user --db-hostname localhost --db-port 1521 --db-servicename FREE --log-folder /etc/ords/logs --feature-sdw true --feature-db-api true --feature-rest-enabled-sql true --password-stdin < /tmp/password.txt"
  /etc/init.d/ords start
  firewall-cmd --zone=public --add-port=8080/tcp --permanent

  # Install APEX
  cd /tmp

  export APEX_ZIP=apex_24.1_en.zip
  su - oracle -c "wget https://download.oracle.com/otn_software/apex/$APEX_ZIP"
  su - oracle -c "unzip $APEX_ZIP"
  su - oracle -c "cd apex; sqlplus '/ as sysdba' <<EOF
@apexins.sql SYSAUX SYSAUX TEMP /i/
exit
EOF"
else
  echo "TF_VAR_language=$TF_VAR_language. APEX not installed."
fi

# Open the Firewall
firewall-cmd --zone=public --add-port=1521/tcp --permanent
firewall-cmd --reload

# -- Root container
# sqlplus sys/$DB_PASSWORD@//localhost:1521/free as sysdba
# -- Pluggable database
# sqlplus sys/$DB_PASSWORD@//localhost:1521/freepdb1 as sysdba
# /etc/init.d/oracle-free-23c stop
# /etc/init.d/oracle-free-23c start

# export ORACLE_SID=FREE 
# export ORAENV_ASK=NO 
# . /opt/oracle/product/23c/dbhomeFree/bin/oraenv

