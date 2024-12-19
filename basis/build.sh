#!/bin/bash
export PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export TARGET_DIR=$PROJECT_DIR/target

cd $PROJECT_DIR
mkdir -p $TARGET_DIR/log
export LOG_NAME=$TARGET_DIR/log/build.${DATE_POSTFIX}.log

# Show the log and save it to target/build.log and target/log
ln -s $LOG_NAME $TARGET_DIR/build.log
bin/build_all.sh $@ 2>&1 | tee $LOG_NAME
# Return the exit code of build_all.sh
exit ${PIPESTATUS[0]}