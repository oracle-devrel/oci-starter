#!/bin/bash
export PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -f $PROJECT_DIR/bin/oci-starter.sh ]; then
  export PATH=$PROJECT_DIR/bin:$PATH
fi  

(return 0 2>/dev/null) && SOURCED=1 || SOURCED=0
if [ "$SOURCED" == "1" ]; then
  . oci-starter.sh $@
  echo "RETURN"
else
  oci-starter.sh $@
  exit ${PIPESTATUS[0]}
fi

