variable apigw_ocid { default="" }

locals {
  apigw_ocid = var.apigw_ocid
}


data "oci_apigateway_gateway" "starter_apigw" {
    #Required
    count = var.apigw_ocid=="" ? 0 : 1
    gateway_id = var.apigw_ocid
}


