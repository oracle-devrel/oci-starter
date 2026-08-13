###############################################################################
# Docker images
###############################################################################

locals {
  docker_image_ui   = data.external.env_part2.result.docker_image_ui
  docker_image_rest = data.external.env_part2.result.docker_image_rest

{%- if python_framework in [ "langgraph", "responses" ] %}
  docker_image_mcp_server = data.external.env_part2.result.docker_image_mcp_server
{%- endif %}

  #
  # Hosted deployments take container_uri and tag separately.
  # Container Instance image_url normally contains both.
  #
  rest_image_has_tag = can(regex(":[^/:]+$", local.docker_image_rest))
  rest_container_uri = local.rest_image_has_tag ? replace(
    local.docker_image_rest,
    "/:[^/:]+$/",
    ""
  ) : local.docker_image_rest
  rest_container_tag = local.rest_image_has_tag ? trimprefix(
    regex(":[^/:]+$", local.docker_image_rest),
    ":"
  ) : "latest"

  ui_image_has_tag = can(regex(":[^/:]+$", local.docker_image_ui))
  ui_container_uri = local.ui_image_has_tag ? replace(
    local.docker_image_ui,
    "/:[^/:]+$/",
    ""
  ) : local.docker_image_ui
  ui_container_tag = local.ui_image_has_tag ? trimprefix(
    regex(":[^/:]+$", local.docker_image_ui),
    ":"
  ) : "latest"

{%- if python_framework in [ "langgraph", "responses" ] %}
  mcp_image_has_tag = can(regex(":[^/:]+$", local.docker_image_mcp_server))
  mcp_container_uri = local.mcp_image_has_tag ? replace(
    local.docker_image_mcp_server,
    "/:[^/:]+$/",
    ""
  ) : local.docker_image_mcp_server
  mcp_container_tag = local.mcp_image_has_tag ? trimprefix(
    regex(":[^/:]+$", local.docker_image_mcp_server),
    ":"
  ) : "latest"
{%- endif %}
}


###############################################################################
# REST hosted application
###############################################################################

resource "oci_generative_ai_hosted_application" "starter_rest_hosted_application" {
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-rest-hosted-app"

  ###########################################################################
  # Same environment variables as the old "rest" container
  ###########################################################################

{%- if db_type != "none" %}
  environment_variables {
    name  = "DB_URL"
    type  = "PLAINTEXT"
    value = local.local_db_url
  }

  environment_variables {
    name  = "JDBC_URL"
    type  = "PLAINTEXT"
    value = local.local_jdbc_url
  }

  environment_variables {
    name  = "DB_USER"
    type  = "PLAINTEXT"
    value = var.db_user != null ? var.db_user : "{{ db_user }}"
  }

  environment_variables {
    name  = "DB_PASSWORD"
    type  = "PLAINTEXT"
    value = var.db_password
  }

  environment_variables {
    name  = "JAVAX_SQL_DATASOURCE_DS1_DATASOURCE_URL"
    type  = "PLAINTEXT"
    value = local.local_jdbc_url
  }
{%- endif %}

{%- if db_type == "nosql" %}
  environment_variables {
    name  = "TF_VAR_compartment_ocid"
    type  = "PLAINTEXT"
    value = var.compartment_ocid
  }

  environment_variables {
    name  = "TF_VAR_nosql_endpoint"
    type  = "PLAINTEXT"
    value = "nosql.${var.region}.oci.oraclecloud.com"
  }
{%- endif %}

{%- if python_framework in [ "langgraph", "responses" ] %}
  environment_variables {
    name  = "TF_VAR_region"
    type  = "PLAINTEXT"
    value = var.region
  }

  environment_variables {
    name  = "TF_VAR_compartment_ocid"
    type  = "PLAINTEXT"
    value = var.compartment_ocid
  }

  environment_variables {
    name  = "AUTH_TYPE"
    type  = "PLAINTEXT"
    value = "RESOURCE_PRINCIPAL"
  }
{%- endif %}

{%- if python_framework == "langgraph" %}
  environment_variables {
    name  = "MCP_SERVER_URL"
    type  = "PLAINTEXT"
    value = local.hosted_mcp_invoke_url
  }
{%- elif python_framework == "responses" %}
  environment_variables {
    name  = "TF_VAR_project_ocid"
    type  = "PLAINTEXT"
    value = local.local_project_ocid
  }

  environment_variables {
    name  = "MCP_SERVER_URL"
    type  = "PLAINTEXT"
    value = "https://${local.local_apigw_hostname}/${var.prefix}/mcp_server/mcp"
  }
{%- endif %}

  ###########################################################################
  # Authentication
  ###########################################################################

  inbound_auth_config {
    inbound_auth_config_type = "IDCS_AUTH_CONFIG"

    idcs_config {
      domain_url = var.hosted_app_idcs_domain_url
      scope      = var.hosted_app_idcs_scope
      audience   = var.hosted_app_idcs_audience
    }
  }

  ###########################################################################
  # Networking
  #
  # CUSTOM outbound networking replaces the old Container Instance VNIC
  # behavior and permits access through the application subnet.
  ###########################################################################

  networking_config {
    inbound_networking_config {
      endpoint_mode = "PUBLIC"
    }

    outbound_networking_config {
      network_mode     = "CUSTOM"
      custom_subnet_id = data.oci_core_subnet.starter_app_subnet.id
    }
  }

  ###########################################################################
  # Approximation of one always-running Container Instance
  ###########################################################################

  scaling_config {
    scaling_type        = "CPU"
    min_replica         = 1
    max_replica         = 1
    target_cpu_threshold = 50
  }

  freeform_tags = local.freeform_tags
}


###############################################################################
# REST hosted deployment
###############################################################################

resource "oci_generative_ai_hosted_deployment" "starter_rest_hosted_deployment" {
  compartment_id         = local.lz_app_cmp_ocid
  hosted_application_id  = oci_generative_ai_hosted_application.starter_rest_hosted_application.id

  active_artifact {
    artifact_type = "SIMPLE_DOCKER_ARTIFACT"
    container_uri = local.rest_container_uri
    tag           = local.rest_container_tag
  }

  freeform_tags = local.freeform_tags
}


###############################################################################
# UI hosted application
###############################################################################

resource "oci_generative_ai_hosted_application" "starter_ui_hosted_application" {
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-ui-hosted-app"

  inbound_auth_config {
    inbound_auth_config_type = "IDCS_AUTH_CONFIG"

    idcs_config {
      domain_url = var.hosted_app_idcs_domain_url
      scope      = var.hosted_app_idcs_scope
      audience   = var.hosted_app_idcs_audience
    }
  }

  networking_config {
    inbound_networking_config {
      endpoint_mode = "PUBLIC"
    }

    outbound_networking_config {
      network_mode     = "CUSTOM"
      custom_subnet_id = data.oci_core_subnet.starter_app_subnet.id
    }
  }

  scaling_config {
    scaling_type         = "CPU"
    min_replica          = 1
    max_replica          = 1
    target_cpu_threshold = 50
  }

  freeform_tags = local.freeform_tags
}


###############################################################################
# UI hosted deployment
###############################################################################

resource "oci_generative_ai_hosted_deployment" "starter_ui_hosted_deployment" {
  compartment_id        = local.lz_app_cmp_ocid
  hosted_application_id = oci_generative_ai_hosted_application.starter_ui_hosted_application.id

  active_artifact {
    artifact_type = "SIMPLE_DOCKER_ARTIFACT"
    container_uri = local.ui_container_uri
    tag           = local.ui_container_tag
  }

  freeform_tags = local.freeform_tags
}


###############################################################################
# MCP hosted application/deployment
###############################################################################

{%- if python_framework in [ "langgraph", "responses" ] %}

resource "oci_generative_ai_hosted_application" "starter_mcp_hosted_application" {
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-mcp-hosted-app"

{%- if db_type != "none" %}
  environment_variables {
    name  = "DB_URL"
    type  = "PLAINTEXT"
    value = local.local_db_url
  }

  environment_variables {
    name  = "JDBC_URL"
    type  = "PLAINTEXT"
    value = local.local_jdbc_url
  }

  environment_variables {
    name  = "DB_USER"
    type  = "PLAINTEXT"
    value = var.db_user != null ? var.db_user : "{{ db_user }}"
  }

  environment_variables {
    name  = "DB_PASSWORD"
    type  = "PLAINTEXT"
    value = var.db_password
  }

  environment_variables {
    name  = "JAVAX_SQL_DATASOURCE_DS1_DATASOURCE_URL"
    type  = "PLAINTEXT"
    value = local.local_jdbc_url
  }
{%- endif %}

{%- if db_type == "nosql" %}
  environment_variables {
    name  = "TF_VAR_compartment_ocid"
    type  = "PLAINTEXT"
    value = var.compartment_ocid
  }

  environment_variables {
    name  = "TF_VAR_nosql_endpoint"
    type  = "PLAINTEXT"
    value = "nosql.${var.region}.oci.oraclecloud.com"
  }
{%- endif %}

  inbound_auth_config {
    inbound_auth_config_type = "IDCS_AUTH_CONFIG"

    idcs_config {
      domain_url = var.hosted_app_idcs_domain_url
      scope      = var.hosted_app_idcs_scope
      audience   = var.hosted_app_idcs_audience
    }
  }

  networking_config {
    inbound_networking_config {
      endpoint_mode = "PUBLIC"
    }

    outbound_networking_config {
      network_mode     = "CUSTOM"
      custom_subnet_id = data.oci_core_subnet.starter_app_subnet.id
    }
  }

  scaling_config {
    scaling_type         = "CPU"
    min_replica          = 1
    max_replica          = 1
    target_cpu_threshold = 50
  }

  freeform_tags = local.freeform_tags
}


resource "oci_generative_ai_hosted_deployment" "starter_mcp_hosted_deployment" {
  compartment_id        = local.lz_app_cmp_ocid
  hosted_application_id = oci_generative_ai_hosted_application.starter_mcp_hosted_application.id

  active_artifact {
    artifact_type = "SIMPLE_DOCKER_ARTIFACT"
    container_uri = local.mcp_container_uri
    tag           = local.mcp_container_tag
  }

  freeform_tags = local.freeform_tags
}

{%- endif %}


###############################################################################
# Hosted application invoke URLs
#
# Equivalent to the old Container Instance private IP destinations.
###############################################################################

locals {
  hosted_application_base_url = "https://inference.generativeai.${var.region}.oci.oraclecloud.com/20251112/hostedApplications"

  hosted_rest_invoke_url = "${local.hosted_application_base_url}/${oci_generative_ai_hosted_application.starter_rest_hosted_application.id}/actions/invoke"

  hosted_ui_invoke_url = "${local.hosted_application_base_url}/${oci_generative_ai_hosted_application.starter_ui_hosted_application.id}/actions/invoke"

{%- if python_framework in [ "langgraph", "responses" ] %}
  hosted_mcp_invoke_url = "${local.hosted_application_base_url}/${oci_generative_ai_hosted_application.starter_mcp_hosted_application.id}/actions/invoke"
{%- endif %}
}


###############################################################################
# API Gateway
###############################################################################

resource "oci_apigateway_deployment" "starter_apigw_deployment" {
{%- if tls is defined %}
  count = var.certificate_ocid == null ? 0 : 1
{%- endif %}

  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-apigw-deployment"
  gateway_id     = local.apigw_ocid
  path_prefix    = "/${var.prefix}"

  specification {
    logging_policies {
      access_log {
        is_enabled = true
      }

      execution_log {
        is_enabled = true
      }
    }

    #########################################################################
    # REST
    #
    # Old:
    # /app/* -> REST container
    #
    # New:
    # /app/* -> REST hosted application
    #########################################################################

    routes {
      path    = "/app/{pathname*}"
      methods = ["ANY"]

      backend {
        type = "HTTP_BACKEND"
        url  = "${local.hosted_rest_invoke_url}/$${request.path[pathname]}"
      }
    }

{%- if python_framework in [ "langgraph", "responses" ] %}

    #########################################################################
    # MCP
    #
    # Old:
    # http://<container-private-ip>:2025/*
    #
    # New:
    # Hosted MCP application /*
    #########################################################################

    routes {
      path    = "/mcp_server/{pathname*}"
      methods = ["ANY"]

      backend {
        type = "HTTP_BACKEND"
        url  = "${local.hosted_mcp_invoke_url}/$${request.path[pathname]}"
      }
    }

{%- endif %}

    #########################################################################
    # UI
    #
    # Old:
    # http://<container-private-ip>/*
    #
    # New:
    # UI hosted application /*
    #########################################################################

    routes {
      path    = "/{pathname*}"
      methods = ["ANY"]

      backend {
        type = "HTTP_BACKEND"
        url  = "${local.hosted_ui_invoke_url}/$${request.path[pathname]}"
      }
    }
  }

  freeform_tags = local.api_tags

  depends_on = [
    oci_generative_ai_hosted_deployment.starter_rest_hosted_deployment,
    oci_generative_ai_hosted_deployment.starter_ui_hosted_deployment,
{%- if python_framework in [ "langgraph", "responses" ] %}
    oci_generative_ai_hosted_deployment.starter_mcp_hosted_deployment,
{%- endif %}
  ]
}


###############################################################################
# Optional data sources
###############################################################################

data "oci_generative_ai_hosted_deployments" "starter_rest_hosted_deployments" {
  compartment_id = local.lz_app_cmp_ocid
  application_id = oci_generative_ai_hosted_application.starter_rest_hosted_application.id
  id             = oci_generative_ai_hosted_deployment.starter_rest_hosted_deployment.id
  state          = "ACTIVE"
}

data "oci_generative_ai_hosted_deployments" "starter_ui_hosted_deployments" {
  compartment_id = local.lz_app_cmp_ocid
  application_id = oci_generative_ai_hosted_application.starter_ui_hosted_application.id
  id             = oci_generative_ai_hosted_deployment.starter_ui_hosted_deployment.id
  state          = "ACTIVE"
}

{%- if python_framework in [ "langgraph", "responses" ] %}

data "oci_generative_ai_hosted_deployments" "starter_mcp_hosted_deployments" {
  compartment_id = local.lz_app_cmp_ocid
  application_id = oci_generative_ai_hosted_application.starter_mcp_hosted_application.id
  id             = oci_generative_ai_hosted_deployment.starter_mcp_hosted_deployment.id
  state          = "ACTIVE"
}

{%- endif %}