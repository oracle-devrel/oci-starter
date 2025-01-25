#!/bin/bash
export PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -f $PROJECT_DIR/bin/oci-starter.sh ]; then
  export PATH=$PROJECT_DIR/bin:$PATH
fi  
. oci-starter.sh $@
exit ${PIPESTATUS[0]}