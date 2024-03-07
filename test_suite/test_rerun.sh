#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
export TEST_HOME=$SCRIPT_DIR/test_group_all
. $SCRIPT_DIR/test_suite_shared.sh
export BUILD_COUNT=1

if [ -z "$1" ]; then
  echo "Usage: test_rerun.sh <FULL_DIRECTORY_PATH>"
  exit
fi

export TEST_DIR=$1
export TEST_NAME=`basename $TEST_DIR`
cd $TEST_DIR               
build_test_destroy

