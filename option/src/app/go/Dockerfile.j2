FROM oraclelinux:8

RUN  dnf -y install oracle-release-el8 && \
{%- if db_family == "oracle" %}
  {%- if shape == "arm" %}
     dnf install -y oracle-release-el8
     dnf install -y oracle-instantclient19.19-basic oracle-instantclient19.19-devel     
  {%- else %}    
     dnf install -y oracle-instantclient-release-el8  
     dnf install -y oracle-instantclient-basic oracle-instantclient-sqlplus && \ 
  {%- endif %}    
{%- endif %}    
     dnf module enable go-toolset:ol8addon && \
     dnf module install -y go-toolset && \
     rm -rf /var/cache/yum

WORKDIR /app
COPY src/* /app/
RUN go get .
RUN go build .
CMD ./app
