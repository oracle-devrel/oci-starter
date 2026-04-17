#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
export PATH=~/.local/bin/:$PATH

. $HOME/compute/tf_env.sh

# Start LangGraph CompiledStateGraph on port 2024
source myenv/bin/activate
cd agent
langgraph dev --port 8080 --host 0.0.0.0 2>&1 | tee ../langgraph.log

