resource "oci_database_autonomous_database" "starter_atp" {
  #Required
  admin_password           = var.db_password
  compartment_id           = local.lz_database_cmp_ocid
  cpu_core_count           = "1"
  data_storage_size_in_tbs = "1"
  db_name                  = "${var.prefix}atp"

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