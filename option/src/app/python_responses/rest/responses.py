import json
import os
import uuid
from typing import Any

from fastapi import FastAPI, Request
from openai import OpenAI
from fastapi.responses import StreamingResponse

# Defaults can be overridden by AGENT_HUB_REGION.
REGION = os.getenv("TF_VAR_region")
MODEL_ID = "openai.gpt-oss-120b"
# REGION = "us-chicago-1"
# MODEL_ID = "xai.grok-4-fast-non-reasoning"

BASE_URL = f"https://inference.generativeai.{REGION}.oci.oraclecloud.com/20231130/openai/v1"
REGION = os.getenv("TF_VAR_region")
PROJECT_OCID = os.environ.get("TF_VAR_project_ocid")
GENAI_API_KEY = os.environ.get("TF_VAR_genai_api_key")
MCP_SERVER_URL = os.environ.get("MCP_SERVER_URL")
SYSTEM_PROMPT = """
INSTRUCTIONS:
- Assist ONLY with research-related tasks, DO NOT do any math.
- To draw a diagram, use mermaid   
- If not, use MarkDown to give a clear and short answer to the user.
- When showing an agenda, use colored icons to show the importance based on customer score (free, low, medium, high)
"""
client = OpenAI(
    base_url=BASE_URL,
    api_key=GENAI_API_KEY,
    project=PROJECT_OCID,
)

app = FastAPI()


def log(*args, **kwargs):
    print(*args, **kwargs, flush=True)


def get_tools() -> list[dict[str, Any]]:
    if not MCP_SERVER_URL:
        return []
    return [
        {
            "type": "mcp",
            "server_label": "mcp",
            "server_url": MCP_SERVER_URL,
            "require_approval": "never",
        }
    ]

# Simple in-memory state for demo compatibility with chat.js protocol.
THREADS: dict[str, dict[str, Any]] = {}

@app.get("/chat")
def chat(q: str):
    response = client.responses.create(
        model=MODEL_ID,
        temperature=0.0,
        tools=get_tools(),
        input=q,
    )
    return response.output_text


@app.post("/threads")
@app.post("/app/threads")
def create_thread() -> dict[str, str]:
    conversation = client.conversations.create()
    thread_id = conversation.id
    THREADS[thread_id] = {"next_message_id": 1}
    return {"thread_id": thread_id}


@app.post("/assistants/search")
@app.post("/app/assistants/search")
def assistants_search() -> list[dict[str, str]]:
    # chat.js expects an array of objects with a graph_id field.
    return [{"graph_id": "agent"}]


@app.post("/threads/{thread_id}/runs/stream")
@app.post("/app/threads/{thread_id}/runs/stream")
def runs_stream(thread_id: str, payload: dict[str, Any], request: Request):
    if thread_id not in THREADS:
        THREADS[thread_id] = {"next_message_id": 1}

    messages = payload.get("input", {}).get("messages", [])
    log("<runs_stream> messages=", messages)
    question = ""
    if messages:
        question = messages[-1].get("content", "")
    log("<runs_stream> question=", question)

    authorization = request.headers.get("authorization")
    
    message_id = int(THREADS[thread_id].get("next_message_id", 1))
    if message_id == 1:
        log("<runs_stream> SYSTEM_PROMPT")
        input_payload = [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": question},
        ]
    else:
        input_payload = question  # just the user message  if message_id=1:

    response_kwargs: dict[str, Any] = {
        "model": MODEL_ID,
        "temperature": 0.0,
        "tools": get_tools(),     
        "input": input_payload,
        "stream": True,
        "conversation": thread_id
    }

    if authorization and authorization.lower().startswith("bearer "):
        response_kwargs["extra_headers"] = {"Authorization": authorization}
        log("<runs_stream> forwarding bearer authorization header")

    def _to_dict(obj: Any) -> dict[str, Any]:
        if obj is None:
            return {}
        if isinstance(obj, dict):
            return obj
        if hasattr(obj, "model_dump"):
            try:
                return obj.model_dump()
            except Exception:
                pass
        if hasattr(obj, "dict"):
            try:
                return obj.dict()
            except Exception:
                pass
        return {}

    def _emit(event_payload: dict[str, Any], message_id: int):
        event = {"messages": {str(message_id): event_payload}}
        # chat.js splits on CRLF + CRLF and expects lines starting with "data:"
        return f"data: {json.dumps(event)}\r\n\r\n"

    def event_stream():
        log("<event_stream> question=", question)
        response_stream = client.responses.create(**response_kwargs)
        message_id = int(THREADS[thread_id].get("next_message_id", 1))
        content = ""

        for stream_event in response_stream:
            event_type = getattr(stream_event, "type", "")

            if event_type == "response.output_item.done":
                item = _to_dict(getattr(stream_event, "item", None))
                item_type = item.get("type", "")

                # Surface tool calls to the end-user UI.
                if item_type in {"function_call", "mcp_call", "web_search_call"}:
                    tool_name = (
                        item.get("name")
                        or item.get("tool_name")
                        or item.get("server_tool_name")
                        or item_type
                    )
                    tool_args = (
                        item.get("arguments")
                        or item.get("args")
                        or item.get("input")
                        or {}
                    )
                    if isinstance(tool_args, str):
                        try:
                            tool_args = json.loads(tool_args)
                        except Exception:
                            tool_args = {"raw": tool_args}

                    yield _emit(
                        {
                            "type": "ai",
                            "tool_calls": [
                                {
                                    "name": tool_name,
                                    "args": tool_args,
                                }
                            ],
                        },
                        message_id,
                    )
                    message_id += 1

                # Surface tool results to the end-user UI.
                elif item_type in {"function_call_output", "mcp_call_output", "tool_result"}:
                    tool_name = (
                        item.get("name")
                        or item.get("tool_name")
                        or item.get("server_tool_name")
                        or "tool"
                    )
                    tool_result = item.get("output") or item.get("result") or item.get("content")
                    structured_content: dict[str, Any] = {}
                    if isinstance(tool_result, (list, dict)):
                        structured_content["result"] = tool_result
                    else:
                        structured_content["response"] = str(tool_result or "")

                    yield _emit(
                        {
                            "type": "tool",
                            "name": tool_name,
                            "artifact": {
                                "structured_content": structured_content,
                            },
                        },
                        message_id,
                    )
                    message_id += 1

            if event_type == "response.output_text.delta":
                delta = getattr(stream_event, "delta", "") or ""
                if not delta:
                    continue
                content += delta
                continue

        if not content:
            response = response_stream.get_final_response()
            content = response.output_text
            log("<event_stream> output_text=", content)
            log("<event_stream> response=", response)

        # Emit AI answer once (no per-delta messages)
        yield _emit({"type": "ai", "content": content}, message_id)
        message_id += 1

        THREADS[thread_id]["next_message_id"] = message_id

    return StreamingResponse(event_stream(), media_type="text/event-stream")

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8080)
