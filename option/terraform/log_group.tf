resource "oci_logging_log_group" "starter_log_group" {
  #Required
  compartment_id = local.lz_security_cmp_ocid
  display_name   = "${var.prefix}-log-group"

  freeform_tags = local.freeform_tags
}