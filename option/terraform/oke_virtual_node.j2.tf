{%- if oke_ocid is defined %}
variable "oke_ocid" {}

locals {
  oke_ocid = var.oke_ocid
}

{%- else %}  

#----------------------------------------------------------------------------
# VARIABLES

variable "oke_shape" {
  {%- if shape == "ampere" %}
  default = "Pod.Standard.A1.Flex"
  {%- else %}
  default = "Pod.Standard.E4.Flex"
  {%- endif %}
}

variable "node_pool_size" {
  default = 1
}

variable "cluster_options_persistent_volume_config_defined_tags_value" {
  default = "value"
}

variable "kubernetes_version" {
  default = "v1.29.1"
}

# CIDR
locals {
  oke_cidr_nodepool     = "10.0.10.0/24"
  oke_cidr_loadbalancer = "10.0.20.0/24"
  oke_cidr_api          = "10.0.30.0/24"
  oke_cidr_pods         = "10.1.0.0/16"
  oke_cidr_services     = "10.2.0.0/16"
}

#----------------------------------------------------------------------------
# DATA

data "oci_containerengine_cluster_option" "starter_cluster_option" {
  cluster_option_id = "all"
}

data "oci_containerengine_node_pool_option" "starter_node_pool_option" {
  node_pool_option_id = "all"
}

data "oci_identity_availability_domain" "ad1" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

data "oci_identity_availability_domain" "ad2" {
  compartment_id = var.tenancy_ocid
  ad_number      = 2
}

data "oci_core_images" "shape_specific_images" {
  #Required
  compartment_id = var.tenancy_ocid
  shape     = var.oke_shape
}

locals {
  # all_images = "${data.oci_core_images.shape_specific_images.images}"
  # all_sources = "${data.oci_containerengine_node_pool_option.starter_node_pool_option.sources}"
  # compartment_images = [for image in local.all_images : image.id if length(regexall("Oracle-Linux-[0-9]*.[0-9]*-20[0-9]*",image.display_name)) > 0 ]
  # oracle_linux_images = [for source in local.all_sources : source.image_id if length(regexall("Oracle-Linux-[0-9]*.[0-9]*-20[0-9]*",source.source_name)) > 0]
  # image_id = tolist(setintersection( toset(local.compartment_images), toset(local.oracle_linux_images)))[0]
  image_id = data.oci_core_images.oraclelinux.images.0.id
}
  

#----------------------------------------------------------------------------
# SECURITY LISTS

resource "oci_core_security_list" "starter_seclist_lb" {
  compartment_id = local.lz_network_cmp_ocid
  vcn_id         = data.oci_core_vcn.starter_vcn.id
  display_name   = "${var.prefix}-seclist-lb"

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

  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 8080
      max = 8080
    }
  }

  egress_security_rules {
    description      = "Allow TCP traffic from Load Balancers to node ports"
    destination      = local.oke_cidr_nodepool
    destination_type = "CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      min = 30000
      max = 32767
    }
  }
  egress_security_rules {
    description      = "Allow TCP traffic from Load Balancers to node ports"
    destination      = local.oke_cidr_nodepool
    destination_type = "CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      min = 10256
      max = 10256
    }
  }

  freeform_tags = local.freeform_tags
}

#----------------------------------------------------------------------------

resource "oci_core_security_list" "starter_seclist_node" {
  compartment_id = local.lz_network_cmp_ocid
  vcn_id         = data.oci_core_vcn.starter_vcn.id
  display_name   = "${var.prefix}-seclist-node"

 	egress_security_rules {
		description = "Allow pods on one worker node to communicate with pods on other worker nodes"
		destination = local.oke_cidr_nodepool
		destination_type = "CIDR_BLOCK"
		protocol = "all"
		stateless = "false"
	}
	egress_security_rules {
		description = "Access to Kubernetes API Endpoint"
		destination = local.oke_cidr_api
		destination_type = "CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
	}
	egress_security_rules {
		description = "Kubernetes worker to control plane communication"
		destination = local.oke_cidr_api
		destination_type = "CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
	}
	egress_security_rules {
		description = "Path discovery"
		destination = local.oke_cidr_api
		destination_type = "CIDR_BLOCK"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		stateless = "false"
	}
	egress_security_rules {
		description = "Allow nodes to communicate with OKE to ensure correct start-up and continued functioning"
		destination = "all-fra-services-in-oracle-services-network"
		destination_type = "SERVICE_CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
	}
	egress_security_rules {
		description = "ICMP Access from Kubernetes Control Plane"
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		stateless = "false"
	}
	egress_security_rules {
		description = "Worker Nodes access to Internet"
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
		protocol = "all"
		stateless = "false"
	}
	ingress_security_rules {
		description = "Allow pods on one worker node to communicate with pods on other worker nodes"
		protocol = "all"
		source = local.oke_cidr_nodepool
		stateless = "false"
	}
	ingress_security_rules {
		description = "Path discovery"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		source = local.oke_cidr_api
		stateless = "false"
	}
	ingress_security_rules {
		description = "TCP access from Kubernetes Control Plane"
		protocol = "6"
		source = local.oke_cidr_api
		stateless = "false"
	}
	ingress_security_rules {
		description = "Inbound SSH traffic to worker nodes"
		protocol = "6"
		source = "0.0.0.0/0"
		stateless = "false"
	}

  freeform_tags = local.freeform_tags
}

#----------------------------------------------------------------------------

resource oci_core_security_list starter_seclist_api {
  compartment_id = local.lz_network_cmp_ocid
  vcn_id         = data.oci_core_vcn.starter_vcn.id
  display_name   = "${var.prefix}-seclist-node"

	egress_security_rules {
		description = "Allow Kubernetes Control Plane to communicate with OKE"
		destination = "all-fra-services-in-oracle-services-network"
		destination_type = "SERVICE_CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
	}
	egress_security_rules {
		description = "All traffic to worker nodes"
		destination = local.oke_cidr_nodepool
		destination_type = "CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
	}
	egress_security_rules {
		description = "Path discovery"
		destination = local.oke_cidr_nodepool
		destination_type = "CIDR_BLOCK"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		stateless = "false"
	}
	ingress_security_rules {
		description = "External access to Kubernetes API endpoint"
		protocol = "6"
		source = "0.0.0.0/0"
		stateless = "false"
	}
	ingress_security_rules {
		description = "Kubernetes worker to Kubernetes API endpoint communication"
		protocol = "6"
		source = local.oke_cidr_nodepool
		stateless = "false"
	}
	ingress_security_rules {
		description = "Kubernetes worker to control plane communication"
		protocol = "6"
		source = local.oke_cidr_nodepool
		stateless = "false"
	}
	ingress_security_rules {
		description = "Path discovery"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		source = local.oke_cidr_nodepool
		stateless = "false"
	}

  freeform_tags = local.freeform_tags
}

#----------------------------------------------------------------------------
# SUBNETS

resource "oci_core_subnet" "starter_nodepool_subnet" {
  #Required
  # availability_domain = data.oci_identity_availability_domain.ad1.name
  cidr_block          = local.oke_cidr_nodepool
  compartment_id      = local.lz_network_cmp_ocid
  vcn_id              = data.oci_core_vcn.starter_vcn.id
  dns_label           = "nodepool"
  prohibit_public_ip_on_vnic = "true"

  # Provider code tries to maintain compatibility with old versions.
  # security_list_ids = [oci_core_security_list.starter_seclist_node.id,data.oci_core_vcn.starter_vcn.default_security_list_id,oci_core_security_list.starter_security_list.id]
  security_list_ids = [oci_core_security_list.starter_seclist_node.id,data.oci_core_vcn.starter_vcn.default_security_list_id]
  display_name      = "${var.prefix}-oke-nodepool-subnet"
  route_table_id    = oci_core_route_table.starter_route_private.id

  freeform_tags = local.freeform_tags
}

resource "oci_core_subnet" "starter_lb_subnet" {
  #Required
  cidr_block          = local.oke_cidr_loadbalancer
  compartment_id      = local.lz_network_cmp_ocid
  vcn_id              = data.oci_core_vcn.starter_vcn.id
  dns_label           = "lb"
  prohibit_public_ip_on_vnic = "false"

  # Provider code tries to maintain compatibility with old versions.
  # security_list_ids = [data.oci_core_vcn.starter_vcn.default_security_list_id, oci_core_security_list.starter_security_list.id]
  security_list_ids = [oci_core_security_list.starter_seclist_lb.id,data.oci_core_vcn.starter_vcn.default_security_list_id]
  display_name      = "${var.prefix}-oke-lb-subnet"
  route_table_id    = data.oci_core_vcn.starter_vcn.default_route_table_id

  freeform_tags     = local.freeform_tags
}

resource "oci_core_subnet" "starter_api_subnet" {
  #Required
  cidr_block          = local.oke_cidr_api
  compartment_id      = local.lz_network_cmp_ocid
  vcn_id              = data.oci_core_vcn.starter_vcn.id
  dns_label           = "api"
  prohibit_public_ip_on_vnic = "false"

  # Provider code tries to maintain compatibility with old versions.
  # security_list_ids = [oci_core_security_list.starter_seclist_api.id,data.oci_core_vcn.starter_vcn.default_security_list_id,oci_core_security_list.starter_security_list.id]
  security_list_ids = [oci_core_security_list.starter_seclist_api.id,data.oci_core_vcn.starter_vcn.default_security_list_id]
  display_name      = "${var.prefix}-oke-api-subnet"
  route_table_id    = data.oci_core_vcn.starter_vcn.default_route_table_id
  freeform_tags     = local.freeform_tags
}

# 	security_list_ids = ["${oci_core_security_list.kubernetes_api_endpoint_sec_list.id}"]

/*
resource "oci_core_subnet" "starter_pod_subnet" {
  #Required
  cidr_block          = "10.0.40.0/24"
  compartment_id      = local.lz_network_cmp_ocid
  vcn_id              = data.oci_core_vcn.starter_vcn.id

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [data.oci_core_vcn.starter_vcn.default_security_list_id, oci_core_security_list.starter_security_list.id]
  display_name      = "${var.prefix}-oke-pod-subnet"
  route_table_id    = data.oci_core_vcn.starter_vcn.default_route_table_id
  freeform_tags     = local.freeform_tags
}
*/

#----------------------------------------------------------------------------
# CLUSTER


resource "oci_containerengine_cluster" "starter_oke" {
	cluster_pod_network_options {
		cni_type = "OCI_VCN_IP_NATIVE"
	}
	compartment_id = var.compartment_ocid
	endpoint_config {
		is_public_ip_enabled = "true"
		subnet_id = "${oci_core_subnet.starter_api_subnet.id}"
	}
	kubernetes_version = var.kubernetes_version
	name = "${var.prefix}-oke"
	options {
		admission_controller_options {
			is_pod_security_policy_enabled = "false"
		}
		persistent_volume_config {
			freeform_tags = {
				"OKEclusterName" = "${var.prefix}-oke"
			}
		}
		service_lb_config {
			freeform_tags = {
				"OKEclusterName" = "${var.prefix}-oke"
			}
		}
		service_lb_subnet_ids = ["${oci_core_subnet.starter_api_subnet.id}"]
	}
	type = "ENHANCED_CLUSTER"
	vcn_id = data.oci_core_vcn.starter_vcn.id
    freeform_tags = local.freeform_tags
}

#----------------------------------------------------------------------------
# NODE POOL

resource "oci_containerengine_virtual_node_pool" "starter_virtual_node_pool" {
	cluster_id = "${oci_containerengine_cluster.starter_oke.id}"
	compartment_id = var.compartment_ocid
	display_name = "pool1"
	initial_virtual_node_labels {
		key = "name"
		value = "starter-virtual"
	}
	placement_configurations {
		availability_domain = data.oci_identity_availability_domain.ad1.name
		subnet_id = "${oci_core_subnet.starter_nodepool_subnet.id}"
        fault_domain=["FAULT-DOMAIN-1"]
	}
	pod_configuration {
		shape = var.oke_shape
		subnet_id = "${oci_core_subnet.starter_nodepool_subnet.id}"
	}
	size = var.node_pool_size
}

#----------------------------------------------------------------------------
# Policy for OKE Virtual NodePools

resource "oci_identity_policy" "starter_oke_policy" {
  provider       = oci.home    
  name           = "${var.prefix}-oke-virtual-node-policy"
  description    = "${var.prefix}-oke-virtual-node-policy"
  compartment_id = var.tenancy_ocid
  statements = [
    "define tenancy ske as ocid1.tenancy.oc1..aaaaaaaacrvwsphodcje6wfbc3xsixhzcan5zihki6bvc7xkwqds4tqhzbaq",
    "define compartment ske_compartment as ocid1.compartment.oc1..aaaaaaaa2bou6r766wmrh5zt3vhu2rwdya7ahn4dfdtwzowb662cmtdc5fea",
    "endorse any-user to associate compute-container-instances in compartment ske_compartment of tenancy ske with subnets in tenancy where ALL {request.principal.type='virtualnode',request.operation='CreateContainerInstance',request.principal.subnet=2.subnet.id}",
    "endorse any-user to associate compute-container-instances in compartment ske_compartment of tenancy ske with vnics in tenancy where ALL {request.principal.type='virtualnode',request.operation='CreateContainerInstance',request.principal.subnet=2.subnet.id}",
    "endorse any-user to associate compute-container-instances in compartment ske_compartment of tenancy ske with network-security-group in tenancy where ALL {request.principal.type='virtualnode',request.operation='CreateContainerInstance'}"
  ]
  freeform_tags = local.freeform_tags
}

#----------------------------------------------------------------------------
# ADDONS 

/*
# Database Operator
resource oci_containerengine_addon starter_oke_addon_dboperator {
  addon_name                       = "OracleDatabaseOperator"
  cluster_id                       = oci_containerengine_cluster.starter_oke.id
  remove_addon_resources_on_delete = "true"
}

# WebLogic Operator
resource oci_containerengine_addon starter_oke_addon_wlsoperator {
  addon_name                       = "WeblogicKubernetesOperator"
  cluster_id                       = oci_containerengine_cluster.starter_oke.id
  remove_addon_resources_on_delete = "true"
}

# CertManager
resource oci_containerengine_addon starter_oke_addon_certmanager {
  addon_name                       = "CertManager"
  cluster_id                       = oci_containerengine_cluster.starter_oke.id
  remove_addon_resources_on_delete = "true"
}
*/

#----------------------------------------------------------------------------
# OUTPUTS

/*
output "node_pool" {
  value = {
    id                 = oci_containerengine_node_pool.starter_virtual_node_pool.id
    kubernetes_version = oci_containerengine_node_pool.starter_virtual_node_pool.kubernetes_version
    name               = oci_containerengine_node_pool.starter_virtual_node_pool.name
    subnet_ids         = oci_containerengine_node_pool.starter_virtual_node_pool.subnet_ids
  }
}
*/

#----------------------------------------------------------------------------
# LOCALS

locals {
  oke_ocid = oci_containerengine_cluster.starter_oke.id
}
{%- endif %}  

output "oke_ocid" {
  value = local.oke_ocid
}



