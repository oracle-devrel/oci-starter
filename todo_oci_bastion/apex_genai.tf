#-- IDCS_URL ----------------------------------------------------------
/*
variable idcs_domain_name { default = "Default" }
variable idcs_url { default = "" }

data "oci_identity_domains" "starter_domains" {
    #Required
    compartment_id = var.tenancy_ocid
    display_name = var.idcs_domain_name
}

locals {
  idcs_url = (var.idcs_url!="")?var.idcs_url:data.oci_identity_domains.starter_domains.domains[0].url
}

#-- Object Storage ----------------------------------------------------------

# Object Storage
variable "namespace" {}

resource "oci_objectstorage_bucket" "starter_bucket" {
  compartment_id = local.lz_serv_cmp_ocid
  namespace      = var.namespace
  name           = "${var.prefix}-public-bucket"
  access_type    = "ObjectReadWithoutList"
  object_events_enabled = true

  freeform_tags = local.freeform_tags
}

locals {
  bucket_url = "https://objectstorage.${var.region}.oraclecloud.com/n/${var.namespace}/b/${var.prefix}-public-bucket/o"
}  

resource "oci_identity_domains_dynamic_resource_group" "starter-adb-dyngroup" {
    #Required
    provider       = oci.home    
    display_name = "${var.prefix}-adb-dyngroup"
    idcs_endpoint = local.idcs_url
    matching_rule = "ANY{ resource.id = '${oci_database_autonomous_database.starter_atp.id}' }"
    schemas = ["urn:ietf:params:scim:schemas:oracle:idcs:DynamicResourceGroup"]
}

resource "oci_identity_domains_dynamic_resource_group" "starter-compute-dyngroup" {
    #Required
    provider       = oci.home    
    display_name = "${var.prefix}-compute-dyngroup"
    idcs_endpoint = local.idcs_url
    matching_rule = "ANY{ instance.compartment.id = '${local.lz_app_cmp_ocid}' }"
    schemas = ["urn:ietf:params:scim:schemas:oracle:idcs:DynamicResourceGroup"]
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [ oci_identity_domains_dynamic_resource_group.starter-adb-dyngroup, oci_identity_domains_dynamic_resource_group.starter-compute-dyngroup ]
  create_duration = "30s"
}

resource "oci_identity_policy" "starter-adb-policy" {
    provider       = oci.home    
    depends_on     = [ time_sleep.wait_30_seconds ]
    name           = "${var.prefix}-adb-policy"
    description    = "${var.prefix} adb policy"
    compartment_id = local.lz_app_cmp_ocid

    statements = [
        "Allow dynamic-group ${var.idcs_domain_name}/${var.prefix}-adb-dyngroup to manage generative-ai-family in compartment id ${var.compartment_ocid}"
    ]
}

resource "oci_identity_policy" "starter-compute-policy" {
    provider       = oci.home    
    depends_on     = [ time_sleep.wait_30_seconds ]
    name           = "${var.prefix}-compute-policy"
    description    = "${var.prefix} compute policy"
    compartment_id = local.lz_app_cmp_ocid

    statements = [
        "Allow dynamic-group ${var.idcs_domain_name}/${var.prefix}-compute-dyngroup to manage generative-ai-family in compartment id ${var.compartment_ocid}"
    ]
}
*/

// WA: ADB Dynamic group does not work above (instance does) 
// WA for the ORA-20404: Object not found - https://inference.generativeai.eu-frankfurt-1.oci.oraclecloud.com/20231130/actions/embedText 
resource "oci_identity_policy" "starter-policy" {
    provider       = oci.home    
    name           = "${var.prefix}-policy"
    description    = "${var.prefix} policy"
    compartment_id = local.lz_app_cmp_ocid

    statements = [
        "Allow any-user to use generative-ai-family in compartment id ${var.compartment_ocid}"
    ]
}

#-- API Gateway Private --------------------------------------------------

resource oci_apigateway_gateway starter_apigw_private {
  compartment_id = local.lz_app_cmp_ocid
  display_name  = "${var.prefix}-apigw-private"
  endpoint_type = "PRIVATE" 
  subnet_id = data.oci_core_subnet.starter_app_subnet.id
  freeform_tags = local.freeform_tags       
}

resource "oci_apigateway_deployment" "starter_apigw_private_deployment" {   
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-apigw-private-deployment"
  gateway_id     = oci_apigateway_gateway.starter_apigw_private.id
  path_prefix    = "/cohere"
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
      path    = "/generate"
      methods = [ "ANY" ]
      backend {
        type = "HTTP_BACKEND"
        url    = "http://${data.oci_core_instance.starter_bastion.private_ip}:3000/cohere/generate"
        connect_timeout_in_seconds = 10
        read_timeout_in_seconds = 30
        send_timeout_in_seconds = 30        
      }
    }      
  }
}

#-- API Gateway Public ----------------------------------------------------

resource oci_apigateway_gateway starter_apigw {
  compartment_id = local.lz_app_cmp_ocid
  display_name  = "${var.prefix}-apigw-public"
  endpoint_type = "PUBLIC"
  subnet_id = data.oci_core_subnet.starter_web_subnet.id
  freeform_tags = local.freeform_tags       
}

locals {
  apigw_ocid = try(oci_apigateway_gateway.starter_apigw.id, "")
  apigw_ip   = try(oci_apigateway_gateway.starter_apigw.ip_addresses[0].ip_address,"")
}   

resource "oci_apigateway_deployment" "starter_apigw_public_deployment" {   
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-apigw-public-deployment"
  gateway_id     = oci_apigateway_gateway.starter_apigw.id
  path_prefix    = "/"
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
      path    = "/"
      methods = [ "ANY" ]
      backend {
        type = "HTTP_BACKEND"
        url    = "http://${data.oci_core_instance.starter_bastion.private_ip}/"
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
        url    = "http://${data.oci_core_instance.starter_bastion.private_ip}/$${request.path[pathname]}"
      }
    }
  }       
}

#-- Bastion ----------------------------------------------------

resource "oci_bastion_bastion" "starter_bastion" {
  name = "${var.prefix}-bastion"
  bastion_type     = "STANDARD"
  compartment_id   = var.compartment_ocid
  target_subnet_id =  data.oci_core_subnet.starter_app_subnet.id
  freeform_tags = local.freeform_tags      
  client_cidr_block_allow_list = [
    "0.0.0.0/0"
  ]
}

resource "oci_bastion_session" "starter_bastion_session" {
  bastion_id = oci_bastion_bastion.starter_bastion.id
  key_details {
      public_key_content = var.ssh_public_key
  }

  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id = data.oci_core_instance.starter_compute.id
    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = "22"
  }
  key_type = "PUB"
  session_ttl_in_seconds = 3600
  display_name = "${var.prefix}-bastion-session"
}

output "bastion_command" {
  value = oci_bastion_session.starter_bastion_session.ssh_metadata.command
}

//---- Load Balancer -------------------------------------------------------

resource "oci_load_balancer" "starter_pool_lb" {
  shape          = "flexible"
  compartment_id = local.lz_app_cmp_ocid
  subnet_ids = [ data.oci_core_subnet.starter_web_subnet.id ]
  shape_details {
    #Required
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 100
  }

  display_name ="${var.prefix}-pool-lb"
}

resource "oci_load_balancer_backend_set" "starter_pool_backend_set" {
  name             = "${substr(var.prefix,0,8)}-pool-bes"
  load_balancer_id = oci_load_balancer.starter_pool_lb.id
  policy           = "ROUND_ROBIN"

  health_checker {
    port                = "443"
    protocol            = "HTTPS"
    response_body_regex = ".*"
    url_path            = "/ords"
  }
}

resource "oci_load_balancer_backend" "starter_pool_backend" {
  load_balancer_id = "${oci_load_balancer.starter_pool_lb.id}"

  //backendset_name  = "${oci_load_balancer_backend_set.lb-bes-https.name}"
  backendset_name = oci_load_balancer_backend_set.starter_pool_backend_set.name
  ip_address      = data.oci_database_autonomous_database.starter_atp.private_endpoint_ip
  port            = 443
  backup          = false
  drain           = false
  offline         = false
  weight          = 1
}

resource "oci_load_balancer_listener" "starter_lb_https_listener" {
  load_balancer_id         = oci_load_balancer.starter_pool_lb.id
  name                     = "HTTP-443"
  default_backend_set_name = oci_load_balancer_backend_set.starter_pool_backend_set.name
  port = 443
  protocol = "HTTP"

  ssl_configuration {
    certificate_ids = [ var.certificate_ocid ]
    cipher_suite_name = "oci-wider-compatible-ssl-cipher-suite-v1"
    protocols =  [
        "TLSv1",
        "TLSv1.1",
        "TLSv1.2"
    ]
    server_order_preference = "ENABLED"
    verify_depth = 1
    verify_peer_certificate = false
  }
}

