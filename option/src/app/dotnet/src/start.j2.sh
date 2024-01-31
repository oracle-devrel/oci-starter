#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

{% import "start_sh.j2_macro" as m with context %}
{{ m.env() }}

export PATH=$HOME/.dotnet:$PATH
dotnet run 2>&1 | tee app.log
