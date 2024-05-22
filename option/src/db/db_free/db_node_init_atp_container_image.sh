sudo dnf install -y podman
podman run -d -p 1521:1521 -p 1522:1522 -p 8443:8443 -p 27017:27017 -e WORKLOAD_TYPE='ADW' -e WALLET_PASSWORD=${DB_PASSWORD} -e ADMIN_PASSWORD=${DB_PASSWORD} --cap-add SYS_ADMIN --device /dev/fuse --name adb-free --volume adb_container_volume:/u01/data container-registry.oracle.com/database/adb-free:latest-23ai
alias adb-cli="podman exec adb-free adb-cli"

sudo yum update
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum update
sudo yum -y install docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
sudo groupadd docker
sudo usermod -aG docker opc

docker run -d -p 1521:1522 -p 1522:1522 -p 8443:8443 -p 27017:27017 -e WORKLOAD_TYPE='ADW' -e WALLET_PASSWORD=${DB_PASSWORD} -e ADMIN_PASSWORD=${DB_PASSWORD} --cap-add SYS_ADMIN --device /dev/fuse --name adb-free --volume adb_container_volume:/u01/data container-registry.oracle.com/database/adb-free:latest-23ai
alias adb-cli="podman exec adb-free adb-cli"

# Open the Firewall
firewall-cmd --zone=public --add-port=1521/tcp --permanent
firewall-cmd --zone=public --add-port=1522/tcp --permanent
firewall-cmd --zone=public --add-port=8443/tcp --permanent
firewall-cmd --reload

cat >> /home/opc/.bash_profile << EOF
alias adb-cli="podman exec adb-free adb-cli"
EOF

# podman logs adb-free
# podman exec -it adb-free bash
# export ORACLE_HOME=/u01/app/oracle/product/23.0.0.0/dbhome_1
# export PATH=$ORACLE_HOME/bin:$PATH
# export TNS_ADMIN=/u01/app/oracle/wallets/tls_wallet
# sqlplus admin/$DB_PASSWORD@myatp_medium
# myatp_medium = (description=(retry_count=0)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=localhost))(connect_data=(service_name=myatp_medium.adb.oraclecloud.com))(security=(SSL_SERVER_DN_MATCH=TRUE)(SSL_SERVER_CERT_DN="CN=af44605599f8")))
# myatp_medium1 = (description=(retry_count=0)(retry_delay=3)(address=(protocol=tcp)(port=1521)(host=localhost))(connect_data=(service_name=myatp_medium.adb.oraclecloud.com))(security=(SSL_SERVER_DN_MATCH=TRUE)(SSL_SERVER_CERT_DN="CN=af44605599f8")))

# mkdir scratch
# podman cp adb-free:/u01/app/oracle/wallets/tls_wallet /scratch/tls_wallet
# export TNS_ADMIN=/scratch/tls_wallet


# -- Root container
# sqlplus sys/$DB_PASSWORD@//localhost:1521/free as sysdba
# -- Pluggable database
# sqlplus sys/$DB_PASSWORD@//localhost:1521/freepdb1 as sysdba
# /etc/init.d/oracle-free-23c stop
# /etc/init.d/oracle-free-23c start

# export ORACLE_SID=FREE 
# export ORAENV_ASK=NO 
# . /opt/oracle/product/23c/dbhomeFree/bin/oraenv

