#!/bin/bash
export DB_USER=##DB_USER##
export DB_PASSWORD=##DB_PASSWORD##
export JDBC_URL="##JDBC_URL##"

/opt/tomcat/bin/startup.sh
# curl http://localhost:8080/starter-1.0/info
# curl http://localhost:8080/starter-1.0/dept