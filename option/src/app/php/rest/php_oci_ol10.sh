# Use by PUBLIC_COMPUTE and DOCKER installation (K8s/Container Instance/Fn)
# https://jira-sd.mc1.oracleiaas.com/browse/YUM-5781
# To try:
# https://medium.com/oracledevs/oracle-database-and-php-oci8-3-4-1-is-now-available-in-both-pecl-and-pie-e29bb75e7220

install_instant_client

ORACLE_HOME=/usr/lib/oracle/26/client64

mkdir -p /run/php-fpm

dnf install -y \
    php \
    php-cli \
    php-common \
    php-devel \
    php-pear \
    php-mbstring \
    php-xml \
    php-json \
    php-process \
    php-mysqlnd \
    gcc \
    gcc-c++ \
    make \
    autoconf

pecl install oci8 <<EOF
instantclient,$ORACLE_HOME/lib
EOF

# dnf install -y php-fpm pcre-devel php-pecl-http php-mysqlnd systemtap-sdt-devel
php -v
php -i | grep oci8

# Enable in php.ini
echo >> /etc/php.ini
echo extension=oci8.so >> /etc/php.ini
echo extension=oci8 > /etc/php.d/20-oci8.ini

# Error Logs
ln -s /var/log/php-fpm/www-error.log .
ln -s /var/log/php-fpm/error.log .

# Enable Service
systemctl enable httpd
systemctl enable php-fpm
