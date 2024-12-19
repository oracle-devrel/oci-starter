#!/bin/bash
export PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $PROJECT_DIR

export TARGET_DIR=$PROJECT_DIR/target
DATE_POSTFIX=`date '+%Y%m%d-%H%M%S'`
LOG_NAME=$TARGET_DIR/log/destroy.${DATE_POSTFIX}.log

# Show the log and save it to target/build.log and target/log
ln -s $LOG_NAME $TARGET_DIR/destroy.log
bin/destroy_all.sh $@ 2>&1 | tee $LOG_NAME
# Return the exit code of destroy_all.sh
exit ${PIPESTATUS[0]}