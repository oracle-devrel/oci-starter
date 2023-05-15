#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install last version of PHP
# https://yum.oracle.com/oracle-linux-php.html

sudo dnf install -y oraclelinux-developer-release-el8 oracle-instantclient-release-el8
chmod +x wa_php_oci.sh
sudo ./wa_php_oci.sh

# sudo dnf install -y @php:7.4
# sudo dnf install -y oraclelinux-developer-release-el8 oracle-instantclient-release-el8
# sudo dnf module enable php:7.4 php-oci8
# sudo dnf install -y php-oci8-21c php-mysqlnd 
# sudo dnf install -y php-mysqlnd 
# sudo dnf install -y httpd

if grep -q '##DB_URL##' php.ini.append; then
  sed -i "s!##DB_URL##!$DB_URL!" php.ini.append 
  sudo sh -c "cat php.ini.append >> /etc/php.ini"
else
  echo "DB_URL is already in php.ini.append"
fi

# PHP use apache 
sudo cp html/* /var/www/html/.
sudo cp app.conf /etc/httpd/conf.d/.

# Configure the Apache Listener on 8080
sudo sed -i "s/Listen 80$/Listen 8080/" /etc/httpd/conf/httpd.conf
sudo systemctl restart httpd
sudo systemctl restart php-fpm

# XXXX
sudo rm /etc/nginx/default.d/php.conf



