from langchain_openai import ChatOpenAI
from langchain_oci import ChatOCIGenAI
from langgraph.prebuilt import create_react_agent
from langgraph.graph import StateGraph
from langchain_mcp_adapters.client import MultiServerMCPClient
from langchain_mcp_adapters.interceptors import MCPToolCallRequest
import asyncio
import os
import pprint
import httpx
import oci_openai 
from typing import Any
from config import DEFAULT_AGENT_PROMPT, config
from search import get_search_tools

def build_llm_openai():
    auth = oci_openai.OciInstancePrincipalAuth()
    return ChatOpenAI(
        model="xai.grok-4-fast-reasoning",
        api_key="OCI",
        base_url="https://inference.generativeai.us-chicago-1.oci.oraclecloud.com/20231130/actions/v1",
        http_client=httpx.Client(
            auth=auth,
            headers={"CompartmentId": config("COMPARTMENT_OCID")}
        ),
    )

def build_llm() -> ChatOCIGenAI:
    return ChatOCIGenAI(
        auth_type="API_KEY" if "LIVELABS" in os.environ else config("AUTH_TYPE"),
        model_id=config("GENAI_MODEL"),
        # model_id="meta.llama-4-scout-17b-16e-instruct",
        # model_id="cohere.command-a-03-2025",
        service_endpoint="https://inference.generativeai."+config("REGION")+".oci.oraclecloud.com",
        # model_id="xai.grok-4.3",
        # service_endpoint="https://inference.generativeai.us-chicago-1.oci.oraclecloud.com",
        compartment_id=config("COMPARTMENT_OCID"),
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
    # Forward the original request credentials to every MCP tool call.
    if config("MCP_AUTH_TYPE")=="STATIC_BEARER_TOKEN":
        headers = {"Authorization": "Bearer " + config("MCP_STATIC_BEARER_TOKEN") }
    elif config("MCP_AUTH_TYPE")=="NONE" and not auth_header:
        headers = {}
    else:
        headers = {"Authorization": auth_header}
    modified_request = request.override(args=cleaned_args, headers=headers)
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

async def init( agent_name, prompt, callback_handler=None ) -> StateGraph:

    # Build the graph once at process startup; app.py streams runs from this object.
    # Waiting is important, since after reboot the MCP server could start afterwards.
    delay = 10
    client = None
    agent_tools = list(get_search_tools())
    llm = build_llm()
    if not config("MCP_SERVER_URL"):
        print("MCP_SERVER_URL is not configured; starting agent without MCP tools")
        return create_react_agent(
            model=llm,
            tools=agent_tools,
            prompt=prompt,
            name=agent_name
        )

    for attempt in range(1, 10):
        try:
            print(f"Connecting to MCP {attempt}...")
            client = MultiServerMCPClient(
                {
                    "McpServer": {
                        "transport": "streamable_http",
                        "url": config("MCP_SERVER_URL"),
                    },
                },
                tool_interceptors=[inject_user_context],
            )
            tools = await client.get_tools()
            print( "-- tools ------------------------------------------------------------")
            pprint.pprint( tools )
            agent_tools = [*agent_tools, *tools]
            print( "-- agent_tools ------------------------------------------------------")
            pprint.pprint( agent_tools )
            break
        except Exception as e:
            print(f"Connection failed {attempt}: {e}")            
            print(f"Waiting for {delay} seconds before the next attempt...")
            await asyncio.sleep(delay)

    if client==None:
        raise RuntimeError("ERROR: connection to MCP Failed")

    agent = create_react_agent(
        model=llm,
        tools=agent_tools,
        prompt=prompt,
        name=agent_name
    ) 
    return agent    

async def build_agent() -> StateGraph:
    return await init("agent", config("AGENT_PROMPT") or DEFAULT_AGENT_PROMPT)


class AgentRuntime:
    def __init__(self, graph: StateGraph):
        self._graph = graph
        self._reload_lock = asyncio.Lock()

    async def astream(self, *args, **kwargs):
        graph = self._graph
        async for state in graph.astream(*args, **kwargs):
            yield state

    async def reload(self) -> None:
        async with self._reload_lock:
            self._graph = await build_agent()


agent = AgentRuntime(asyncio.run(build_agent()))


async def reload_agent_config() -> None:
    await agent.reload()
