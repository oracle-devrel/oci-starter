FROM oraclelinux:7-slim
WORKDIR /function
RUN groupadd --gid 1000 fn && adduser --uid 1000 --gid fn fn

RUN  yum-config-manager --disable ol7_developer_EPEL && \
     yum-config-manager --enable ol7_optional_latest && \
     yum -y install python3 oracle-release-el7 && \
     rm -rf /var/cache/yum
     
ADD . /function/
RUN pip3 install --upgrade pip
RUN pip3 install --no-cache --no-cache-dir -r requirements.txt
RUN rm -fr /function/.pip_cache ~/.cache/pip requirements.txt func.yaml Dockerfile README.md

ENTRYPOINT ["/usr/local/bin/fdk", "/function/func.py", "handler"]