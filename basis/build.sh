#!/bin/bash
export PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export TARGET_DIR=$PROJECT_DIR/target

cd $PROJECT_DIR
mkdir -p $TARGET_DIR/logs
export LOG_NAME=$TARGET_DIR/logs/build.${DATE_POSTFIX}.log

# Show the log and save it to target/build.log and target/logs
ln -sf $LOG_NAME $TARGET_DIR/build.log
bin/build_all.sh $@ 2>&1 | tee $LOG_NAME
# Return the exit code of build_all.sh
exit ${PIPESTATUS[0]}