FROM oraclelinux:7-slim

RUN  yum -y install oracle-release-el7 oracle-golang-release-el7 && \
     yum -y install oracle-instantclient-release-el7 && \
     yum-config-manager --disable ol7_developer_EPEL && \
     yum -y install oracle-instantclient-basic oracle-instantclient-sqlplus gcc golang && \
     rm -rf /var/cache/yum

WORKDIR /app
COPY src/* /app/
RUN go get .
RUN go build .
CMD ./app
