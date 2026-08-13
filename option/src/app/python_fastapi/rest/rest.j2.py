{% import "python.j2_macro" as m with context %}
import os
import traceback

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, PlainTextResponse

{{ m.import() }}

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/dept")
def dept():
    {{ m.dept() }}
    return a


@app.get("/info", response_class=PlainTextResponse)
def info():
    return "Python - FastAPI - {{ dbName }}"


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8080
    )