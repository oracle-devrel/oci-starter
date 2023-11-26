# Run as root
wget https://repo.mysql.com//mysql80-community-release-el8-5.noarch.rpm
yum -y install mysql80-community-release-el8-5.noarch.rpm
yum repolist enabled | grep "mysql.*-community.*"
yum -y module disable mysql
dnf -y install mysql-community-server mysql-shell
id mysql
systemctl start mysqld 

export TMP_PASSWORD=`grep 'temporary password' /var/log/mysqld.log | sed 's/.*: //g'` 
mysqlsh $DB_USER@$DB_URL --password=$TMP_PASSWORD --sql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
EOF

# Open the Firewall
# firewall-cmd --zone=public --add-port=3306/tcp --permanent
# firewall-cmd --reload


