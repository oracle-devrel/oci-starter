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
  count = var.certificate_ocid == "" ? 0 : 1
  certificate_id = var.certificate_ocid
{%- endif %}       
}

resource "oci_apigateway_api" "starter_api" {
  compartment_id = local.lz_appdev_cmp_ocid
  content       = var.openapi_spec
  display_name  = "${var.prefix}-api"
  freeform_tags = local.freeform_tags   

{%- if tls is defined %}
  count = var.certificate_ocid == "" ? 0 : 1
{%- endif %}       
}

locals {
  apigw_ocid = oci_apigateway_gateway.starter_apigw[0].id
  apigw_ip   = oci_apigateway_gateway.starter_apigw[0].ip_addresses[0].ip_address
}
