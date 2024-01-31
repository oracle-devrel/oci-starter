#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

{% import "start_sh.j2_macro" as m with context %}
{{ m.env() }}
python3.9 app.py 2>&1 | tee app.log
