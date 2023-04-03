locals {
  apigw_dest_private_ip = oci_core_instance.starter_instance.private_ip
}

resource "oci_apigateway_deployment" "starter_apigw_deployment" {
  compartment_id = local.lz_appdev_cmp_ocid
  display_name   = "${var.prefix}-apigw-deployment"
  gateway_id     = local.apigw_ocid
  path_prefix    = "/${var.prefix}"
  specification {
    logging_policies {
      access_log {
        is_enabled = true
      }
      execution_log {
        #Optional
        is_enabled = true
      }
    }
    routes {
      path    = "/app/{pathname*}"
      methods = [ "ANY" ]
      backend {
        type = "HTTP_BACKEND"
        url    = "##APP_URL##"
      }
    }     
  }
  freeform_tags = local.api_tags
}

