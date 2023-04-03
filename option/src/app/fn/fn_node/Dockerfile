FROM oraclelinux:7-slim
WORKDIR /function
RUN groupadd --gid 1000 fn && adduser --uid 1000 --gid fn fn

RUN  yum -y install oracle-release-el7 oracle-nodejs-release-el7 && \
     yum -y install oracle-instantclient-release-el7 && \
     yum-config-manager --disable ol7_developer_EPEL && \
     yum -y install oracle-instantclient-basic oracle-instantclient-sqlplus nodejs&& \
     rm -rf /var/cache/yum
    
# Install the Node program
ADD . /function/
RUN npm install
RUN rm -fr /function/.pip_cache ~/.cache/pip func.yaml Dockerfile README.md

ENTRYPOINT ["node", "func.js"]
