#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../../env.sh -no-auto
. $OCI_STARTER_BIN_DIR/build_common.sh

build_function $JDBC_URL
