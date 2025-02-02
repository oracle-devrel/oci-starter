# Run as root
# 
# Install MySQL on OL8
# Doc: https://docs.oracle.com/cd/E17952_01/mysql-8.0-en/linux-installation-yum-repo.html
wget https://repo.mysql.com//mysql80-community-release-el8-9.noarch.rpm
yum -y install mysql80-community-release-el8-9.noarch.rpm
yum repolist enabled | grep "mysql.*-community.*"
yum -y module disable mysql
dnf -y install mysql-community-server
systemctl start mysqld 

dnf -y install mysql-shell
export TMP_PASSWORD=`grep 'temporary password' /var/log/mysqld.log | sed 's/.*: //g'` 
mysqlsh root@localhost --password=$TMP_PASSWORD --sql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
EOF

# Open the Firewall
# firewall-cmd --zone=public --add-port=3306/tcp --permanent
# firewall-cmd --reload


