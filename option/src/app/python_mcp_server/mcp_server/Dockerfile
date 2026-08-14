FROM ghcr.io/astral-sh/uv:latest AS uv

FROM python:3-bookworm

COPY --from=uv /uv /uvx /bin/

WORKDIR /app
COPY requirements.txt ./
RUN uv pip install --system -r requirements.txt

COPY ./ /app/

ENTRYPOINT ["python3","mcp_server.py"]
