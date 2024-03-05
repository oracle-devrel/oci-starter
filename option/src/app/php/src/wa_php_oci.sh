# https://jira-sd.mc1.oracleiaas.com/browse/YUM-5781

# dnf install -y @php:7.4
# dnf install -y oraclelinux-developer-release-el8 oracle-instantclient-release-el8
# dnf module enable php:7.4 php-oci8
# dnf install -y php-oci8-21c php-mysqlnd 
# dnf install -y php-mysqlnd 
# dnf install -y httpd

if [[ `arch` == "aarch64" ]]; then
    dnf install -y oracle-release-el8
    dnf install -y oracle-instantclient19.19-basic oracle-instantclient19.19-devel
else
    dnf install -y oracle-instantclient-release-el8
    dnf install -y oracle-instantclient-basic oracle-instantclient-devel
fi
dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module enable -y php:remi-7.4
dnf module reset -y php
dnf module enable -y php:remi-7.4 -y
dnf install -y php php-cli php-common php-fpm php-pear gcc curl-devel php-devel zlib-devel pcre-devel php-pecl-http php-mysqlnd systemtap-sdt-devel --allowerasing
export PHP_DTRACE=yes
setenforce 0
if [[ `arch` == "aarch64" ]]; then
    echo "instantclient,/usr/lib/oracle/19.19/client64/lib" | pecl install oci8-2.2.0.tgz
else
    echo "instantclient,/usr/lib/oracle/21/client64/lib" | pecl install oci8-2.2.0.tgz
fi
echo >> /etc/php.ini
echo extension=oci8.so >> /etc/php.ini
echo extension=oci8 > /etc/php.d/20-oci8.ini

# Needed for docker to start the service at boot time
systemctl enable httpd
systemctl enable php-fpm

