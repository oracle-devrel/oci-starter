// ------------------------ PostgreSQL -----------------------------
resource "oci_psql_db_system" "starter_psql" {
  compartment_id      = local.lz_database_cmp_ocid
  instance_count = "1"
  system_type = "OCI_OPTIMIZED_STORAGE"

  #Required
  db_version          = "14"
  display_name = "${var.prefix}psql"
  network_details {
    subnet_id = data.oci_core_subnet.starter_private_subnet.id
  }
  shape = "PostgreSQL.VM.Standard.E4.Flex.2.32GB"
  storage_details {
    is_regionally_durable = true
    system_type = "OCI_OPTIMIZED_STORAGE"
  }
  credentials {
    username = "adminUser"
    password_details {
      password_type = "PLAIN_TEXT"
      password = var.db_password
    }
  }
  freeform_tags = local.freeform_tags
}

# Compatibility with plsql_existing.tf 
data "oci_psql_db_system" "starter_psql" {
  #Required
  db_system_id = oci_psql_db_system.starter_psql.id
}