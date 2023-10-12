#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
. ../../env.sh -silent
. $BIN_DIR/shared_infra_as_code.sh
infra_as_code_plan $@
exit_on_error