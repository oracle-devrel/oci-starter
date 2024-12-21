#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

if [ -z "$1" ]; then
  echo "Usage: test_errors_only.sh <FULL_DIRECTORY_PATH>"
  exit
fi

export TEST_ERRORS_ONLY=$1
./test_suite.sh
