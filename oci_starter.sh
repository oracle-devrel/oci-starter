#!/bin/bash
# OCI Starter
# 
# Script to create a directory or a zip file with the source code
# 
# Author: Marc Gueury
# Date: 2022-10-15
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

rm -rf ./output 
python3 py_oci_starter.py "$@"
