resource "oci_core_nat_gateway" "starter_nat_gateway" {
  compartment_id = local.lz_network_cmp_ocid
  vcn_id         = oci_core_vcn.starter_vcn.id
  display_name   = "${var.prefix}-nat-gateway"
  freeform_tags  = local.freeform_tags
}

resource "oci_core_route_table" "starter_route_private" {
  compartment_id = local.lz_network_cmp_ocid
  vcn_id         = oci_core_vcn.starter_vcn.id
  display_name   = "${var.prefix}-route-private"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.starter_nat_gateway.id
  }
}

