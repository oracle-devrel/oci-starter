#!/bin/bash
. env.sh -silent
. $BIN_DIR/shared_infra_as_code.sh
cd $PROJECT_DIR/src/terraform
infra_as_code_apply $@
exit_on_error
