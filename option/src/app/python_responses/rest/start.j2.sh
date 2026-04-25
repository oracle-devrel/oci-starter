#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
export PATH=~/.local/bin/:$PATH

. $HOME/compute/tf_env.sh

{%- if deploy_type == "public_compute" %}
export MCP_SERVER_URL="http://$BASTION_IP/mcp_server/mcp"
{%- else %}
export MCP_SERVER_URL="https://$APIGW_HOSTNAME/$TF_VAR_prefix/mcp_server/mcp"
{%- endif %}

# Default port is 2025
source myenv/bin/activate
python responses.py 2>&1 | tee rest.log
