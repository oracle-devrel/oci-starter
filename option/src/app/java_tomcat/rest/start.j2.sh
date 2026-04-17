#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/tf_env.sh

/opt/tomcat/bin/startup.sh
# curl http://localhost:8080/starter-1.0/info
# curl http://localhost:8080/starter-1.0/dept