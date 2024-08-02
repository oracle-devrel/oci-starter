# TO RUN AS ROOT
if [ "$DB_PASSWORD" == "" ]; then
   echo "ERROR: DB_PASSWORD not set."
   exit
fi

export DB_SERVICE_NAME=`sudo su - oracle -c "lsnrctl status | grep pdb1. | sed -e 's/.* \"//; s/\" .*//'"`
echo DB_SERVICE_NAME=$DB_SERVICE_NAME

dnf install -y graalvm22-ee-17-jdk
dnf install -y ords
chown oracle /etc/ords 

cat > /tmp/password.txt << EOF
${DB_PASSWORD}
${DB_PASSWORD}
EOF
su - oracle -c "/usr/local/bin/ords --config /etc/ords/config install --admin-user SYS --proxy-user --db-hostname localhost --db-port 1521 --db-servicename $DB_SERVICE_NAME --log-folder /etc/ords/logs --feature-sdw true --feature-db-api true --feature-rest-enabled-sql true --password-stdin < /tmp/password.txt"
/etc/init.d/ords start
firewall-cmd --zone=public --add-port=8080/tcp --permanent  
