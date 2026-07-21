# Run as root
# 
# Install MySQL on OL8
# Doc: https://docs.oracle.com/cd/E17952_01/mysql-8.0-en/linux-installation-yum-repo.html
#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

. /home/opc/compute/tf_env.sh

# wget https://repo.mysql.com//mysql80-community-release-el8-9.noarch.rpm
# yum -y install mysql80-community-release-el8-9.noarch.rpm
# yum repolist enabled | grep "mysql.*-community.*"
# yum -y module disable mysql
tee /etc/yum.repos.d/mysql97-community.repo > /dev/null <<'EOF'
[ol10_mysql97_community]
name=Oracle Linux 10 MySQL 9.7 Community
baseurl=https://yum.oracle.com/repo/OracleLinux/OL10/MySQL97/community/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://yum.oracle.com/RPM-GPG-KEY-oracle-ol10
EOF

tee /etc/yum.repos.d/mysql97-community.repo > /dev/null <<'EOF'
[ol10_mysql97_tools_community]
name=Oracle Linux 10 MySQL 9.7 Tools Community
baseurl=https://yum.oracle.com/repo/OracleLinux/OL10/MySQL97/tools/community/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://yum.oracle.com/RPM-GPG-KEY-oracle-ol10
EOF

dnf clean all
dnf makecache

sudo dnf install -y mysql-community-server
systemctl start mysqld 

dnf -y install mysql-shell

export TMP_PASSWORD=`grep 'temporary password' /var/log/mysqld.log | sed 's/.*: //g'` 
mysqlsh root@localhost --password=$TMP_PASSWORD --sql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
EOF

# Open the Firewall
# firewall-cmd --zone=public --add-port=3306/tcp --permanent
# firewall-cmd --reload

# Install the tables
mysqlsh $DB_USER@$DB_URL --password=$DB_PASSWORD --sql < mysql.sql