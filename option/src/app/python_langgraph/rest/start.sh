#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
export PATH=~/.local/bin/:$PATH

. $HOME/compute/tf_env.sh
export MCP_SERVER_URL="http://localhost:2025/mcp"

# Start LangGraph CompiledStateGraph on port 2024
source myenv/bin/activate
cd agent
PORT="8080"
HOST="0.0.0.0"

port_owner() {
    if command -v lsof >/dev/null 2>&1; then
        lsof -nP -iTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true
    elif command -v ss >/dev/null 2>&1; then
        ss -ltnp "sport = :$PORT" 2>/dev/null || true
    fi
}

for attempt in {1..10}; do
    PORT_OWNER=$(port_owner)
    if [ -z "$PORT_OWNER" ]; then
        break
    fi

    {
        echo "Port $PORT is already in use. Waiting 5 seconds before starting LangGraph (attempt $attempt/10)."
        echo "$PORT_OWNER"
    } | tee -a ../rest.log

    sleep 5
done

PORT_OWNER=$(port_owner)
if [ -n "$PORT_OWNER" ]; then
    echo "ERROR: Port $PORT is still in use after 10 attempts." | tee -a ../rest.log
    echo "$PORT_OWNER" | tee -a ../rest.log
    exit 1
fi

export LOG_COLOR=false
langgraph dev --no-reload --port "$PORT" --host "$HOST" 2>&1 | tee ../rest.log
