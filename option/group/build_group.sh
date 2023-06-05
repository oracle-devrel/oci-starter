#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

cd group_common
./build.sh
cd $SCRIPT_DIR

echo "-- Loop in alphabetical order --"
for d in `ls -d */ | sort -g`; do
    if [ "$d" != "group_common/" ]; then
      echo "-- BUILD_ALL - $d ---------------------------------"

      cd $d
      ./build.sh
      cd $SCRIPT_DIR
    fi
done
