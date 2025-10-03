# TLS
variable "dns_zone_name" { 
  default=null 
  description = "SSL/TLS - DNS Zone Name"  
}
variable "dns_name" { 
  default=null 
  description = "SSL/TLS - DNS Name"  
}
variable "dns_ip" { 
  default=null
  description = "SSL/TLS - IP associated with the DNS Name"  
}
variable "certificate_email" { 
  default=null
  description = "SSL/TLS - Email used to create the certificate"  
}

locals {
{%- if deploy_type == "public_compute" and tls != "existing_ocid" %}  
  dns_ip = local.compute_public_ip
{%- elif deploy_type == "instance_pool" %}  
  dns_ip = local.local_instance_pool_lb_ip
{%- elif deploy_type == "kubernetes" and tls == "new_http_01" %}
# No Locals
{%- else %}  
  dns_ip = local.apigw_ip
{%- endif %}       
}

{%- if deploy_type == "kubernetes" and tls == "new_http_01" %}
{%- if oke_ocid is defined %}
# Policy defined in group_common
{%- else %}
# Todo: Better use Workload Access Principal - https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contenggrantingworkloadaccesstoresources.htm

resource "oci_identity_policy" "oke_tls_policy" {
  provider       = oci.home    
  name           = "oke-tls-policy"
  description    = "oke-tls-policy"
  compartment_id = var.compartment_ocid

  statements = [
    # "Allow any-user to manage dns in compartment id ${var.compartment_ocid} where instance.compartment.id='${var.compartment_ocid}'",
    "Allow any-user to manage dns in compartment id ${var.compartment_ocid}",
    "Allow any-user to manage dns in compartment id ${var.compartment_ocid} where all {request.principal.type='workload',request.principal.cluster_id='${local.local_oke_ocid}',request.principal.service_account='external-dns'}"
  ]
}
{%- endif %}
{%- else %}  
resource "oci_dns_rrset" "starter_rrset" {
    # XXXX Advanced case with DNS not in OCI XXXX ?
    count = var.dns_zone_name==null ? 0 : 1

    #Required
    zone_name_or_id = var.dns_zone_name
    domain = var.dns_name
    rtype  = "A"
    compartment_id = local.lz_app_cmp_ocid
    items {
        #Required
        domain = var.dns_name
        rdata = var.dns_ip==null ? local.dns_ip : var.dns_ip
        rtype = "A"
        ttl = 300
    }
}
{%- endif %}       

{%- if deploy_type == "instance_pool" %}  
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
{%- endif %}



