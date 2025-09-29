# https://jira-sd.mc1.oracleiaas.com/browse/YUM-5781

mkdir -p /run/php-fpm

dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm -y
dnf module enable php:remi-8.4 -y
dnf module reset php -y
dnf module enable php:remi-8.4 -y
dnf update php\* -y
dnf install -y php php-cli php-common php-fpm php-pear gcc curl-devel php-devel zlib-devel pcre-devel php-pecl-http php-mysqlnd systemtap-sdt-devel
dnf install -y php84-php-oci8
# Not sure why I have to copy it
cp /opt/remi/php84/root/usr/lib64/php/modules/oci8.so /usr/lib64/php/modules/.
php -v
# export PHP_DTRACE=yes
# pecl install oci8
# echo "instantclient,$OCI_CLIENT_DIR" | pecl install oci8
php -i | grep oci8

# Enable in php.ini
echo >> /etc/php.ini
echo extension=oci8.so >> /etc/php.ini
echo extension=oci8 > /etc/php.d/20-oci8.ini


