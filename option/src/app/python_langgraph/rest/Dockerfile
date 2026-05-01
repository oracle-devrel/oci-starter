FROM python:3-bookworm

RUN pip install --upgrade pip

WORKDIR /app
ENV PATH="/app/.local/bin:${PATH}"
COPY ./ /app/
RUN pip3 install -r requirements.txt
WORKDIR "/app/agent"
ENTRYPOINT ["langgraph", "dev", "--port", "8080", "--host", "0.0.0.0"]

