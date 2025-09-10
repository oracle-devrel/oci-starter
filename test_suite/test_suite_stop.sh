#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
export TEST_HOME=$SCRIPT_DIR/test_group_all

if [ "$1" == "stop_after_build" ]; then
  touch $TEST_HOME/stop_after_build
elif [ "$1" == "stop_all_after_destroy" ]; then
  touch $TEST_HOME/stop_all_after_destroy
else
  echo "ERROR: argument missing"
  echo "ex: ./test_suite_stop.sh stop_after_build"
  echo "    ./test_suite_stop.sh stop_all_after_destroy"
 fi 
