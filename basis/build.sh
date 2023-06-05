#!/bin/bash
export ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $ROOT_DIR

export TARGET_DIR=$ROOT_DIR/target
if [ ! -d $TARGET_DIR ]; then
  mkdir $TARGET_DIR
fi

bin/build_all.sh $@ 2>&1 | tee $TARGET_DIR/build.log
