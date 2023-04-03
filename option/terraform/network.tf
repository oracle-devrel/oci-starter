# --- Network ---
resource "oci_core_vcn" "starter_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = local.lz_network_cmp_ocid
  display_name   = "${var.prefix}-vcn"
  dns_label      = "${var.prefix}vcn"
  freeform_tags  = local.freeform_tags
}

resource "oci_core_internet_gateway" "starter_internet_gateway" {
  compartment_id = local.lz_network_cmp_ocid
  display_name   = "${var.prefix}-internet-gateway"
  vcn_id         = oci_core_vcn.starter_vcn.id
  freeform_tags  = local.freeform_tags
}

resource "oci_core_default_route_table" "default_route_table" {
  manage_default_resource_id = oci_core_vcn.starter_vcn.default_route_table_id
  display_name               = "DefaultRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.starter_internet_gateway.id
  }
  freeform_tags = local.freeform_tags
}

# Public Subnet
resource "oci_core_subnet" "starter_public_subnet" {
  cidr_block        = "10.0.1.0/24"
  display_name      = "${var.prefix}-pub-subnet"
  dns_label         = "${var.prefix}pub"
  security_list_ids = [oci_core_vcn.starter_vcn.default_security_list_id, oci_core_security_list.starter_security_list.id]
  compartment_id    = local.lz_network_cmp_ocid
  vcn_id            = oci_core_vcn.starter_vcn.id
  route_table_id    = oci_core_vcn.starter_vcn.default_route_table_id
  dhcp_options_id   = oci_core_vcn.starter_vcn.default_dhcp_options_id
  freeform_tags     = local.freeform_tags
}

# Private Subnet
resource "oci_core_subnet" "starter_private_subnet" {
  cidr_block        = "10.0.2.0/24"
  display_name      = "${var.prefix}-priv-subnet"
  dns_label         = "${var.prefix}priv"
  security_list_ids = [oci_core_vcn.starter_vcn.default_security_list_id, oci_core_security_list.starter_security_list.id]
  compartment_id    = local.lz_network_cmp_ocid
  vcn_id            = oci_core_vcn.starter_vcn.id
  route_table_id    = oci_core_route_table.starter_route_private.id
  dhcp_options_id   = oci_core_vcn.starter_vcn.default_dhcp_options_id
  freeform_tags     = local.freeform_tags
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_security_list" "starter_security_list" {
  compartment_id = local.lz_network_cmp_ocid
  vcn_id         = oci_core_vcn.starter_vcn.id
  display_name   = "${var.prefix}-security-list"

  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 80
      max = 80
    }
  }

  // XXXXXX 0.0.0.0/0 ??
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 8080
      max = 8080
    }
  }  

  // Oracle TNS Listener port
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "10.0.0.0/8"
    stateless = false

    tcp_options {
      min = 1521
      max = 1522
    }
  }  

  // MySQL listener port: XXX optional ?
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "10.0.0.0/8"
    stateless = false

    tcp_options {
      min = 3306
      max = 3306
    }
  }  

  // MySQL listener port_x: XXX optional ?
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "10.0.0.0/8"
    stateless = false

    tcp_options {
      min = 33306
      max = 33306
    }
  }  

  // External access to Kubernetes API endpoint
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 6443
      max = 6443
    }
  }  

  // Kubernetes worker to control plane communication
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "10.0.0.0/8"
    stateless = false

    tcp_options {
      min = 12250
      max = 12250
    }
  }  

  // K8S Ingress-Controller
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "10.0.0.0/8"
    stateless = false

    tcp_options {
      min = 8443
      max = 8443
    }
  }  

  freeform_tags = local.freeform_tags
}

# Compatibility with network_existing.tf
data "oci_core_vcn" "starter_vcn" {
  vcn_id = oci_core_vcn.starter_vcn.id
}

data "oci_core_subnet" "starter_public_subnet" {
  subnet_id = oci_core_subnet.starter_public_subnet.id
}

data "oci_core_subnet" "starter_private_subnet" {
  subnet_id = oci_core_subnet.starter_private_subnet.id
}
