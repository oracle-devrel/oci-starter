variable "dns_zone_name" { default="" }
variable "dns_name" { default="" }
variable "dns_ip" { default="" }

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
        ttl = 3600
    }
}