resource "oci_identity_dynamic_group" "starter-atp-dyngroup" {
  name           = "${var.prefix}-atp-dyngroup"
  description    = "ATP Dyngroup"
  compartment_id = var.tenancy_ocid
  matching_rule  = "ALL {resource.id = '${data.oci_database_autonomous_database.starter_atp.autonomous_database_id}'"
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