provider "oci" {}

locals {
  oke_cidr_nodepool     = "10.0.10.0/24"
  oke_cidr_loadbalancer = "10.0.20.0/24"
  oke_cidr_api          = "10.0.30.0/24"
  oke_cidr_pods         = "10.1.0.0/16"
  oke_cidr_services     = "10.2.0.0/16"
}


resource "oci_core_vcn" "generated_oci_core_vcn" {
	cidr_block = "10.0.0.0/16"
	compartment_id = var.compartment_ocid
	display_name = "oke-vcn-quick-starter-virtual-168cd3edc"
	dns_label = "startervirtual"
}

resource "oci_core_internet_gateway" "generated_oci_core_internet_gateway" {
	compartment_id = var.compartment_ocid
	display_name = "oke-igw-quick-starter-virtual-168cd3edc"
	enabled = "true"
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_core_nat_gateway" "generated_oci_core_nat_gateway" {
	compartment_id = var.compartment_ocid
	display_name = "oke-ngw-quick-starter-virtual-168cd3edc"
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_core_service_gateway" "generated_oci_core_service_gateway" {
	compartment_id = var.compartment_ocid
	display_name = "oke-sgw-quick-starter-virtual-168cd3edc"
	services {
		service_id = "ocid1.service.oc1.eu-frankfurt-1.aaaaaaaa7ncsqkj6lkz36dehifizupyn6qjqsmtepsegs23yyntnsy7qrvea"
	}
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_core_route_table" "generated_oci_core_route_table" {
	compartment_id = var.compartment_ocid
	display_name = "oke-private-routetable-starter-virtual-168cd3edc"
	route_rules {
		description = "traffic to the internet"
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
		network_entity_id = "${oci_core_nat_gateway.generated_oci_core_nat_gateway.id}"
	}
	route_rules {
		description = "traffic to OCI services"
		destination = "all-fra-services-in-oracle-services-network"
		destination_type = "SERVICE_CIDR_BLOCK"
		network_entity_id = "${oci_core_service_gateway.generated_oci_core_service_gateway.id}"
	}
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_core_subnet" "service_lb_subnet" {
	cidr_block = local.oke_cidr_loadbalancer
	compartment_id = var.compartment_ocid
	display_name = "oke-svclbsubnet-quick-starter-virtual-168cd3edc-regional"
	dns_label = "lbsube0f83562f"
	prohibit_public_ip_on_vnic = "false"
	route_table_id = "${oci_core_default_route_table.generated_oci_core_default_route_table.id}"
	security_list_ids = ["${oci_core_vcn.generated_oci_core_vcn.default_security_list_id}"]
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_core_subnet" "node_subnet" {
	cidr_block = local.oke_cidr_nodepool
	compartment_id = var.compartment_ocid
	display_name = "oke-nodesubnet-quick-starter-virtual-168cd3edc-regional"
	dns_label = "subfe50c27a4"
	prohibit_public_ip_on_vnic = "true"
	route_table_id = "${oci_core_route_table.generated_oci_core_route_table.id}"
	security_list_ids = ["${oci_core_security_list.node_sec_list.id}"]
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_core_subnet" "kubernetes_api_endpoint_subnet" {
	cidr_block = local.oke_cidr_api
	compartment_id = var.compartment_ocid
	display_name = "oke-k8sApiEndpoint-subnet-quick-starter-virtual-168cd3edc-regional"
	dns_label = "sub49af870c0"
	prohibit_public_ip_on_vnic = "false"
	route_table_id = "${oci_core_default_route_table.generated_oci_core_default_route_table.id}"
	security_list_ids = ["${oci_core_security_list.kubernetes_api_endpoint_sec_list.id}"]
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_core_default_route_table" "generated_oci_core_default_route_table" {
	display_name = "oke-public-routetable-starter-virtual-168cd3edc"
	route_rules {
		description = "traffic to/from internet"
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
		network_entity_id = "${oci_core_internet_gateway.generated_oci_core_internet_gateway.id}"
	}
	manage_default_resource_id = "${oci_core_vcn.generated_oci_core_vcn.default_route_table_id}"
}

resource "oci_core_security_list" "service_lb_sec_list" {
	compartment_id = var.compartment_ocid
	display_name = "oke-svclbseclist-quick-starter-virtual-168cd3edc"
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_core_security_list" "node_sec_list" {
	compartment_id = var.compartment_ocid
	display_name = "oke-nodeseclist-quick-starter-virtual-168cd3edc"
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
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_core_security_list" "kubernetes_api_endpoint_sec_list" {
	compartment_id = var.compartment_ocid
	display_name = "oke-k8sApiEndpoint-quick-starter-virtual-168cd3edc"
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
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_containerengine_cluster" "starter_oke" {
	cluster_pod_network_options {
		cni_type = "OCI_VCN_IP_NATIVE"
	}
	compartment_id = var.compartment_ocid
	endpoint_config {
		is_public_ip_enabled = "true"
		subnet_id = "${oci_core_subnet.kubernetes_api_endpoint_subnet.id}"
	}
	freeform_tags = {
		"OKEclusterName" = "starter-virtual"
	}
	kubernetes_version = "v1.29.1"
	name = "starter-virtual"
	options {
		admission_controller_options {
			is_pod_security_policy_enabled = "false"
		}
		persistent_volume_config {
			freeform_tags = {
				"OKEclusterName" = "starter-virtual"
			}
		}
		service_lb_config {
			freeform_tags = {
				"OKEclusterName" = "starter-virtual"
			}
		}
		service_lb_subnet_ids = ["${oci_core_subnet.service_lb_subnet.id}"]
	}
	type = "ENHANCED_CLUSTER"
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_containerengine_virtual_node_pool" "create_virtual_node_pool_details0" {
	cluster_id = "${oci_containerengine_cluster.starter_oke.id}"
	compartment_id = var.compartment_ocid
	display_name = "pool1"
	initial_virtual_node_labels {
		key = "name"
		value = "starter-virtual"
	}
	placement_configurations {
		availability_domain = "KSGd:EU-FRANKFURT-1-AD-1"
		subnet_id = "${oci_core_subnet.node_subnet.id}"
        fault_domain=["FAULT-DOMAIN-1"]
	}
	placement_configurations {
		availability_domain = "KSGd:EU-FRANKFURT-1-AD-2"
		subnet_id = "${oci_core_subnet.node_subnet.id}"
        fault_domain=["FAULT-DOMAIN-1"]
	}
	placement_configurations {
		availability_domain = "KSGd:EU-FRANKFURT-1-AD-3"
		subnet_id = "${oci_core_subnet.node_subnet.id}"
        fault_domain=["FAULT-DOMAIN-1"]
	}
	pod_configuration {
		shape = "Pod.Standard.E4.Flex"
		subnet_id = "${oci_core_subnet.node_subnet.id}"
	}
	size = "1"
}
