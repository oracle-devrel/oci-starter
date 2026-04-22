BUILD_COMMON_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
if [ -f $BUILD_COMMON_DIR/../starter.sh ]; then
    . $BUILD_COMMON_DIR/../starter.sh env -no-auto -silent
else 
    echo "ERROR: starter.sh not found"
    exit 1
fi

# Build_common.sh
#!/usr/bin/env bash
if [ "$BIN_DIR" == "" ]; then
    echo "Error: BIN_DIR not set"
    exit 1
fi
if [ "$PROJECT_DIR" == "" ]; then
    echo "Error: PROJECT_DIR not set"
    exit 1
fi

# Ex: src/app/rest     -> rest     -> rest 
# Ex: src/app/xxx/rest -> xxx/rest -> xxx-rest 
export APP_DIR="${SCRIPT_DIR#*/app/}"
export APP_NAME="${APP_DIR//\//-}"
cd $SCRIPT_DIR
title "Build App - $APP_NAME"

if [ "$TF_VAR_deploy_type" == "" ]; then
    . $PROJECT_DIR/starter.sh env
else 
    . $BIN_DIR/shared_bash_function.sh
fi 

if [ -f $PROJECT_DIR/before_build.sh ]; then
    . $PROJECT_DIR/before_build.sh
fi 
