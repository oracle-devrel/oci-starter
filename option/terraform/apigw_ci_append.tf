locals {
  apigw_dest_private_ip = try(oci_container_instances_container_instance.starter_container_instance[0].vnics[0].private_ip, "")
}

resource "oci_apigateway_deployment" "starter_apigw_deployment" {
{%- if tls is defined %}
  count = (var.docker_image_ui == "" || var.certificate_ocid == "") ? 0 : 1
{%- else %}   
  count = var.docker_image_ui == "" ? 0 : 1
{%- endif %}   
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

