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

source myenv/bin/activate
port_wait 8080 | tee rest.log
python rest.py 2>&1 | tee rest.log
