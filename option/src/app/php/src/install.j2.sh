#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

if [[ `arch` == "aarch64" ]]; then
    sudo dnf install -y oracle-release-el8
    sudo dnf install -y oracle-instantclient19.19-basic oracle-instantclient19.19-devel
    # OCI_CLIENT_DIR=/usr/lib/oracle/19.19/client64/lib
else
    sudo dnf install oracle-instantclient-release-23ai-el8 -y
    sudo dnf install -y oracle-instantclient-basic oracle-instantclient-devel
    # OCI_CLIENT_DIR=/usr/lib/oracle/23/client64/lib
fi

# Install last version of PHP
# https://yum.oracle.com/oracle-linux-php.html

# # XXX This should be the right way. But it does not work...
# # See https://docs.oracle.com/en-us/iaas/Content/developer/apache-on-oracle-linux/01-summary.htm
# sudo dnf install httpd -y
# sudo systemctl enable httpd
# sudo dnf install @php:7.4 -y
# php -v
# # See https://yum.oracle.com/oracle-linux-php.html#InstallPHPOCI8
# sudo dnf module enable php:7.4 php-oci8
# sudo dnf install -y php-oci8-21c php-mysqlnd 

# sudo dnf install @php:8.2 -y
# sudo dnf install -y oraclelinux-developer-release-el8 oracle-instantclient-release-el8
# sudo dnf module enable php:8.2 php-oci8
# sudo dnf install -y php-oci8-21c php-mysqlnd 
# sudo dnf install -y php-mysqlnd 
# sudo dnf install -y httpd

chmod +x wa_php_oci.sh
sudo ./wa_php_oci.sh

{%- if db_family == "psql" %}
sudo yum install -y php-pgsql
{%- endif %}

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

# Restart all
sudo systemctl enable httpd
sudo systemctl enable php-fpm
sudo systemctl restart httpd
sudo systemctl restart php-fpm

# Use Apache to PHP, and nginx to forward request to Apache
sudo rm /etc/nginx/default.d/php.conf



