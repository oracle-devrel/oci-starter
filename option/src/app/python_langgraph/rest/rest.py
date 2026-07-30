import asyncio
import json
import os
import time
import uuid
from dataclasses import dataclass, field
from typing import Any, AsyncIterator

import aiohttp
import uvicorn
from aiocache import SimpleMemoryCache, cached
from fastapi import Body, Depends, FastAPI, Header, HTTPException
from fastapi.encoders import jsonable_encoder
from fastapi.responses import StreamingResponse
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage, ToolMessage

from agent import agent, reload_agent_config
from config import config_router, set_agent_reload_callback

app = FastAPI(title="LangGraph Agent")
set_agent_reload_callback(reload_agent_config)
app.include_router(config_router)

# Minimal user object passed through LangGraph runtime config to agent.py.
@dataclass
class AuthUser:
    identity: str
    auth_header: str
    email: str = "spam@oracle.com"
    is_authenticated: bool = True

    def dict(self) -> dict[str, Any]:
        return {
            "identity": self.identity,
            "auth_header": self.auth_header,
            "email": self.email,
            "is_authenticated": self.is_authenticated,
        }


# In-memory thread store used by the FastAPI replacement for langgraph dev.
@dataclass
class ThreadState:
    messages: list[Any] = field(default_factory=list)
    next_message_id: int = 0
    lock: asyncio.Lock = field(default_factory=asyncio.Lock)
    last_accessed: float = field(default_factory=time.time)


threads: dict[str, ThreadState] = {}


# Bearer tokens are validated against IDCS and cached briefly to avoid
# repeated userinfo lookups during a chat session.
@cached(cache=SimpleMemoryCache, ttl=3600)
async def get_username_from_auth_header(auth_header: str) -> str:
    idcs_url = os.getenv("IDCS_URL")
    if not idcs_url:
        raise HTTPException(status_code=401, detail="IDCS_URL is not configured")

    userinfo_url = f"{idcs_url}oauth2/v1/userinfo"
    async with aiohttp.ClientSession() as session:
        async with session.get(userinfo_url, headers={"Authorization": auth_header}) as response:
            if response.status >= 400:
                raise HTTPException(status_code=401, detail="Invalid JWT Token")
            data = await response.json()
            username = data.get("sub")
            if not username:
                raise HTTPException(status_code=401, detail="Invalid JWT Token")
            return username


async def get_current_user(authorization: str | None = Header(default=None)) -> AuthUser:
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing authorization header")

    try:
        scheme, token = authorization.split(maxsplit=1)
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid authorization header") from None

    if scheme == "Bearer":
        token = await get_username_from_auth_header(authorization)
    elif scheme != "User":
        raise HTTPException(status_code=401, detail="Access Denied")

    return AuthUser(identity=token, auth_header=authorization)


def sse_event(payload: dict[str, Any]) -> str:
    return f"data: {json.dumps(jsonable_encoder(payload))}\r\n\r\n"


def content_to_text(content: Any) -> str:
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                parts.append(str(item.get("text", "")))
            else:
                parts.append(json.dumps(jsonable_encoder(item)))
        return "\n".join(part for part in parts if part)
    return str(content)


def message_from_payload(message: dict[str, Any]) -> Any:
    role = message.get("role") or message.get("type")
    content = message.get("content", "")

    if role in {"human", "user"}:
        return HumanMessage(content=content)
    if role in {"ai", "assistant"}:
        return AIMessage(content=content)
    if role == "system":
        return SystemMessage(content=content)
    if role == "tool":
        return ToolMessage(
            content=content,
            tool_call_id=message.get("tool_call_id") or message.get("id") or "",
            name=message.get("name"),
        )

    raise HTTPException(status_code=400, detail=f"Unsupported message role: {role}")


def messages_from_payload(payload: dict[str, Any]) -> list[Any]:
    input_payload = payload.get("input") or {}
    raw_messages = input_payload.get("messages") or payload.get("messages") or []
    if not isinstance(raw_messages, list) or not raw_messages:
        raise HTTPException(status_code=400, detail="Missing input.messages")
    return [message_from_payload(message) for message in raw_messages]


def message_to_payload(message: Any) -> dict[str, Any]:
    message_type = getattr(message, "type", None)
    payload: dict[str, Any] = {
        "type": message_type or "ai",
        "content": content_to_text(getattr(message, "content", "")),
    }

    name = getattr(message, "name", None)
    if name:
        payload["name"] = name

    tool_calls = getattr(message, "tool_calls", None)
    if tool_calls:
        payload["tool_calls"] = jsonable_encoder(tool_calls)

    artifact = getattr(message, "artifact", None)
    if artifact is not None:
        payload["artifact"] = jsonable_encoder(artifact)

    return payload


def append_messages_event(thread: ThreadState, messages: list[Any]) -> str:
    # The UI consumes LangGraph-style SSE payloads keyed by monotonic message ids.
    payload: dict[str, Any] = {"messages": {}}
    for message in messages:
        payload["messages"][str(thread.next_message_id)] = message_to_payload(message)
        thread.next_message_id += 1
    return sse_event(payload)


def agent_config(auth_user: AuthUser) -> dict[str, Any]:
    # agent.py reads this config to forward the original auth header to MCP tools.
    return {
        "configurable": {
            "user_id": auth_user.identity,
            "langgraph_auth_user": auth_user,
        }
    }


def get_thread_for_run(thread_id: str, payload: dict[str, Any]) -> ThreadState:
    if payload.get("assistant_id") not in {None, "agent"}:
        raise HTTPException(status_code=404, detail="Unknown assistant")

    thread = threads.get(thread_id)
    if thread is None:
        raise HTTPException(status_code=404, detail="Unknown thread")

    return thread


def run_output_payload(messages: list[Any]) -> dict[str, Any]:
    return {"messages": [message_to_payload(message) for message in messages]}


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/ready")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/threads")
async def create_thread(
    _auth_user: AuthUser = Depends(get_current_user),
) -> dict[str, str]:
    # Keep this endpoint body-free so callers can create threads with any body.
    thread_id = uuid.uuid4().hex
    threads[thread_id] = ThreadState()
    return {"thread_id": thread_id}


@app.post("/threads/{thread_id}/runs/stream")
async def stream_run(
    thread_id: str,
    payload: dict[str, Any] = Body(default_factory=dict),
    auth_user: AuthUser = Depends(get_current_user),
) -> StreamingResponse:
    thread = get_thread_for_run(thread_id, payload)
    new_messages = messages_from_payload(payload)

    async def event_stream() -> AsyncIterator[str]:
        async with thread.lock:
            try:
                # Serialize runs per thread and preserve prior messages for context.
                input_messages = [*thread.messages, *new_messages]
                final_messages = input_messages
                seen_count = len(thread.messages)

                async for state in agent.astream(
                    {"messages": input_messages},
                    config=agent_config(auth_user),
                    stream_mode="values",
                ):
                    messages = list(state.get("messages", []))
                    if len(messages) <= seen_count:
                        continue
                    yield append_messages_event(thread, messages[seen_count:])
                    seen_count = len(messages)
                    final_messages = messages

                thread.messages = final_messages
                thread.last_accessed = time.time()
            except asyncio.CancelledError:
                raise
            except Exception as exc:
                yield sse_event({"error": str(exc)})

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


@app.post("/threads/{thread_id}/runs/wait")
async def wait_run(
    thread_id: str,
    payload: dict[str, Any] = Body(default_factory=dict),
    auth_user: AuthUser = Depends(get_current_user),
) -> dict[str, Any]:
    thread = get_thread_for_run(thread_id, payload)
    new_messages = messages_from_payload(payload)

    async with thread.lock:
        try:
            # Same run semantics as /runs/stream, but return the final state as JSON.
            input_messages = [*thread.messages, *new_messages]
            final_messages = input_messages

            async for state in agent.astream(
                {"messages": input_messages},
                config=agent_config(auth_user),
                stream_mode="values",
            ):
                messages = list(state.get("messages", []))
                if messages:
                    final_messages = messages

            thread.messages = final_messages
            thread.next_message_id = max(thread.next_message_id, len(final_messages))
            thread.last_accessed = time.time()
            return run_output_payload(final_messages)
        except asyncio.CancelledError:
            raise
        except Exception as exc:
            raise HTTPException(status_code=500, detail=str(exc)) from exc


if __name__ == "__main__":
    uvicorn.run(
        app,
        host=os.getenv("HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", "8080")),
        reload=False,
    )
