XXXXX
# Kubernetes
if [ "$TF_VAR_deploy_type" == "kubernetes" ]; then
    append_tf_env "export LANGGRAPH_URL=\"http://langgraph-service:2024\""
    append_tf_env "export MCP_SERVER_URL=\"http://mcp-server-service:2025/mcp\""
else 
    append_tf_env "export LANGGRAPH_URL=\"http://127.0.0.1:2024\""
    append_tf_env "export MCP_SERVER_URL=\"http://localhost:2025/mcp\""
fi