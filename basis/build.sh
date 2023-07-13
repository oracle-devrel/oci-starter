#!/bin/bash
export PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export TARGET_DIR=$PROJECT_DIR/target

cd $PROJECT_DIR
mkdir -p $TARGET_DIR

# Show the log and save it in target/build.log
bin/build_all.sh $@ 2>&1 | tee $TARGET_DIR/build.log
# Return the exit code of build_all.sh
exit ${PIPESTATUS[0]}