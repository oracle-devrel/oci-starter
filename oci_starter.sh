#!/usr/bin/env bash
# OCI Starter
# 
# Script to create a directory or a zip file with the source code
# 
# Author: Marc Gueury
# Date: 2022-10-15
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

rm -rf ./output 
# python py_oci_starter.py "$@"
scl enable rh-python38 -- python py_oci_starter.py "$@"

exit $RESULT