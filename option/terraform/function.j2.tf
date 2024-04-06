{%- if fnapp_ocid is defined %}
variable fnapp_ocid {}

data "oci_functions_application" "test_application" {
    #Required
    application_id = var.fnapp_ocid
}

locals {
  fnapp_ocid = var.fnapp_ocid
}

{%- else %}   
resource "oci_functions_application" "starter_fn_application" {
  #Required
  compartment_id = local.lz_appdev_cmp_ocid
  display_name   = "${var.prefix}-fn-application"
  subnet_ids     = [data.oci_core_subnet.starter_private_subnet.id]
  {%- if shape == "ampere" %}
  shape          = "GENERIC_ARM"   
  {%- endif %}

  image_policy_config {
    #Required
    is_policy_enabled = false
  }

  freeform_tags = local.freeform_tags
}

resource oci_logging_log export_starter_fn_application_invoke {
  configuration {
    compartment_id = local.lz_security_cmp_ocid
    source {
      category    = "invoke"
      resource    = local.fnapp_ocid
      service     = "functions"
      source_type = "OCISERVICE"
    }
  }
  display_name       = "starter-fn-application-invoke"
  is_enabled         = "true"
  log_group_id       = oci_logging_log_group.starter_log_group.id
  log_type           = "SERVICE"
  retention_duration = "30"

  freeform_tags = local.freeform_tags
}

locals {
  fnapp_ocid = oci_functions_application.starter_fn_application.id
}
{%- endif %}

{%- if group_name is not defined %}
variable "fn_image" { default = "" }
variable "fn_db_url" { default = "" }
{%- if db_type == "nosql" %} 
variable nosql_endpoint {}
{%- endif %} 

resource "oci_functions_function" "starter_fn_function" {
  #Required
  count          = var.fn_image == "" ? 0 : 1
  application_id = local.fnapp_ocid
  display_name   = "${var.prefix}-fn-function"
  image          = var.fn_image
  memory_in_mbs  = "2048"
  config = {
    {%- if language == "java" %} 
    JDBC_URL      = var.fn_db_url,
    {%- else %}     
    DB_URL      = var.fn_db_url,
    {%- endif %}     
    DB_USER     = var.db_user,
    DB_PASSWORD = var.db_password,
    {%- if db_type == "nosql" %} 
    TF_VAR_compartment_ocid = var.compartment_ocid,
    TF_VAR_nosql_endpoint = var.nosql_endpoint,
    {%- endif %}     
  }
  #Optional
  timeout_in_seconds = "300"
  trace_config {
    is_enabled = true
  }

  freeform_tags = local.freeform_tags
/*
  # To start faster
  provisioned_concurrency_config {
    strategy = "CONSTANT"
    count = 40
  }
*/    
}

output "fn_url" {
  value = join("", oci_apigateway_deployment.starter_apigw_deployment.*.endpoint)
}

resource "oci_identity_policy" "starter_fn_policy" {
  provider       = oci.home    
  name           = "${var.prefix}-fn-policy"
  description    = "APIGW access Function"
  compartment_id = local.lz_appdev_cmp_ocid
  statements = [
    # "ALLOW any-user to use functions-family in compartment id ${local.lz_appdev_cmp_ocid} where ALL {request.principal.type= 'ApiGateway', request.resource.compartment.id = '${local.lz_appdev_cmp_ocid}'}"
    "ALLOW any-user to use functions-family in compartment id ${local.lz_appdev_cmp_ocid} where ALL {request.principal.type= 'ApiGateway'}"
  ]

  freeform_tags = local.freeform_tags
}

#-- Object Storage ----------------------------------------------------------

# Object Storage
variable "namespace" {}

resource "oci_objectstorage_bucket" "starter_bucket" {
  compartment_id = local.lz_security_cmp_ocid
  namespace      = var.namespace
  name           = "${var.prefix}-public-bucket"
  access_type    = "ObjectReadWithoutList"
  object_events_enabled = true

  freeform_tags = local.freeform_tags
}

locals {
  bucket_url = "https://objectstorage.${var.region}.oraclecloud.com/n/${var.namespace}/b/${var.prefix}-public-bucket/o"
}
{%- endif %}  
