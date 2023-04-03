variable apigw_ocid {}

data "oci_apigateway_gateway" "starter_apigw" {
    #Required
    gateway_id = var.apigw_ocid
}

locals {
  apigw_ocid = var.apigw_ocid
}

