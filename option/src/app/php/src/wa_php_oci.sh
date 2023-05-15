# https://jira-sd.mc1.oracleiaas.com/browse/YUM-5781

dnf install -y oracle-instantclient-release-el8
dnf install -y oracle-instantclient-basic
dnf install -y oracle-instantclient-devel
dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module enable -y php:remi-7.4
dnf module reset -y php
dnf module enable -y php:remi-7.4 -y
dnf install -y php php-cli php-common php-fpm php-pear gcc curl-devel php-devel zlib-devel pcre-devel php-pecl-http php-mysqlnd systemtap-sdt-devel --allowerasing
export PHP_DTRACE=yes
setenforce 0
echo "instantclient,/usr/lib/oracle/21/client64/lib" | pecl install oci8-2.2.0.tgz
echo >> /etc/php.ini
echo extension=oci8.so >> /etc/php.ini
echo extension=oci8 > /etc/php.d/20-oci8.ini
systemctl restart php-fpm
systemctl restart httpd
