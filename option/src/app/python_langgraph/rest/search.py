import pprint
import traceback
from typing import Any

import json
import oci
from oci.generative_ai_data import GenerateSqlFromNlJobClient
from oci.generative_ai_data.models import GenerateSqlFromNlDetails
from oci.retry import NoneRetryStrategy

import httpx
from langchain_core.tools import tool
from openai import OpenAI
from oci_genai_auth import OciInstancePrincipalAuth, OciResourcePrincipalAuth

import oracledb

from config import config, require_config


def log(message: str) -> None:
    print(message, flush=True)


def build_oci_signer() -> Any:
    if config("AUTH_TYPE") == "RESOURCE_PRINCIPAL":
        return oci.auth.signers.get_resource_principals_signer()
    return oci.auth.signers.InstancePrincipalsSecurityTokenSigner()


def close_client(client: Any) -> None:
    close = getattr(client, "close", None)
    if callable(close):
        close()


def extract_generated_sql(data: Any) -> str | None:
    if isinstance(data, dict):
        print("dict")
        job_output = data.get("job_output") or data.get("jobOutput") or {}
        content = job_output.get("content") if isinstance(job_output, dict) else None
        return str(content) if content else None

    print("not dict")
    job_output = getattr(data, "job_output", None) or getattr(data, "jobOutput", None)
    content = getattr(job_output, "content", None) if job_output is not None else None
    return str(content) if content else None


def responses_get_client() -> OpenAI:
    require_config(["REGION", "PROJECT_OCID", "COMPARTMENT_OCID"])

    auth = (
        OciResourcePrincipalAuth()
        if config("AUTH_TYPE") == "RESOURCE_PRINCIPAL"
        else OciInstancePrincipalAuth()
    )

    return OpenAI(
        base_url=f"https://inference.generativeai.{config('REGION')}.oci.oraclecloud.com/20231130/openai/v1",
        api_key="unused",
        project=config("PROJECT_OCID"),
        http_client=httpx.Client(
            auth=auth,
            headers={
                "opc-compartment-id": config("COMPARTMENT_OCID"),
            },
        ),
    )


def responses_format(response: Any) -> dict[str, Any] | None:
    log(pprint.pformat(response, indent=2, sort_dicts=True))

    message = next(
        (output for output in getattr(response, "output", []) if getattr(output, "type", None) == "message"),
        None,
    )
    if not message or not getattr(message, "content", None):
        return None

    content = message.content[0]
    text = getattr(content, "text", "")
    file_map: dict[str, dict[str, Any]] = {}

    for item in getattr(response, "output", []):
        if getattr(item, "type", None) != "file_search_call":
            continue

        for result in getattr(item, "results", []) or []:
            attributes = getattr(result, "attributes", None) or {}
            file_map[result.file_id] = {
                "url": attributes.get("customized_url_source"),
                "file_name": getattr(result, "filename", None),
                "score": getattr(result, "score", None),
            }

    citations = []
    for annotation in getattr(content, "annotations", []) or []:
        if getattr(annotation, "type", None) != "file_citation":
            continue

        file_id = annotation.file_id
        metadata = file_map.get(file_id, {})
        additional_properties = getattr(annotation, "additional_properties", None) or {}
        pages = additional_properties.get("page_numbers") or []
        if not isinstance(pages, list):
            pages = [pages]
        url = metadata.get("url")
        if url and pages:
            url = f"{url}#{pages[0]}"

        citations.append(
            {
                "file_id": file_id,
                "file_name": metadata.get("file_name"),
                "url": url,
                "score": metadata.get("score"),
                "pages": pages,
                "chunk_id": additional_properties.get("chunk_id"),
            }
        )

    unique = {}
    for citation in citations:
        key = (citation["file_id"], tuple(citation["pages"]))
        if key not in unique:
            unique[key] = citation

    citations_sorted = sorted(
        unique.values(),
        key=lambda citation: citation["score"] or 0,
        reverse=True,
    )

    log(pprint.pformat(citations_sorted, indent=2, sort_dicts=True))

    return {
        "response": text,
        "citations": citations_sorted,
    }


@tool("search_vector_store")
def search_vector_store(question: str) -> dict[str, Any] | None:
    """Search the configured OCI vector store and answer with document-backed citations. When returning the result, show the citations in a table format (Name of the file and URL)."""
    log("<responses_search>")

    try:
        require_config(["VECTOR_STORE_ID", "GENAI_MODEL", "PROJECT_OCID"])

        client = None
        try:
            client = responses_get_client()
            response = client.responses.create(
                model=config("GENAI_MODEL"),
                temperature=0.0,
                input=(
                    "Answer using only information from the retrieved documents. "
                    "You may summarize or synthesize information that is explicitly supported by the retrieved text. "
                    "Do not use outside knowledge. If the retrieved documents do not contain enough information to answer, "
                    "say exactly: 'I don't have sufficient information in the documents.'. "
                    f"The question is: {question}"
                ),
                tools=[
                    {
                        "type": "file_search",
                        "vector_store_ids": [config("VECTOR_STORE_ID")],
                        "max_num_results": 10,
                    }
                ],
                extra_headers={"OpenAI-Project": config("PROJECT_OCID")},
                tool_choice="required",
                include=["file_search_call.results"],
            )
        finally:
            if client is not None:
                close_client(client)

        log("<after> client.responses.create")
        return responses_format(response)
    except Exception as exc:
        log(
            "\n".join(
                (
                    f"<responses_search> failed: {type(exc).__name__}: {exc}",
                    traceback.format_exc(),
                )
            ).rstrip()
        )
        raise


@tool("search_database")
def search_database(question: str) -> dict[str, Any]:
    """Search in the Oracle Database Tables"""
    log("<search_in_database>")

    client = None
    connection = None
    try:
        require_config(["DB_USER", "DB_PASSWORD", "DB_URL", "REGION", "SEMANTIC_STORE_OCID"])
        service_endpoint = f"https://inference.generativeai.{config('REGION')}.oci.oraclecloud.com"

        signer = build_oci_signer()

        client = GenerateSqlFromNlJobClient(
            config={},
            signer=signer,
            service_endpoint=service_endpoint,
            retry_strategy=NoneRetryStrategy(),
        )

        details = GenerateSqlFromNlDetails(
            display_name="search_in_database",
            description="Generate SQL from a natural language database question.",
            input_natural_language_query=question,
        )

        resp = client.generate_sql_from_nl(
            details,
            config('SEMANTIC_STORE_OCID'),
        )

        print("HTTP status:", resp.status)
        print("opc-request-id:", resp.headers.get("opc-request-id"))

        print(json.dumps(resp, indent=2, default=str))
        
        data = resp.data
        if hasattr(data, "to_dict"):
            data = data.to_dict()

        print(json.dumps(data, indent=2, default=str))
        sql = extract_generated_sql(data)
        if not sql:
            raise ValueError("No SQL was generated for the database search")
        sql = str(sql).strip().rstrip(";")
   
        connection = oracledb.connect(
            user=config("DB_USER"),
            password=config("DB_PASSWORD"),
            dsn=config("DB_URL"),
        )
        log("<search_database> connected to db")
        try:
            with connection.cursor() as cursor:
                log(f"<search_database> before running sql: {sql}")                
                cursor.execute(sql)
                columns = [column[0].lower() for column in cursor.description or []]
                rows = cursor.fetchall()
                log(f"<search_database> after running sql: {rows}")                  
                return {
                    "sql": sql,
                    "result": [
                        dict(zip(columns, row))
                        for row in rows
                    ],
                }
        finally:
            if connection is not None:
                connection.close()
    except Exception as exc:
        log(
            "\n".join(
                (
                    f"<search_database> failed: {type(exc).__name__}: {exc}",
                    traceback.format_exc(),
                )
            ).rstrip()
        )
        raise
    finally:
        if client is not None:
            close_client(client)

def get_search_tools() -> list[Any]:
    tools = []
    if config("VECTOR_STORE_ID"):
        tools.append(search_vector_store)
    if config("SEMANTIC_STORE_OCID"):
        tools.append(search_database)
    return tools
