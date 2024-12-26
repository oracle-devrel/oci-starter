
{%- if language == "apex" %}
locals {
  db_root_url = replace(data.oci_database_autonomous_database.starter_atp.connection_urls[0].apex_url, "/ords/apex", "" )
}
{%- else %}
# Used for APIGW and TAGS
locals {
  apigw_dest_private_ip = local.compute_private_ip
}
{%- endif %}

{%- if language == "apex" %}

# One single entry "/" would work too. 
# The reason of the 3 entries is to allow to make it work when the APIGW is shared with other URLs (ex: testsuite)
resource "oci_apigateway_deployment" "starter_apigw_deployment_ords" {
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-apigw-deployment"
  gateway_id     = local.apigw_ocid
  path_prefix    = "/ords"
  specification {
    # Go directly from APIGW to APEX in the DB    
    routes {
      path    = "/{pathname*}"
      methods = [ "ANY" ]
      backend {
        type = "HTTP_BACKEND"
        url    = "${local.db_root_url}/ords/$${request.path[pathname]}"
        connect_timeout_in_seconds = 60
        read_timeout_in_seconds = 120
        send_timeout_in_seconds = 120            
      }
      request_policies {
        header_transformations {
          set_headers {
            items {
              name = "Host"
              values = ["$${request.headers[Host]}"]
            }
          }
        }
      }
    }
  }
  freeform_tags = local.api_tags
}

resource "oci_apigateway_deployment" "starter_apigw_deployment_i" {
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-apigw-deployment"
  gateway_id     = local.apigw_ocid
  path_prefix    = "/i"
  specification {
    # Go directly from APIGW to APEX in the DB    
    routes {
      path    = "/{pathname*}"
      methods = [ "ANY" ]
      backend {
        type = "HTTP_BACKEND"
        url    = "${local.db_root_url}/i/$${request.path[pathname]}"
        connect_timeout_in_seconds = 60
        read_timeout_in_seconds = 120
        send_timeout_in_seconds = 120            
      }
      request_policies {
        header_transformations {
          set_headers {
            items {
              name = "Host"
              values = ["$${request.headers[Host]}"]
            }
          }
        }
      }
    }
  }
  freeform_tags = local.api_tags
}

resource "oci_apigateway_deployment" "starter_apigw_deployment_app" {
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-apigw-deployment"
  gateway_id     = local.apigw_ocid
  path_prefix    ="/${var.prefix}"
  specification {
    # Go directly from APIGW to APEX in the DB    
    routes {
      path    = "/{pathname*}"
      methods = [ "ANY" ]
      backend {
        type = "HTTP_BACKEND"
        url    = "${local.db_root_url}/ords/r/apex_app/apex_app"
        connect_timeout_in_seconds = 60
        read_timeout_in_seconds = 120
        send_timeout_in_seconds = 120            
      }
      request_policies {
        header_transformations {
          set_headers {
            items {
              name = "Host"
              values = ["$${request.headers[Host]}"]
            }
          }
        }
      }
    }
  }
  freeform_tags = local.api_tags
}   


{%- else %}
resource "oci_apigateway_deployment" "starter_apigw_deployment" {
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-apigw-deployment"
  gateway_id     = local.apigw_ocid
  path_prefix    = "/${var.prefix}"
  specification {
    # Route the COMPUTE_PRIVATE_IP 
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

{%- if security == "openid" %}     
    request_policies {
      authentication {
        type = "TOKEN_AUTHENTICATION"
        token_header = "Authorization"
        token_auth_scheme = "Bearer"
        is_anonymous_access_allowed = false
        validation_policy {
          // Example validation policy using an OAuth2 introspection endpoint
          // (https://datatracker.ietf.org/doc/html/rfc7662) to validate the
          // clients authorization credentials
          type = "REMOTE_DISCOVERY"
          is_ssl_verify_disabled = true
          max_cache_duration_in_hours = 1
          source_uri_details {
            // Discover the OAuth2/OpenID configuration from an RFC8414
            // metadata endpoint (https://www.rfc-editor.org/rfc/rfc8414)
            type = "DISCOVERY_URI"
            uri = "${IDCS_URL}/.well-known/openid-configuration"
          }
          client_details {
            // Specify the OAuth client id and secret to use with the
            // introspection endpoint
            type = "CUSTOM"
            client_id = var.client_id
            client_secret_id = oci_vault_secret.starter_openid_secret.id
            client_secret_version_number = var.client_secret_version_number
          }
        }
        validation_failure_policy {
          // When a client uses the API without auth credentials, or
          // invalid/expired credentials then invoke the OAuth2 flow using
          // the configuration below.
          type = "OAUTH2"
          scopes = ["openid"]
          response_type = "CODE"
          max_expiry_duration_in_hours = 1
          use_cookies_for_intermediate_steps = true
          use_cookies_for_session = true
          use_pkce = true
          fallback_redirect_path = "/fallback"
          source_uri_details {
            // Use the same discovery URI as the validation policy above.
            type = "VALIDATION_BLOCK"
          }
          client_details {
            // Use the same OAuth2 client details as the validation policy above.
            type = "VALIDATION_BLOCK"
          }
        }
      }
    }  
{%- endif %}      
  }
  freeform_tags = local.api_tags
}    
{%- endif %}      

/*
resource oci_logging_log starter_apigw_deployment_execution {
  count = var.log_group_ocid == "" ? 0 : 1
  log_group_id = var.log_group_ocid
  configuration {
    compartment_id = local.lz_app_cmp_ocid
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
    compartment_id = local.lz_app_cmp_ocid
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