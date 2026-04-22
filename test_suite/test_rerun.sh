#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

if [ "$#" -lt 1 ]; then
    echo "Usage: test_rerun.sh <FULL_DIRECTORY_PATH>" 
    exit 1
fi

echo "Mode"
echo "[1] ./test_rerun.sh <path> destroy_refresh_build_destroy"
echo "[2] ./test_rerun.sh <path> destroy_refresh_build"
echo "[3] ./test_rerun.sh <path> refresh"
read -p "Enter choice [1/4]:  " MODE_ID
if [ "$MODE_ID" == "1" ]; then
    echo "-"
elif [ "$MODE_ID" == "2" ]; then
    export TEST_RERUN_NO_DESTROY=TRUE
elif [ "$MODE_ID" == "3" ]; then
    export TEST_RERUN_REFRESH=TRUE
else
    echo "ERROR: Unknown choice"
    exit 1
fi

export TEST_DIRECTORY_ONLY=$1
./test_suite.sh
