variable "dns_zone_name" { default="" }
variable "dns_name" { default="" }
variable "dns_ip" { default="" }

locals {
{%- if deploy == "compute" %}  
  dns_ip = local.compute_ip
{%- elif deploy == "instance_pool" %}  
  dns_ip = local.instance_pool_lb_ip
{%- else %}  
  dns_ip = local.apigw_ip
{%- endif %}       
}

resource "oci_dns_rrset" "starter_rrset" {
    count = var.dns_zone_name=="" ? 0 : 1

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
resource "oci_load_balancer_listener" "test_listener" {
    #Required
  count                    = var.certificate_ocid=="" ? 0 : 1
  load_balancer_id         = oci_load_balancer.starter_pool_lb.id
  name                     = "TCP-443"
  default_backend_set_name = oci_load_balancer_backend_set.starter_pool_backend_set.name
  port = 443
  protocol = "TCP"

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
{%- endif %}