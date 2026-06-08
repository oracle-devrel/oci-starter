from langchain_openai import ChatOpenAI
from langchain_oci import ChatOCIGenAI
from langgraph.prebuilt import create_react_agent
from langgraph.graph import StateGraph
from langchain_mcp_adapters.client import MultiServerMCPClient
from langchain_mcp_adapters.interceptors import MCPToolCallRequest
import asyncio
import os
import time
import pprint
import httpx
import oci_openai 
from typing import Any

COMPARTMENT_OCID = os.getenv("TF_VAR_compartment_ocid")
REGION = os.getenv("TF_VAR_region")
MCP_SERVER_URL = os.getenv("MCP_SERVER_URL") or "http://localhost:2025/mcp"
if REGION == "eu-amsterdam-1":
    REGION = "eu-frankfurt-1"
AUTH_TYPE = os.getenv("AUTH_TYPE") or "INSTANCE_PRINCIPAL"

# auth = oci_openai.OciInstancePrincipalAuth()
# llm = ChatOpenAI(
#     model="xai.grok-4-fast-reasoning",
#     api_key="OCI",
#     base_url="https://inference.generativeai.us-chicago-1.oci.oraclecloud.com/20231130/actions/v1",
#     http_client=httpx.Client(
#         auth=auth,
#         headers={"CompartmentId": COMPARTMENT_OCID}
#     ),
# )

llm = ChatOCIGenAI(
    auth_type="API_KEY" if "LIVELABS" in os.environ else AUTH_TYPE,
    model_id="openai.gpt-oss-120b",
    # model_id="meta.llama-4-scout-17b-16e-instruct",
    # model_id="cohere.command-a-03-2025",
    service_endpoint="https://inference.generativeai."+REGION+".oci.oraclecloud.com",
    # model_id="xai.grok-4.3",
    # service_endpoint="https://inference.generativeai.us-chicago-1.oci.oraclecloud.com",
    compartment_id=COMPARTMENT_OCID,
    is_stream=False,
    model_kwargs={"temperature": 0}
)

def remove_empty_parameter_names(args: dict[str, Any] | None) -> dict[str, Any]:
    """Remove tool arguments whose parameter name is empty or only whitespace."""
    if not args:
        return {}

    return {
        key: value
        for key, value in args.items()
        if isinstance(key, str) and key.strip()
    }

# See https://docs.langchain.com/oss/python/langchain/mcp#accessing-runtime-context
async def inject_user_context(
    request: MCPToolCallRequest,
    handler,
):
    """Inject user credentials into MCP tool calls and keep agent runs alive on tool errors."""
    print( "--- request ----" )
    pprint.pprint( request )
    runtime = request.runtime
    user_id = runtime.config["configurable"]["user_id"]
    auth_user = runtime.config["configurable"]["langgraph_auth_user"]
    auth_header = auth_user.dict().get("auth_header")
    print( f"<inject_user_context> user_id={user_id}", flush=True )
    # print( f"<inject_user_context> auth_header={auth_header}", flush=True )
    # modified_request = request.override( headers = { "Authorization": f"User {user_id}" } )
    cleaned_args = remove_empty_parameter_names(request.args)
    modified_request = request.override(
        args=cleaned_args,
        headers={ "Authorization": auth_header },
    )
    try:
        return await handler(modified_request)
    except Exception as first_error:
        message = str(first_error)
        print(f"<inject_user_context> tool call failed: {message}", flush=True)

        # Retry once only for likely transient errors.
        transient_markers = ["timeout", "temporar", "connection reset", "503", "502", "429"]
        if any(marker in message.lower() for marker in transient_markers):
            print("<inject_user_context> retrying transient tool error once", flush=True)
            await asyncio.sleep(0.5)
            try:
                return await handler(modified_request)
            except Exception as second_error:
                message = str(second_error)
                print(f"<inject_user_context> retry failed: {message}", flush=True)

        # For validation/format errors, return structured payload instead of raising,
        # so the agent can reason on the error and try a corrected tool call.
        return {
            "status": "tool_error",
            "retryable_by_agent": True,
            "error": message,
            "guidance": "Tool call failed. Adjust parameters based on this error and retry with corrected values.",
        }

async def init( agent_name, prompt, tools_list, callback_handler=None ) -> StateGraph:

    # Waiting is important, since after reboot the MCP server could start afterwards.
    delay = 10
    for attempt in range(1, 30):
        try:
            print(f"Connecting to MCP {attempt}...")
            client = MultiServerMCPClient(
                {
                    "McpServer": {
                        "transport": "streamable_http",
                        "url": MCP_SERVER_URL,                     
                    },
                },
                tool_interceptors=[inject_user_context],
            )
            tools = await client.get_tools()
            print( "-- tools ------------------------------------------------------------")
            pprint.pprint( tools )
            # Filter tools.
            tools_filtered = []
            for tool in tools:
                if tools_list==None or tool.name in tools_list:
                    tools_filtered.append( tool )
            print( "-- tools_filtered ---------------------------------------------------")
            pprint.pprint( tools_filtered )
            break
        except Exception as e:
            print(f"Connection failed {attempt}: {e}")            
            print(f"Waiting for {delay} seconds before the next attempt...")
            time.sleep(delay)

    if client==None:
        print("ERROR: connection to MCP Failed")
        exit(1)

    agent = create_react_agent(
        model=llm,
        tools=tools_filtered,
        prompt=prompt,
        name=agent_name
    ) 
    return agent    
prompt = """You are an agent that use the tools you got access to.

INSTRUCTIONS:
- Assist ONLY with research-related tasks, DO NOT do any math.
- When using a MCP tool, take care not to  pass empty parameters name like "", or {"":{}}
- To draw a diagram, use mermaid   
- If not, use MarkDown to give a clear and short answer to the user.
"""

agent = asyncio.run(init("agent", prompt, None))
