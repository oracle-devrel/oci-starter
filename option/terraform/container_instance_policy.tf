resource "oci_identity_policy" "starter-ci_policy" {
  provider       = oci.home
  name           = "${var.prefix}-ci-policy"
  description    = "Container instance access to OCIR"
  compartment_id = var.tenancy_ocid
  statements = [
     "ALLOW ANY-USER to read repos in tenancy WHERE ALL {request.principal.type='computecontainerinstance'}"
  ]
  freeform_tags = local.freeform_tags
}
