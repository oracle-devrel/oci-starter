#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

git --no-pager diff
git add .
DATE_POSTFIX=`date '+%Y%m%d-%H%M%S'`
git commit -m "Bastion Build $DATE_POSTFIX"
git push origin master
