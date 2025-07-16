locals {
  fn_image=data.external.env_part2.result.fn_image
}

resource "oci_functions_function" "starter_fn_function" {
  #Required
  application_id = local.fnapp_ocid
  display_name   = "${var.prefix}-fn-function"
  image          = local.fn_image
  memory_in_mbs  = "2048"
  config = {
    {%- if language == "java" %} 
    JDBC_URL      = var.fn_db_url,
    {%- else %}     
    DB_URL      = var.fn_db_url,
    {%- endif %}     
    DB_USER     = var.db_user,
    DB_PASSWORD = var.db_password,
    {%- if db_type == "nosql" %} 
    TF_VAR_compartment_ocid = var.compartment_ocid,
    TF_VAR_nosql_endpoint = var.nosql_endpoint,
    {%- endif %}     
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
   depends_on = [ "local.fn_image" ]
}

resource "oci_apigateway_deployment" "starter_apigw_deployment" {
{%- if tls is defined %}
  count = (local.fn_image == null || var.certificate_ocid == null) ? 0 : 1
{%- endif %}   
  compartment_id = local.lz_app_cmp_ocid
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
        type = "ORACLE_FUNCTIONS_BACKEND"
        function_id   = oci_functions_function.starter_fn_function[0].id
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

  depends_on = [ "local.fn_image" ]
}