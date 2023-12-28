variable "dns_zone_name" { default="" }
variable "dns_name" { default="" }
variable "dns_ip" { default="" }

locals {
{%- if deploy == "compute" %}  
  dns_ip = local.compute_public_ip
{%- elif deploy == "instance_pool" %}  
  dns_ip = local.instance_pool_lb_ip
{%- else %}  
  dns_ip = local.apigw_ip
{%- endif %}       
}

resource "oci_dns_rrset" "starter_rrset" {
{%- if deploy == "kubernetes" %}
    count = var.dns_ip=="" ? 0 : 1
{%- else %}  
    count = var.dns_zone_name=="" ? 0 : 1
{%- endif %}       

    #Required
    zone_name_or_id = var.dns_zone_name
    domain = var.dns_name
    rtype  = "A"
    compartment_id = local.lz_appdev_cmp_ocid
    items {
        #Required
        domain = var.dns_name
        rdata = var.dns_ip=="" ? local.dns_ip : var.dns_ip
        rtype = "A"
        ttl = 300
    }
}

{%- if deploy == "instance_pool" %}  
resource "oci_load_balancer_listener" "starter-lb-https-listener" {
    #Required
  count                    = var.certificate_ocid=="" ? 0 : 1
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

{%- if tls == "new" %}  
resource oci_load_balancer_backend_set starter-bastion-bes {
  health_checker {
    protocol       = "HTTP"
    url_path       = "/"
  }
  load_balancer_id = oci_load_balancer.starter_pool_lb.id
  name             = "${var.prefix}-bastion-bes"
  policy           = "ROUND_ROBIN"
}

resource oci_load_balancer_backend starter-bastion-be {
  load_balancer_id = oci_load_balancer.starter_pool_lb.id
  backendset_name  = oci_load_balancer_backend_set.starter-bastion-bes.name
  ip_address       = oci_core_instance.starter_bastion.private_ip 
  port             = "80"
  weight           = "1"
}

resource oci_load_balancer_path_route_set starter-bastion-routeset {
  load_balancer_id = oci_load_balancer.starter_pool_lb.id
  name             = "${var.prefix}-bastion-routeset"
  path_routes {
    backend_set_name = oci_load_balancer_backend_set.starter-bastion-bes.name
    path             = "/.well-known/acme-challenge"
    path_match_type {
      match_type = "PREFIX_MATCH"
    }
  }
}
{%- endif %}

{%- endif %}



