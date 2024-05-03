sudo dnf install -y podman
podman run -d -p 1521:1522 -p 1522:1522 -p 8443:8443 -p 27017:27017 -e WORKLOAD_TYPE='ATP' -e WALLET_PASSWORD=LiveLab_123 -e ADMIN_PASSWORD=LiveLab_123 --cap-add SYS_ADMIN --device /dev/fuse --name adb-free --volume adb_container_volume:/u01/data container-registry.oracle.com/database/adb-free:latest-23ai
alias adb-cli="podman exec adb-free adb-cli"

# Open the Firewall
firewall-cmd --zone=public --add-port=1521/tcp --permanent
firewall-cmd --reload

cat >> /home/opc/.bash_profile << EOF
alias adb-cli="podman exec adb-free adb-cli"
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

