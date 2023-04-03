FROM oraclelinux:7-slim

RUN  yum -y install oracle-release-el7 oracle-php-release-el7 && \
     yum -y install oracle-instantclient-release-el7 && \
     yum-config-manager --disable ol7_developer_EPEL && \
     yum -y install oracle-instantclient-basic oracle-instantclient-sqlplus && \
     yum install -y php php-json php-oci8-19c php-mysql && \
     rm -rf /var/cache/yum && \
     sed -i "s/Listen 80$/Listen 8080/" /etc/httpd/conf/httpd.conf 

WORKDIR /app
COPY src/html/* /var/www/html/
COPY src/php.ini.append.docker /app
RUN cat /app/php.ini.append.docker >> /etc/php.ini
COPY src/app.conf /etc/httpd/conf.d/
ENTRYPOINT ["httpd", "-D", "FOREGROUND"]
