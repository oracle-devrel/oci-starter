{%- if apigw_ocid is defined %}
variable apigw_ocid {}

data "oci_apigateway_gateway" "starter_apigw" {
    #Required
    gateway_id = var.apigw_ocid
}

locals {
  apigw_ocid = var.apigw_ocid
  apigw_ip   = try(data.oci_apigateway_gateway.starter_apigw.ip_addresses[0].ip_address,"")
}

{%- else %}   
variable "openapi_spec" {
  default = "openapi: 3.0.0\ninfo:\n  version: 1.0.0\n  title: Test API\n  license:\n    name: MIT\npaths:\n  /ping:\n    get:\n      responses:\n        '200':\n          description: OK"
}

resource oci_apigateway_gateway starter_apigw {
  compartment_id = local.lz_appdev_cmp_ocid
  display_name  = "${var.prefix}-apigw"
  endpoint_type = "PUBLIC"
  subnet_id = data.oci_core_subnet.starter_public_subnet.id
  freeform_tags = local.freeform_tags

{%- if tls is defined %}
  certificate_id = var.certificate_ocid
{%- endif %}       
}

resource "oci_apigateway_api" "starter_api" {
  compartment_id = local.lz_appdev_cmp_ocid
  content       = var.openapi_spec
  display_name  = "${var.prefix}-api"
  freeform_tags = local.freeform_tags   
}

locals {
  apigw_ocid = try(oci_apigateway_gateway.starter_apigw.id, "")
  apigw_ip   = try(oci_apigateway_gateway.starter_apigw.ip_addresses[0].ip_address,"")
}
{%- endif %}   

// API Management - Tags
variable git_url { default = "" }

locals {
  api_git_tags = {
      group = local.group_name
      app_prefix = var.prefix

      api_icon = var.language
      api_git_url = var.git_url 
      api_git_spec_path = "src/app/openapi_spec.yaml"
      api_git_spec_type = "OpenAPI"
      api_git_endpoint_path = "src/terraform/apigw_existing.tf"
      api_endpoint_url = "app/dept"
  }
  api_tags = var.git_url !=""? local.api_git_tags:local.freeform_tags
}

