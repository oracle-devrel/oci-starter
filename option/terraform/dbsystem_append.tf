data "oci_database_databases" "starter_dbs" {
  compartment_id = local.db_compartment_ocid
  db_home_id     = data.oci_database_db_homes.starter_db_homes.db_homes.0.db_home_id
}

data "oci_database_pluggable_databases" "starter_pdbs" {
  database_id = data.oci_database_databases.starter_dbs.databases.0.id
}

locals {
  # TNS Connect String (Description....)
  db_url = data.oci_database_pluggable_databases.starter_pdbs.pluggable_databases.0.connection_strings.0.pdb_ip_default
  db_host = "todo"
  jdbc_url = format("jdbc:oracle:thin:@%s", local.db_url)
}
