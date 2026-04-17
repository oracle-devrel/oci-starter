#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
. $HOME/compute/tf_env.sh

source myenv/bin/activate
python rest.py 2>&1 | tee rest.log
