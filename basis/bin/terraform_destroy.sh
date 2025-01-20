#!/bin/bash
. env.sh -silent
. $BIN_DIR/shared_infra_as_code.sh
infra_as_code_destroy $@
exit_on_error
