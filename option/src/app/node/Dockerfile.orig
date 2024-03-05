FROM oraclelinux:7-slim

RUN  yum -y install oracle-release-el7 oracle-nodejs-release-el7 && \
     yum -y install oracle-instantclient-release-el7 && \
     yum-config-manager --disable ol7_developer_EPEL && \
     yum -y install oracle-instantclient-basic oracle-instantclient-sqlplus nodejs python3 && \
     rm -rf /var/cache/yum

WORKDIR /app
COPY src/* /app/
RUN npm install
CMD exec node rest.js