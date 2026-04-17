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

COMPARTMENT_OCID = os.getenv("TF_VAR_compartment_ocid")
REGION = os.getenv("TF_VAR_region")
MCP_SERVER_URL = os.getenv("MCP_SERVER_URL") or "http://localhost:2025/mcp"

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
    auth_type="API_KEY" if "LIVELABS" in os.environ else "INSTANCE_PRINCIPAL",
    model_id="openai.gpt-oss-120b",
    # model_id="meta.llama-4-scout-17b-16e-instruct",
    # model_id="cohere.command-a-03-2025",
    service_endpoint="https://inference.generativeai."+REGION+".oci.oraclecloud.com",
    # model_id="xai.grok-4-fast-reasoning",
    # service_endpoint="https://inference.generativeai.us-chicago-1.oci.oraclecloud.com",
    compartment_id=COMPARTMENT_OCID,
    is_stream=True,
    model_kwargs={"temperature": 0}
)

# See https://docs.langchain.com/oss/python/langchain/mcp#accessing-runtime-context
async def inject_user_context(
    request: MCPToolCallRequest,
    handler,
):
    """Inject user credentials into MCP tool calls."""
    print( "--- request ----" )
    pprint.pprint( request )
    runtime = request.runtime
    user_id = runtime.config["configurable"]["user_id"]
    auth_user = runtime.config["configurable"]["langgraph_auth_user"]
    auth_header = auth_user.dict().get("auth_header")
    print( f"<inject_user_context> user_id={user_id}", flush=True )
    # print( f"<inject_user_context> auth_header={auth_header}", flush=True )
    # modified_request = request.override( headers = { "Authorization": f"User {user_id}" } )
    modified_request = request.override( headers = { "Authorization": auth_header } )
    return await handler(modified_request)

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
        tools=tools,
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


