variable ingress_ip {
  description = "Kubernetes Ingress IP"  
  default=null 
}

resource "oci_apigateway_deployment" "starter_apigw_deployment" {
  count = var.ingress_ip == null ? 0 : 1
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-apigw-deployment"
  gateway_id     = local.apigw_ocid
  path_prefix    = "/"
  specification {
    routes {
      path    = "/{pathname*}"
      methods = [ "ANY" ]
      backend {
        type = "HTTP_BACKEND"
        url    = "http://${var.ingress_ip}/$${request.path[pathname]}"
      }
    }     
  }
  freeform_tags = local.api_tags
}