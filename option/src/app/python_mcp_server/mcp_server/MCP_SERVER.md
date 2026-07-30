Useful commands
----------------
export MCP_SERVER_URL=http://localhost:2025/mcp/

---

curl -i http://localhost:2025/health

---

curl -i \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -X POST \
  $MCP_SERVER_URL \
  -d '{
    "jsonrpc":"2.0",
    "id":2,
    "method":"tools/list",
    "params":{}
  }'

----

curl -i \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -X POST \
  $MCP_SERVER_URL \
  -d '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"initialize",
    "params":{
      "protocolVersion":"2025-03-26",
      "capabilities":{},
      "clientInfo":{
        "name":"curl",
        "version":"1.0"
      }
    }
  }'

----
