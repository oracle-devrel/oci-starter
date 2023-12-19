variable "dns_zone_name" { default="" }
variable "dns_name" { default="" }
variable "dns_ip" { default="" }

locals {
  dns_ip2 = var.dns_ip=="" ? local.dns_ip : var.dns_ip
}

resource "oci_dns_rrset" "starter_rrset" {
    count = (var.dns_zone_name=="" || local.dns_ip2=="") ? 0 : 1

    #Required
    zone_name_or_id = var.dns_zone_name
    domain = var.dns_name
    rtype  = "A"
    compartment_id = local.lz_appdev_cmp_ocid
    items {
        #Required
        domain = var.dns_name
        rdata = local.dns_ip2
        rtype = "A"
        ttl = 3600
    }
}