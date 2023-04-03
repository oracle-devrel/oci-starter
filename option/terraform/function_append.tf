variable "fn_image" { default = "" }
variable "fn_db_url" { default = "" }

resource "oci_functions_function" "starter_fn_function" {
  #Required
  count          = var.fn_image == "" ? 0 : 1
  application_id = local.fnapp_ocid
  display_name   = "${var.prefix}-fn-function"
  image          = var.fn_image
  memory_in_mbs  = "2048"
  config = {
    DB_URL      = var.fn_db_url,
    DB_USER     = var.db_user,
    DB_PASSWORD = var.db_password,
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

  freeform_tags = local.freeform_tags
}

locals {
  bucket_url = "https://objectstorage.${var.region}.oraclecloud.com/n/${var.namespace}/b/${var.prefix}-public-bucket/o"
}

