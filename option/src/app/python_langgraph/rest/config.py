import json
import os
import threading
from pathlib import Path
from typing import Any

import httpx
import oci
import oci_openai
from fastapi import APIRouter, Body, HTTPException
from openai import OpenAI

CONFIG_FILE = Path(os.getenv("APP_CONFIG_FILE", Path(__file__).with_name("config.json")))

DEFAULT_AGENT_PROMPT = """You are an agent that use the tools you got access to.

INSTRUCTIONS:
- Assist ONLY with research-related tasks, DO NOT do any math.
- When using a MCP tool, take care not to  pass empty parameters name like "", or {"":{}}
- To draw a diagram, use mermaid.
- For Mermaid bar charts, use the xychart diagram type, not a top-level "bar" diagram.
  Example:
  ```mermaid
  xychart
      title "Employees by Department"
      x-axis "Department" ["Dept 10", "Dept 20", "Dept 30"]
      y-axis "Number of Employees"
      bar [3, 5, 6]
  ```
- If not, use MarkDown to give a clear and short answer to the user.
- Do not call the same tools twice
- Call maximum 3 tools at the same time
"""

CONFIG_FIELDS: list[dict[str, str]] = [
    {"name": "REGION", "label": "Region", "type": "LOV"},
    {"name": "GENAI_MODEL", "label": "GenAI model", "type": "LOV"},
    {"name": "AGENT_PROMPT", "label": "Agent prompt", "type": "TEXTAREA"},
    {"name": "VECTOR_STORE_ID", "label": "Vector store", "type": "LOV", "optional": "true"},
    {"name": "SEMANTIC_STORE_OCID", "label": "Semantic store", "type": "LOV", "optional": "true"},
    {"name": "MCP_SERVER_URL", "label": "MCP server URL", "type": "TEXT", "optional": "true"},
    {"name": "MCP_AUTH_TYPE", "label": "MCP authentication", "type": "LOV"},
    {"name": "MCP_STATIC_BEARER_TOKEN", "label": "Static MCP bearer token", "type": "PASSWORD", "optional": "true"},
    {"name": "AUTH_TYPE", "label": "OCI authentication", "type": "LOV"},
]

FIELD_NAMES = {field["name"] for field in CONFIG_FIELDS}
OCI_REGIONS: list[dict[str, str]] = [
    {"name": "Brazil East (Sao Paulo)", "id": "sa-saopaulo-1"},
    {"name": "Germany Central (Frankfurt)", "id": "eu-frankfurt-1"},
    {"name": "India South (Hyderabad)", "id": "ap-hyderabad-1"},
    {"name": "Japan Central (Osaka)", "id": "ap-osaka-1"},
    {"name": "Saudi Arabia Central (Riyadh)", "id": "me-riyadh-1"},
    {"name": "UAE Central (Abu Dhabi)", "id": "me-abudhabi-1"},
    {"name": "UAE East (Dubai)", "id": "me-dubai-1"},
    {"name": "UK South (London)", "id": "uk-london-1"},
    {"name": "US East (Ashburn)", "id": "us-ashburn-1"},
    {"name": "US Midwest (Chicago)", "id": "us-chicago-1"},
    {"name": "US West (Phoenix)", "id": "us-phoenix-1"},
]
FIXED_LOVS: dict[str, list[str]] = {
    "REGION": [region["id"] for region in OCI_REGIONS],
    "AUTH_TYPE": ["INSTANCE_PRINCIPAL", "RESOURCE_PRINCIPAL"],
    "MCP_AUTH_TYPE": ["BEARER_TOKEN_PROPAGATION", "NONE", "STATIC_BEARER_TOKEN"],
}

_CONFIG_LOCK = threading.Lock()
_CONFIG_WARNING: str | None = None
_AGENT_RELOAD_CALLBACK: Any | None = None


class ConfigError(ValueError):
    pass


def env_config() -> dict[str, str]:
    return {
        "REGION": os.getenv("REGION") or os.getenv("TF_VAR_region") or "eu-frankfurt-1",
        "GENAI_MODEL": os.getenv("GENAI_MODEL") or "openai.gpt-oss-120b",
        "AGENT_PROMPT": os.getenv("AGENT_PROMPT") or DEFAULT_AGENT_PROMPT,
        "VECTOR_STORE_ID": os.getenv("VECTOR_STORE_ID") or "",
        "SEMANTIC_STORE_OCID": os.getenv("SEMANTIC_STORE_OCID") or "",
        "MCP_SERVER_URL": os.getenv("MCP_SERVER_URL") or "",
        "MCP_AUTH_TYPE": os.getenv("MCP_AUTH_TYPE") or "BEARER_TOKEN_PROPAGATION",
        "MCP_STATIC_BEARER_TOKEN": os.getenv("MCP_STATIC_BEARER_TOKEN") or "",
        "AUTH_TYPE": os.getenv("AUTH_TYPE") or "INSTANCE_PRINCIPAL",
    }


def _read_raw_config() -> dict[str, str]:
    if not CONFIG_FILE.exists():
        return {}

    try:
        with CONFIG_FILE.open("r", encoding="utf-8") as config_file:
            data = json.load(config_file)
    except json.JSONDecodeError as exc:
        raise ConfigError(f"{CONFIG_FILE.name} is not valid JSON: {exc}") from exc

    if not isinstance(data, dict):
        raise ConfigError(f"{CONFIG_FILE.name} must contain a JSON object")

    return {
        key: "" if value is None else str(value)
        for key, value in data.items()
        if key in FIELD_NAMES
    }


def _complete_config(values: dict[str, str]) -> dict[str, str]:
    return {field["name"]: values.get(field["name"], "") for field in CONFIG_FIELDS}


def initial_config() -> dict[str, str]:
    values = env_config()
    if CONFIG_FILE.exists():
        values.update(_read_raw_config())
    return _complete_config(values)


def _write_raw_config(values: dict[str, str]) -> None:
    CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
    payload = {field["name"]: values.get(field["name"], "") for field in CONFIG_FIELDS}
    with CONFIG_FILE.open("w", encoding="utf-8") as config_file:
        json.dump(payload, config_file, indent=2)
        config_file.write("\n")


def get_effective_config() -> dict[str, str]:
    with _CONFIG_LOCK:
        return _complete_config(CONFIG)


def normalize_region(region: str) -> str:
    if region == "eu-amsterdam-1":
        return "eu-frankfurt-1"
    return region


def config(variable_name: str) -> str:
    return CONFIG.get(variable_name)


def require_config(variable_names: list[str] | tuple[str, ...]) -> None:
    missing = []
    for variable_name in variable_names:
        if not config(variable_name):
            missing.append(variable_name)

    if missing:
        raise ConfigError(f"{', '.join(missing)} is not configured")


def refresh_runtime_globals(values: dict[str, str] | None = None) -> None:
    runtime_config = values if values is not None else CONFIG
    CONFIG.update(
        {
            field_name: runtime_config.get(field_name, "")
            for field_name in FIELD_NAMES
            if field_name in runtime_config
        }
    )
    CONFIG.update(
        {
            "PROJECT_OCID": os.getenv("TF_VAR_project_ocid") or os.getenv("PROJECT_OCID") or "",
            "COMPARTMENT_OCID": os.getenv("TF_VAR_compartment_ocid") or "",
            "DB_USER": os.getenv("DB_USER") or "",
            "DB_PASSWORD": os.getenv("DB_PASSWORD") or "",
            "DB_URL": os.getenv("DB_URL") or "",
            "REGION": normalize_region(runtime_config.get("REGION", "")),
        }
    )


def save_config(updates: dict[str, Any]) -> dict[str, str]:
    global CONFIG, _CONFIG_WARNING

    if not isinstance(updates, dict):
        raise ConfigError("Configuration payload must be a JSON object")

    unknown_fields = sorted(set(updates) - FIELD_NAMES)
    if unknown_fields:
        raise ConfigError(f"Unknown configuration field(s): {', '.join(unknown_fields)}")

    with _CONFIG_LOCK:
        next_values = dict(CONFIG)

        for name, value in updates.items():
            next_values[name] = "" if value is None else str(value).strip()

        CONFIG.clear()
        CONFIG.update(next_values)
        refresh_runtime_globals(CONFIG)
        try:
            _write_raw_config(next_values)
            _CONFIG_WARNING = None
        except OSError as exc:
            _CONFIG_WARNING = (
                f"Warning: could not write {CONFIG_FILE}. "
                "Configuration is saved only in memory."
            )
            print(f"{_CONFIG_WARNING} {exc}", flush=True)

    return get_effective_config()


def get_config_warning() -> str | None:
    return _CONFIG_WARNING


CONFIG: dict[str, str] = initial_config()
for key, value in CONFIG.items():
    print(f"Config {key}={value}")
refresh_runtime_globals(CONFIG)

def get_lov(field_name: str, values: dict[str, Any] | None = None) -> list[str]:
    if field_name in FIXED_LOVS:
        return FIXED_LOVS[field_name]
    values_list, _labels = get_dynamic_lov(field_name, values)
    return values_list

def get_lov_labels(field_name: str, values: dict[str, Any] | None = None) -> dict[str, str]:
    if field_name == "REGION":
        return region_labels()
    _values_list, labels = get_dynamic_lov(field_name, values)
    return labels

def get_dynamic_lov(
    field_name: str,
    values: dict[str, Any] | None = None,
) -> tuple[list[str], dict[str, str]]:
    if field_name == "VECTOR_STORE_ID":
        update_config_for_lov(values)
        return get_vector_stores()
    if field_name == "SEMANTIC_STORE_OCID":
        update_config_for_lov(values)
        return get_semantic_stores()
    if field_name == "GENAI_MODEL":
        update_config_for_lov(values)
        return get_genai_models()
    return [], {}


def update_config_for_lov(values: dict[str, Any] | None) -> None:
    if not values:
        return

    with _CONFIG_LOCK:
        for key in ("REGION", "AUTH_TYPE"):
            if values.get(key):
                CONFIG[key] = str(values[key]).strip()
        refresh_runtime_globals(CONFIG)


def list_configuration_parameters() -> dict[str, Any]:
    values = get_effective_config()
    parameters = []

    for field in CONFIG_FIELDS:
        name = field["name"]
        parameters.append(
            {
                **field,
                "value": values.get(name, ""),
                "lov": get_lov(name, values) if field["type"] == "LOV" else [],
                "lov_labels": get_lov_labels(name, values) if field["type"] == "LOV" else {},
            }
        )

    response: dict[str, Any] = {"parameters": parameters, "values": values}
    if _CONFIG_WARNING:
        response["warning"] = _CONFIG_WARNING
    return response


config_router = APIRouter()


def set_agent_reload_callback(callback: Any) -> None:
    global _AGENT_RELOAD_CALLBACK
    _AGENT_RELOAD_CALLBACK = callback


async def reload_agent_config() -> None:
    if _AGENT_RELOAD_CALLBACK is not None:
        await _AGENT_RELOAD_CALLBACK()


@config_router.get("/config/parameters")
async def read_configuration() -> dict[str, Any]:
    try:
        return list_configuration_parameters()
    except ConfigError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@config_router.put("/config/parameters")
async def update_configuration(
    payload: dict[str, Any] = Body(default_factory=dict),
) -> dict[str, Any]:
    try:
        save_config(payload)
        await reload_agent_config()
        return list_configuration_parameters()
    except ConfigError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Configuration saved, but the agent could not be reloaded: {exc}",
        ) from exc


@config_router.get("/config/lov/{field_name}")
async def read_configuration_lov(
    field_name: str,
    region: str | None = None,
    auth_type: str | None = None,
) -> dict[str, Any]:
    values = {
        "REGION": region,
        "AUTH_TYPE": auth_type,
    }
    return {
        "field": field_name,
        "values": get_lov(field_name, values),
        "lov_labels": get_lov_labels(field_name, values),
    }


def _build_oci_signer(auth_type: str) -> Any:
    if auth_type == "RESOURCE_PRINCIPAL":
        return oci.auth.signers.get_resource_principals_signer()
    return oci.auth.signers.InstancePrincipalsSecurityTokenSigner()


def inference_client() -> Any:
    require_config(["REGION"])
    auth_type = config("AUTH_TYPE")

    return oci.generative_ai.GenerativeAiClient(
        config={},
        signer=_build_oci_signer(auth_type),
        service_endpoint=f"https://generativeai.{config('REGION')}.oci.oraclecloud.com",
    )


def _build_openai_auth() -> Any:
    if config("AUTH_TYPE") == "RESOURCE_PRINCIPAL":
        return oci_openai.OciResourcePrincipalAuth()
    return oci_openai.OciInstancePrincipalAuth()


def openai_client() -> OpenAI:
    require_config(["REGION", "PROJECT_OCID"])
    auth_type = config("AUTH_TYPE")
    compartment_ocid = config("COMPARTMENT_OCID")

    from oci_genai_auth import OciInstancePrincipalAuth, OciResourcePrincipalAuth

    if auth_type == "RESOURCE_PRINCIPAL":
        auth = OciResourcePrincipalAuth()
    else:
        auth = OciInstancePrincipalAuth()

    return OpenAI(
        base_url=f"https://generativeai.{config('REGION')}.oci.oraclecloud.com/20231130/openai/v1",
        api_key="unused",
        http_client=httpx.Client(
            auth=auth,
            headers={
                "opc-compartment-id": compartment_ocid,
            },
        ),
        project=config("PROJECT_OCID"),
    )


def _model_identifier(model: Any) -> str:
    for attribute in ("name", "display_name", "displayName", "model_name", "modelName", "model_id", "modelId", "id"):
        value = getattr(model, attribute, None)
        if value:
            return str(value)
    if isinstance(model, dict):
        for attribute in ("name", "display_name", "displayName", "model_name", "modelName", "model_id", "modelId", "id"):
            value = model.get(attribute)
            if value:
                return str(value)
    return ""


def _display_name(resource: Any, fallback: str) -> str:
    if isinstance(resource, dict):
        return str(
            resource.get("display_name")
            or resource.get("displayName")
            or resource.get("name")
            or fallback
        )
    return str(
        getattr(resource, "display_name", None)
        or getattr(resource, "name", None)
        or fallback
    )


def _resource_identifier(resource: Any, *attributes: str) -> str:
    if isinstance(resource, dict):
        for attribute in attributes:
            value = resource.get(attribute) or resource.get(_snake_to_camel(attribute))
            if value:
                return str(value)
        return ""

    for attribute in attributes:
        value = getattr(resource, attribute, None)
        if value:
            return str(value)
    return ""


def _snake_to_camel(value: str) -> str:
    head, *tail = value.split("_")
    return head + "".join(part.title() for part in tail)


def region_labels() -> dict[str, str]:
    return {
        region["id"]: f"{region['name']} - {region['id']}"
        for region in OCI_REGIONS
    }


def _openai_page_items(response: Any) -> list[Any]:
    if hasattr(response, "auto_paging_iter"):
        return list(response.auto_paging_iter())
    items = getattr(response, "data", response)
    return list(items or [])


def get_vector_stores() -> tuple[list[str], dict[str, str]]:
    try:
        client = openai_client()
        response = client.vector_stores.list()
        # print(f"Debug: {response}", flush=True)
        items = _openai_page_items(response)
        labels = {
            store_id: _display_name(store, store_id)
            for store in items
            if (store_id := _resource_identifier(store, "id", "vector_store_id")) and store.status=="completed"
        }
        stores = sorted(labels, key=lambda store_id: labels[store_id].lower())
    except Exception as exc:
        if isinstance(exc, ConfigError):
            raise
        print(f"Unable to load OCI vector stores for region {config('REGION')}: {exc}", flush=True)
        stores = []
        labels = {}

    return stores, labels


def get_semantic_stores() -> tuple[list[str], dict[str, str]]:
    try:
        client = inference_client()

        # sort_by="displayName" cause HTTP-400
        response = oci.pagination.list_call_get_all_results(
            client.list_semantic_stores,
            compartment_id=config("COMPARTMENT_OCID"),
            sort_by="displayName",
            sort_order="ASC",
        )
        items = getattr(response.data, "items", response.data)
        # for store in items:
        #    print( store )        
        labels = {
            store_id: _display_name(store, store_id)
            for store in items
            if (store_id := _resource_identifier(store, "id")) and store.lifecycle_state=="ACTIVE"
        }
        stores = sorted(labels, key=lambda store_id: labels[store_id].lower())
    except Exception as exc:
        if isinstance(exc, ConfigError):
            raise
        print(f"Unable to load OCI semantic stores for region {config('REGION')}: {exc}", flush=True)
        stores = []
        labels = {}

    return stores, labels


def get_genai_models() -> tuple[list[str], dict[str, str]]:
    try:
        client = inference_client()

        response = oci.pagination.list_call_get_all_results(
            client.list_models,
            compartment_id=config("COMPARTMENT_OCID"),
        )
        items = getattr(response.data, "items", response.data)
        # for model in items:
        #    print( model )               
        labels = {
            model_id: _display_name(model, model_id)
            for model in items
            if (model_id := _model_identifier(model)) and model.lifecycle_state=="ACTIVE" and model.time_on_demand_retired==None and "CHAT" in model.capabilities
        }
        models = sorted(labels, key=lambda model_id: labels[model_id].lower())
    except Exception as exc:
        if isinstance(exc, ConfigError):
            raise
        print(f"Unable to load OCI GenAI models for region {config('REGION')}: {exc}", flush=True)
        models = []
        labels = {}

    return models, labels
