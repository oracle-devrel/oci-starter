
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
      path    = "/app/dept"
      methods = [ "ANY" ]
      backend {
        type = "HTTP_BACKEND"
        url   = format("%s/starter/module/dept", local.ords_url)
      }
    }    
    routes {
      path    = "/app/info"
      methods = [ "ANY" ]
      backend {
        type = "STOCK_RESPONSE_BACKEND"
        body   = "Function ${var.language}"
        status = 200
      }
    }    
    routes {
      path    = "/"
      methods = [ "ANY" ]
      backend {
        type = "HTTP_BACKEND"
        url    = "${local.bucket_url}/index.html"
        connect_timeout_in_seconds = 10
        read_timeout_in_seconds = 30
        send_timeout_in_seconds = 30
      }
    }    
    routes {
      path    = "/{pathname*}"
      methods = [ "ANY" ]
      backend {
        type = "HTTP_BACKEND"
        url    = "${local.bucket_url}/$${request.path[pathname]}"
      }
    }
  }
  freeform_tags = local.api_tags
}