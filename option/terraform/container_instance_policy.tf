resource "oci_identity_dynamic_group" "starter_ci_dyngroup" {
  name           = "${var.prefix}-ci-dyngroup"
  description    = "Starter - All Container Instances"
  compartment_id = var.tenancy_ocid
  matching_rule  = "ALL {resource.type='computecontainerinstance'}"
  freeform_tags = local.freeform_tags
}

resource "oci_identity_policy" "starter-ci_policy" {
  name           = "${var.prefix}-ci-policy"
  description    = "Container instance access to OCIR"
  compartment_id = var.tenancy_ocid
  statements = [
    "allow dynamic-group ${var.prefix}-ci-dyngroup to read repos in tenancy"
  ]
  freeform_tags = local.freeform_tags
}
