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
  default = "VM.Standard.A1.Flex"
  {%- else %}
  default = "VM.Standard.AMD.Generic"
  {%- endif %}
}

variable "node_pool_size" {
  default = 1
}

variable "cluster_options_persistent_volume_config_defined_tags_value" {
  default = "value"
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

  freeform_tags = local.freeform_tags
}

#----------------------------------------------------------------------------

resource "oci_core_security_list" "starter_seclist_node" {
  compartment_id = local.lz_network_cmp_ocid
  vcn_id         = data.oci_core_vcn.starter_vcn.id
  display_name   = "${var.prefix}-seclist-node"

  egress_security_rules {
    description      = "Allow pods on one worker node to communicate with pods on other worker nodes"
    destination      = local.oke_cidr_nodepool
    destination_type = "CIDR_BLOCK"
    protocol  = "all"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Access to Kubernetes API Endpoint"
    destination      = local.oke_cidr_api
    destination_type = "CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  egress_security_rules {
    description      = "Kubernetes worker to control plane communication"
    destination      = local.oke_cidr_api
    destination_type = "CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "12250"
      min = "12250"
    }
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = local.oke_cidr_api
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Allow nodes to communicate with OKE to ensure correct start-up and continued functioning"
    destination      = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  egress_security_rules {
    description      = "ICMP Access from Kubernetes Control Plane"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Worker Nodes access to Internet"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol  = "all"
    stateless = "false"
  }

  ingress_security_rules {
    description = "Allow pods on one worker node to communicate with pods on other worker nodes"
    protocol    = "all"
    source      = local.oke_cidr_nodepool
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "Path discovery"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = local.oke_cidr_api
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "TCP access from Kubernetes Control Plane"
    protocol    = "6"
    source      = local.oke_cidr_api
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "Inbound SSH traffic to worker nodes"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }

  freeform_tags = local.freeform_tags
}

#----------------------------------------------------------------------------

resource oci_core_security_list starter_seclist_api {
  compartment_id = local.lz_network_cmp_ocid
  vcn_id         = data.oci_core_vcn.starter_vcn.id
  display_name   = "${var.prefix}-seclist-node"

  egress_security_rules {
    description      = "Allow Kubernetes Control Plane to communicate with OKE"
    destination      = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  egress_security_rules {
    description      = "All traffic to worker nodes"
    destination      = local.oke_cidr_nodepool
    destination_type = "CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = local.oke_cidr_nodepool
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
  }

  ingress_security_rules {
    description = "External access to Kubernetes API endpoint"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  ingress_security_rules {
    description = "Kubernetes worker to control plane communication"
    protocol    = "6"
    source      = local.oke_cidr_nodepool
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "12250"
      min = "12250"
    }
  }
  ingress_security_rules {
    description = "Path discovery"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = local.oke_cidr_nodepool
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }

  freeform_tags = local.freeform_tags
}

#----------------------------------------------------------------------------
# SUBNETS

resource "oci_core_subnet" "starter_nodepool_subnet" {
  #Required
  availability_domain = data.oci_identity_availability_domain.ad1.name
  cidr_block          = local.oke_cidr_nodepool
  compartment_id      = local.lz_network_cmp_ocid
  vcn_id              = data.oci_core_vcn.starter_vcn.id

  # Provider code tries to maintain compatibility with old versions.
  # security_list_ids = [oci_core_security_list.starter_seclist_node.id,data.oci_core_vcn.starter_vcn.default_security_list_id,oci_core_security_list.starter_security_list.id]
  security_list_ids = [oci_core_security_list.starter_seclist_node.id,data.oci_core_vcn.starter_vcn.default_security_list_id]
  display_name      = "${var.prefix}-oke-nodepool-subnet"
  route_table_id    = data.oci_core_vcn.starter_vcn.default_route_table_id

  freeform_tags = local.freeform_tags
}

resource "oci_core_subnet" "starter_lb_subnet" {
  #Required
  cidr_block          = local.oke_cidr_loadbalancer
  compartment_id      = local.lz_network_cmp_ocid
  vcn_id              = data.oci_core_vcn.starter_vcn.id

  # Provider code tries to maintain compatibility with old versions.
  # security_list_ids = [data.oci_core_vcn.starter_vcn.default_security_list_id, oci_core_security_list.starter_security_list.id]
  security_list_ids = [data.oci_core_vcn.starter_vcn.default_security_list_id]
  display_name      = "${var.prefix}-oke-lb-subnet"
  route_table_id    = data.oci_core_vcn.starter_vcn.default_route_table_id


  freeform_tags     = local.freeform_tags
}

resource "oci_core_subnet" "starter_api_subnet" {
  #Required
  cidr_block          = local.oke_cidr_api
  compartment_id      = local.lz_network_cmp_ocid
  vcn_id              = data.oci_core_vcn.starter_vcn.id

  # Provider code tries to maintain compatibility with old versions.
  # security_list_ids = [oci_core_security_list.starter_seclist_api.id,data.oci_core_vcn.starter_vcn.default_security_list_id,oci_core_security_list.starter_security_list.id]
  security_list_ids = [oci_core_security_list.starter_seclist_api.id,data.oci_core_vcn.starter_vcn.default_security_list_id]
  display_name      = "${var.prefix}-oke-api-subnet"
  route_table_id    = data.oci_core_vcn.starter_vcn.default_route_table_id


  freeform_tags     = local.freeform_tags
}

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
  #Required
  compartment_id     = local.lz_appdev_cmp_ocid
  kubernetes_version = data.oci_containerengine_cluster_option.starter_cluster_option.kubernetes_versions[length(data.oci_containerengine_cluster_option.starter_cluster_option.kubernetes_versions)-1]
  name               = "${var.prefix}-oke"
  vcn_id             = data.oci_core_vcn.starter_vcn.id
  type               = "ENHANCED_CLUSTER"

  #Optional
  endpoint_config {
    subnet_id             = oci_core_subnet.starter_api_subnet.id
    is_public_ip_enabled  = "true"
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.starter_lb_subnet.id]
    #Optional
    add_ons {
      #Optional
      is_kubernetes_dashboard_enabled = "true"
      is_tiller_enabled               = "true"
    }

    admission_controller_options {
      #Optional
      is_pod_security_policy_enabled = false
    }

    kubernetes_network_config {
      #Optional
      pods_cidr     = local.oke_cidr_pods
      services_cidr = local.oke_cidr_services
    }

    # cluster_pod_network_options {
    #     cni_type = "OCI_VCN_IP_NATIVE"
    # }
  }

  freeform_tags = local.freeform_tags
}

#----------------------------------------------------------------------------
# NODE POOL

resource "oci_containerengine_node_pool" "starter_node_pool" {
  #Required
  cluster_id         = oci_containerengine_cluster.starter_oke.id
  compartment_id     = local.lz_appdev_cmp_ocid
  kubernetes_version = data.oci_containerengine_node_pool_option.starter_node_pool_option.kubernetes_versions[length(data.oci_containerengine_node_pool_option.starter_node_pool_option.kubernetes_versions)-1]
  name               = "${var.prefix}-pool"
  node_shape         = var.oke_shape
  node_shape_config {
    memory_in_gbs = "32"
    ocpus = "1"
  }

  node_source_details {
    #Required
    image_id    = local.image_id
    source_type = "IMAGE"
  }

  node_config_details {
    #Required
    placement_configs {
      #Required
      availability_domain = data.oci_identity_availability_domain.ad1.name
      subnet_id           = oci_core_subnet.starter_nodepool_subnet.id
      #optional
      fault_domains = ["FAULT-DOMAIN-1", "FAULT-DOMAIN-3"]
    }
    size = var.node_pool_size

    # node_pool_pod_network_option_details {
    #   cni_type = "OCI_VCN_IP_NATIVE"
    #   pod_subnet_ids = [ oci_core_subnet.starter_pod_subnet.id ]
    # }
  }
  ssh_public_key      = var.ssh_public_key

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
*/

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

#----------------------------------------------------------------------------
# OUTPUTS

output "node_pool" {
  value = {
    id                 = oci_containerengine_node_pool.starter_node_pool.id
    kubernetes_version = oci_containerengine_node_pool.starter_node_pool.kubernetes_version
    name               = oci_containerengine_node_pool.starter_node_pool.name
    subnet_ids         = oci_containerengine_node_pool.starter_node_pool.subnet_ids
  }
}

#----------------------------------------------------------------------------
# LOCALS

locals {
  oke_ocid = oci_containerengine_cluster.starter_oke.id
}
{%- endif %}  

output "oke_ocid" {
  value = local.oke_ocid
}
