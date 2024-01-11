locals {
  apigw_dest_private_ip = local.compute_private_ip
}

resource "oci_apigateway_deployment" "starter_apigw_deployment" {
  compartment_id = local.lz_appdev_cmp_ocid
  display_name   = "${var.prefix}-apigw-deployment"
  gateway_id     = local.apigw_ocid
  path_prefix    = "/${var.prefix}"
  specification {
    routes {
      path    = "/app/{pathname*}"
      methods = [ "ANY" ]
      backend {
        type = "HTTP_BACKEND"
        url    = "##APP_URL##"
      }
    } 
    routes {
      path    = "/{pathname*}"
      methods = [ "ANY" ]
      backend {
        type = "HTTP_BACKEND"
        url    = "http://${local.apigw_dest_private_ip}/$${request.path[pathname]}"
      }
    }        
  }
  freeform_tags = local.api_tags
}

/*
resource oci_logging_log starter_apigw_deployment_execution {
  count = var.log_group_ocid == "" ? 0 : 1
  log_group_id = var.log_group_ocid
  configuration {
    compartment_id = local.lz_appdev_cmp_ocid
    source {
      category    = "execution"
      resource    = oci_apigateway_deployment.starter_apigw_deployment.id
      service     = "apigateway"
      source_type = "OCISERVICE"
    }
  }
  display_name = "${var.prefix}-apigw-deployment-execution"
  freeform_tags = local.freeform_tags
  is_enabled         = "true"
  log_type           = "SERVICE"
  retention_duration = "30"
}

resource oci_logging_log starter_apigw_deployment_access {
  count = var.log_group_ocid == "" ? 0 : 1
  log_group_id = var.log_group_ocid
  configuration {
    compartment_id = local.lz_appdev_cmp_ocid
    source {
      category    = "access"
      resource    = oci_apigateway_deployment.starter_apigw_deployment.id
      service     = "apigateway"
      source_type = "OCISERVICE"
    }
  }
  display_name = "${var.prefix}-apigw-deployment-access"
  freeform_tags = local.freeform_tags
  is_enabled         = "true"
  log_type           = "SERVICE"
  retention_duration = "30"
}
*/