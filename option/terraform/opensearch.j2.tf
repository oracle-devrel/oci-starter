{%- if opensearch_ocid is defined %}
variable "opensearch_ocid" {}

data "oci_opensearch_opensearch_cluster" "starter_opensearch" {
    #Required
    opensearch_cluster_id = var.opensearch_ocid
}

{%- else %}   
resource "oci_identity_policy" "starter_opensearch_policy" {
  name           = "${var.prefix}-policy"
  description    = "${var.prefix} policy"
  compartment_id = local.lz_appdev_cmp_ocid

  statements = [
    "Allow service opensearch to manage vnics in compartment id ${local.lz_appdev_cmp_ocid}",
    "Allow service opensearch to use subnets in compartment id ${local.lz_appdev_cmp_ocid}",
    "Allow service opensearch to use network-security-groups in compartment id ${local.lz_appdev_cmp_ocid}",
    "Allow service opensearch to manage vcns in compartment id ${local.lz_appdev_cmp_ocid}",
  ]
}

resource "oci_opensearch_opensearch_cluster" "starter_opensearch" {
  depends_on = [oci_identity_policy.starter_opensearch_policy]

  #Required
  compartment_id                     = local.lz_appdev_cmp_ocid
  data_node_count                    = 1
  data_node_host_memory_gb           = 32
  data_node_host_ocpu_count          = 1
  data_node_host_type                = "FLEX"
  data_node_storage_gb               = 50
  display_name                       = "${var.prefix}-opensearch"
  master_node_count                  = 1
  master_node_host_memory_gb         = 24
  master_node_host_ocpu_count        = 1
  master_node_host_type              = "FLEX"
  opendashboard_node_count           = 1
  opendashboard_node_host_memory_gb  = 16
  opendashboard_node_host_ocpu_count = 1
  software_version                   = "2.11.0"
  subnet_compartment_id              = local.lz_network_cmp_ocid
  subnet_id                          = data.oci_core_subnet.starter_private_subnet.id
  vcn_compartment_id                 = local.lz_network_cmp_ocid
  vcn_id                             = data.oci_core_vcn.starter_vcn.id

  // security_mode                     = "ENFORCING"
  // security_master_user_name         = var.security_master_user_name
  // security_master_user_password_hash = var.security_master_user_password_hash  
}

data "oci_opensearch_opensearch_cluster" "starter_opensearch" {
    #Required
    opensearch_cluster_id = oci_opensearch_opensearch_cluster.starter_opensearch.id
}
{%- endif %}  

{%- if group_name is not defined %}
locals {
  # TNS Connect String (Description....)
  db_url = data.oci_opensearch_opensearch_cluster.starter_opensearch.opensearch_fqdn
  db_port = "9200"
  db_host = local.db_url
  # jdbc_url = format("jdbc:opensearch://https://%s:9200/?hostnameVerification=false&trustSelfSigned=true", local.db_url)
  jdbc_url = format("jdbc:opensearch://https://%s:9200/?hostnameVerification=false", local.db_url)
}
{%- endif %}  

