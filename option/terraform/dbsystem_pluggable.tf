data "oci_database_databases" "starter_dbs" {
  compartment_id = local.lz_database_cmp_ocid
  db_home_id     = data.oci_database_db_homes.starter_db_homes.db_homes.0.db_home_id
}

resource "oci_database_pluggable_database" "starter_pluggable_database" {
  #Required
  container_database_id = data.oci_database_databases.starter_dbs.databases.0.id
  pdb_name =  "${var.prefix}pdb"

  pdb_admin_password = var.db_password
  should_pdb_admin_account_be_locked = false
  tde_wallet_password = var.db_password

  freeform_tags = local.freeform_tags
}

data "oci_database_pluggable_databases" "starter_pdbs" {
  database_id = data.oci_database_databases.starter_dbs.databases.0.id
}

locals {
  # TNS Connect String (Description....)
  db_url = oci_database_pluggable_database.starter_pluggable_database.connection_strings.0.pdb_ip_default
  db_host = "todo"
  jdbc_url = format("jdbc:oracle:thin:@%s", local.db_url)
}
