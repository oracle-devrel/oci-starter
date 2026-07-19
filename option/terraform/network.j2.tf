# --- Network ---
variable "public_ip_filter" {
  description = "IP Range that can access the public network"
  default = "0.0.0.0/0"  
}

# To use a existing VCN, add these variables in terraform.tfvars
#
# vcn_ocid="XXXX"
# web_subnet_ocid="XXXX"
# app_subnet_ocid="XXXX"
# db_subnet_ocid="XXXX"

# Existing VCN
variable "vcn_ocid" { default=null }
variable "web_subnet_ocid" { default=null }
variable "app_subnet_ocid" {default=null }
variable "db_subnet_ocid" { default=null }

# New VCN 
locals {
    cidr_vcn = "10.0.0.0/16"
    cidr_web_subnet = "10.0.1.0/24"
    cidr_app_subnet =  "10.0.2.0/24"
    cidr_db_subnet =  "10.0.3.0/24"  
}

resource "oci_core_vcn" "starter_vcn" {
    count = var.vcn_ocid == null ? 1 : 0

    cidr_block     = local.cidr_vcn
    compartment_id = local.lz_network_cmp_ocid
    display_name   = "${var.prefix}-vcn"
    dns_label      = "${var.prefix}vcn"
    freeform_tags  = local.freeform_tags
}

resource "oci_core_internet_gateway" "starter_internet_gateway" {
    count = var.vcn_ocid == null ? 1 : 0

    compartment_id = local.lz_network_cmp_ocid
    display_name   = "${var.prefix}-internet-gateway"
    vcn_id         = data.oci_core_vcn.starter_vcn.id
    freeform_tags  = local.freeform_tags
}

resource "oci_core_default_route_table" "default_route_table" {
    count = var.vcn_ocid == null ? 1 : 0

    manage_default_resource_id = data.oci_core_vcn.starter_vcn.default_route_table_id
    display_name               = "DefaultRouteTable"

    route_rules {
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
        network_entity_id = oci_core_internet_gateway.starter_internet_gateway[0].id
    }
    freeform_tags = local.freeform_tags
}

# Public Subnet
resource "oci_core_subnet" "starter_web_subnet" {
    count = var.vcn_ocid == null ? 1 : 0

    cidr_block        = local.cidr_web_subnet
    display_name      = "${var.prefix}-web-subnet"
    dns_label         = "${var.prefix}web"
    security_list_ids = [data.oci_core_vcn.starter_vcn.default_security_list_id, oci_core_security_list.starter_security_list[0].id]
    compartment_id    = local.lz_network_cmp_ocid
    vcn_id            = data.oci_core_vcn.starter_vcn.id
    route_table_id    = data.oci_core_vcn.starter_vcn.default_route_table_id
    dhcp_options_id   = data.oci_core_vcn.starter_vcn.default_dhcp_options_id
    freeform_tags     = local.freeform_tags
}

# App Subnet
resource "oci_core_subnet" "starter_app_subnet" {
    count = var.vcn_ocid == null ? 1 : 0

    cidr_block        = local.cidr_app_subnet
    display_name      = "${var.prefix}-app-subnet"
    dns_label         = "${var.prefix}app"
    security_list_ids = [data.oci_core_vcn.starter_vcn.default_security_list_id, oci_core_security_list.starter_security_list[0].id]
    compartment_id    = local.lz_network_cmp_ocid
    vcn_id            = data.oci_core_vcn.starter_vcn.id
    route_table_id    = oci_core_route_table.starter_route_private[0].id
    dhcp_options_id   = data.oci_core_vcn.starter_vcn.default_dhcp_options_id
    freeform_tags     = local.freeform_tags
    prohibit_public_ip_on_vnic = true
}

# DB Subnet
resource "oci_core_subnet" "starter_db_subnet" {
    count = var.vcn_ocid == null ? 1 : 0

    cidr_block        = local.cidr_db_subnet
    display_name      = "${var.prefix}-db-subnet"
    dns_label         = "${var.prefix}db"
    security_list_ids = [data.oci_core_vcn.starter_vcn.default_security_list_id, oci_core_security_list.starter_security_list[0].id]
    compartment_id    = local.lz_network_cmp_ocid
    vcn_id            = data.oci_core_vcn.starter_vcn.id
    route_table_id    = oci_core_route_table.starter_route_private[0].id
    dhcp_options_id   = data.oci_core_vcn.starter_vcn.default_dhcp_options_id
    freeform_tags     = local.freeform_tags
    prohibit_public_ip_on_vnic = true
}

resource "oci_core_security_list" "starter_security_list" {
    count = var.vcn_ocid == null ? 1 : 0

    compartment_id = local.lz_network_cmp_ocid
    vcn_id         = data.oci_core_vcn.starter_vcn.id
    display_name   = "${var.prefix}-security-list"

    ingress_security_rules {
        protocol  = "6" // tcp
        source    = var.public_ip_filter
        stateless = false

        tcp_options {
            min = 3000
            max = 3000
        }
    }

    ingress_security_rules {
        protocol  = "6" // tcp
        source    = local.cidr_vcn
        stateless = false

        tcp_options {
        min = 3000
        max = 3000
        }
    }


    ingress_security_rules {
        protocol  = "6" // tcp
        source    = var.public_ip_filter
        stateless = false

        tcp_options {
        min = 80
        max = 80
        }
    }

    ingress_security_rules {
        protocol  = "6" // tcp
        source    = local.cidr_vcn
        stateless = false

        tcp_options {
        min = 80
        max = 80
        }
    }

    ingress_security_rules {
        protocol  = "6" // tcp
        source    = var.public_ip_filter
        stateless = false

        tcp_options {
        min = 8080
        max = 8080
        }
    }  

    ingress_security_rules {
        protocol  = "6" // tcp
        source    = local.cidr_vcn
        stateless = false

        tcp_options {
        min = 8080
        max = 8080
        }
    }

    // Oracle TNS Listener port
    ingress_security_rules {
        protocol  = "6" // tcp
        source    = local.cidr_vcn
        stateless = false

        tcp_options {
        min = 1521
        max = 1522
        }
    }  

    // MySQL listener port: XXX optional ?
    ingress_security_rules {
        protocol  = "6" // tcp
        source    = local.cidr_vcn
        stateless = false

        tcp_options {
        min = 3306
        max = 3306
        }
    }  

    // MySQL listener port_x: XXX optional ?
    ingress_security_rules {
        protocol  = "6" // tcp
        source    = local.cidr_vcn
        stateless = false

        tcp_options {
        min = 33060
        max = 33060
        }
    }  

    // PostgreSQL
    ingress_security_rules {
        protocol  = "6" // tcp
        source    = local.cidr_vcn
        stateless = false

        tcp_options {
        min = 5432
        max = 5433
        }
    }  

    // Opensearch
    ingress_security_rules {
        protocol  = "6" // tcp
        source    = local.cidr_vcn
        stateless = false

        tcp_options {
        min = 9200
        max = 9200
        }
    }  

    ingress_security_rules {
        protocol  = "6" // tcp
        source    = local.cidr_vcn
        stateless = false

        tcp_options {
        min = 5601
        max = 5601
        }
    }
    
    // External access to Kubernetes API endpoint
    ingress_security_rules {
        protocol  = "6" // tcp
        source    = local.cidr_vcn
        stateless = false

        tcp_options {
        min = 6443
        max = 6443
        }
    }  

    // Kubernetes worker to control plane communication
    ingress_security_rules {
        protocol  = "6" // tcp
        source    = local.cidr_vcn
        stateless = false

        tcp_options {
        min = 12250
        max = 12250
        }
    }  

    // K8S Ingress-Controller
    ingress_security_rules {
        protocol  = "6" // tcp
        source    = local.cidr_vcn
        stateless = false

        tcp_options {
        min = 8443
        max = 8443
        }
    }  

    // MCP Server
    ingress_security_rules {
        protocol  = "6" // tcp
        source    = local.cidr_vcn
        stateless = false

        tcp_options {
        min = 2025
        max = 2025
        }
    }  


    freeform_tags = local.freeform_tags
}

# NAT Gateway
resource "oci_core_nat_gateway" "starter_nat_gateway" {
    count = var.vcn_ocid == null ? 1 : 0

    compartment_id = local.lz_network_cmp_ocid
    vcn_id         = data.oci_core_vcn.starter_vcn.id
    display_name   = "${var.prefix}-nat-gateway"
    freeform_tags  = local.freeform_tags
}

# Service Gateway
resource "oci_core_service_gateway" "starter_service_gateway" {
    count = var.vcn_ocid == null ? 1 : 0

    compartment_id = local.lz_network_cmp_ocid
    services {
        service_id = data.oci_core_services.all_services.services[0]["id"]
    }
    vcn_id         = data.oci_core_vcn.starter_vcn.id

    display_name   = "${var.prefix}-service-gateway"
    freeform_tags  = local.freeform_tags
}

# Route Private Subnet
resource "oci_core_route_table" "starter_route_private" {
    count = var.vcn_ocid == null ? 1 : 0

    compartment_id = local.lz_network_cmp_ocid
    vcn_id         = data.oci_core_vcn.starter_vcn.id
    display_name   = "${var.prefix}-route-private"

    route_rules {
        destination       = data.oci_core_services.all_services.services[0]["cidr_block"]
        destination_type  = "SERVICE_CIDR_BLOCK"
        network_entity_id = oci_core_service_gateway.starter_service_gateway[0].id
    }  
    route_rules {
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
        network_entity_id = oci_core_nat_gateway.starter_nat_gateway[0].id
    }
}

# Works for both new and existing network
data "oci_core_vcn" "starter_vcn" {
    vcn_id = (var.vcn_ocid == null) ? oci_core_vcn.starter_vcn[0].id : var.vcn_ocid
}

data "oci_core_subnet" "starter_web_subnet" {
    subnet_id = var.web_subnet_ocid == null ? oci_core_subnet.starter_web_subnet[0].id : var.web_subnet_ocid
}

data "oci_core_subnet" "starter_app_subnet" {
    subnet_id = var.app_subnet_ocid == null ? oci_core_subnet.starter_app_subnet[0].id : var.app_subnet_ocid
}

data "oci_core_subnet" "starter_db_subnet" {
    subnet_id = var.db_subnet_ocid == null ? oci_core_subnet.starter_db_subnet[0].id : var.db_subnet_ocid
}
