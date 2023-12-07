#!/bin/bash
export PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export TARGET_DIR=$PROJECT_DIR/target

cd $PROJECT_DIR
bin/destroy_all.sh $@ 2>&1 | tee $TARGET_DIR/destroy.log
# Return the exit code of destroy_all.sh
exit ${PIPESTATUS[0]}