#!/bin/bash
export ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export TARGET_DIR=$ROOT_DIR/target

cd $ROOT_DIR
bin/destroy_all.sh $@ 2>&1 | tee $TARGET_DIR/destroy.log
