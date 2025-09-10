#!/usr/bin/env bash
# Build_app.sh
#
# Compute:
# - build the code 
# - create a $ROOT/target/compute/$APP_DIR directory with the compiled files
# - and a start.sh to start the program
# Docker:
# - build the image
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../../starter.sh env -no-auto
. $BIN_DIR/build_common.sh

curl -X PUT -H 'Authorization: Bearer access_token' -H "Accept:application/json" -F file=@myIntegration.iar -F type=application/octet-stream https://integration.us.oraclecloud.com/ic/api/integration/v1/integrations/archive

curl -H 'Authorization: Bearer xxxxxx'
 -H "Content-Type:application/json"
 -H "Accept: application/json"
 -X POST
 -d '{"commentStr":"add test Comment"}'
 https://example.com/ic/api/process/<version>/tasks/123456/comments
