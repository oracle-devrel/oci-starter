// ------------------------ Autonomous database -----------------------------
{%- if atp_ocid is defined %}
variable "atp_ocid" {}

data "oci_database_autonomous_database" "starter_atp" {
  #Required
  autonomous_database_id = var.atp_ocid
}

{%- else %}   
resource "random_string" "id" {
  length  = 4
  special = false
  upper = false
}

resource "oci_database_autonomous_database" "starter_atp" {
  #Required
  admin_password           = var.db_password
  compartment_id           = local.lz_database_cmp_ocid
  cpu_core_count           = "1"
  data_storage_size_in_tbs = "1"
  # Random name to have several OCI Starter ATP named (starteratpxxxx) on the same Tenancy (Ex: livelabs)
  db_name                  = "${var.prefix}atp${random_string.id.result}"

  #Optional
  db_workload                                    = "OLTP"
  display_name                                   = "${var.prefix}atp"
  is_auto_scaling_enabled                        = "false"
  license_model                                  = var.license_model
  is_preview_version_with_service_terms_accepted = "false"
  # XXXXX  
  #  whitelisted_ips                             = [ data.oci_core_vcn.starter_vcn.id ]
  # whitelisted_ips                              = [ "0.0.0.0/0" ]
  subnet_id                                      = data.oci_core_subnet.starter_private_subnet.id
  is_mtls_connection_required                    = false
  freeform_tags = local.freeform_tags
}

# Compatibility with atp_existing.tf 
data "oci_database_autonomous_database" "starter_atp" {
  #Required
  autonomous_database_id = oci_database_autonomous_database.starter_atp.id
}
{%- endif %}

{%- if group_name is not defined %}
// -- Locals ----------------------------------------------------------------
locals {
  # Create List of 'name' values from source objet list
  list_profiles = [for v in data.oci_database_autonomous_database.starter_atp.connection_strings[0].profiles : format("%s/%s",v.protocol,v.consumer_group)]
  # Get index for 'name' equal to "Dan"
  index_profile = index(local.list_profiles, "TCPS/MEDIUM")
  db_url = replace(data.oci_database_autonomous_database.starter_atp.connection_strings[0].profiles[local.index_profile].value, " ", "")
  jdbc_url = format("jdbc:oracle:thin:@%s", local.db_url)
  # Create List of 'name' values from source objet list
  ords_url = replace(data.oci_database_autonomous_database.starter_atp.connection_urls[0].apex_url, "ords/apex", "ords" )
}

output "ords_url" {
  value = local.ords_url
}

// -- Resource Principals ---------------------------------------------------
/*
# This allow the ATP to use OCI PLSQL SDK to use/manage OCI resources

resource "oci_identity_dynamic_group" "starter-atp-dyngroup" {
  provider       = oci.home 
  name           = "${var.prefix}-atp-dyngroup"
  description    = "ATP Dyngroup"
  compartment_id = var.tenancy_ocid
  matching_rule  = "resource.id = '${data.oci_database_autonomous_database.starter_atp.autonomous_database_id}'"
}

resource "oci_identity_policy" "starter-policy" {
  provider       = oci.home
  name           = "${var.prefix}-atp-policy"
  description    = "${var.prefix} atp policy"
  compartment_id = var.tenancy_ocid

  statements = [
    "Allow dynamic-group ${var.prefix}-atp-dyngroup to manage objects in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${var.prefix}-atp-dyngroup to manage all-resources in tenancy"
  ]
}
*/
{%- endif %}  
