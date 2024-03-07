#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

cd group_common
. bin/shared_bash_function.sh
./starter.sh build
exit_on_error
cd $SCRIPT_DIR

for d in `ls -d */ | sort -g`; do
    if [ "$d" != "group_common/" ]; then
      echo "-- BUILD_ALL - $d ---------------------------------"

      cd $d
      ./starter.sh build
      exit_on_error
      cd $SCRIPT_DIR
    fi
done
