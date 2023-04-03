FROM oraclelinux:7-slim
WORKDIR /function
RUN groupadd --gid 1000 fn && adduser --uid 1000 --gid fn fn

RUN  yum -y install oracle-release-el7 oracle-golang-release-el7 && \
     yum -y install oracle-instantclient-release-el7 && \
     yum-config-manager --disable ol7_developer_EPEL && \
     yum -y install oracle-instantclient-basic oracle-instantclient-sqlplus gcc golang && \
     rm -rf /var/cache/yum
   
# Install the program
ADD . /function/
RUN go get .
RUN go build .
CMD ./func