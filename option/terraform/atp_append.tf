// -- Resource Principals ---------------------------------------------------
/*
# This allow the ATP to use OCI PLSQL SDK to use/manage OCI resources

resource "oci_identity_dynamic_group" "starter-atp-dyngroup" {
  name           = "${var.prefix}-atp-dyngroup"
  description    = "ATP Dyngroup"
  compartment_id = var.tenancy_ocid
  matching_rule  = "resource.id = '${data.oci_database_autonomous_database.starter_atp.autonomous_database_id}'"
}

resource "oci_identity_policy" "starter-policy" {
  name           = "${var.prefix}-atp-policy"
  description    = "${var.prefix} atp policy"
  compartment_id = var.tenancy_ocid

  statements = [
    "Allow dynamic-group ${var.prefix}-atp-dyngroup to manage objects in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${var.prefix}-atp-dyngroup to manage all-resources in tenancy"
  ]
}
*/

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

