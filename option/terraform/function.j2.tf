{%- if fnapp_ocid is defined %}
variable fnapp_ocid {
  description = "Existing Function Application OCID" 
}

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
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-fn-application"
  subnet_ids     = [data.oci_core_subnet.starter_app_subnet.id]
  shape          = startswith(var.instance_shape, "VM.Standard.A") ? "GENERIC_ARM" : "GENERIC_X86"

  image_policy_config {
    #Required
    is_policy_enabled = false
  }

  freeform_tags = local.freeform_tags
}

resource oci_logging_log export_starter_fn_application_invoke {
  configuration {
    compartment_id = local.lz_serv_cmp_ocid
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
variable "fn_image" { 
  default = null 
  description = "OCI Function Docker Image Name"
}

output "fn_url" {
  value = join("", oci_apigateway_deployment.starter_apigw_deployment.*.endpoint)
}

resource "oci_identity_policy" "starter_fn_policy" {
  provider       = oci.home    
  name           = "${var.prefix}-fn-policy"
  description    = "APIGW access Function"
  compartment_id = local.lz_app_cmp_ocid
  statements = [
    # "ALLOW any-user to use functions-family in compartment id ${local.lz_app_cmp_ocid} where ALL {request.principal.type= 'ApiGateway', request.resource.compartment.id = '${local.lz_app_cmp_ocid}'}"
    "ALLOW any-user to use functions-family in compartment id ${local.lz_app_cmp_ocid} where ALL {request.principal.type= 'ApiGateway'}"
  ]

  freeform_tags = local.freeform_tags
}

#-- Object Storage ----------------------------------------------------------

# Object Storage
variable "namespace" {
  description = "OCI Object Storage Namespace"
}

resource "oci_objectstorage_bucket" "starter_bucket" {
  compartment_id = local.lz_serv_cmp_ocid
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
