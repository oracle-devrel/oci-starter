variable "pdb_ocid" {}

data "oci_database_pluggable_database" "starter_pluggable_database" {
    #Required
    pluggable_database_id = var.pdb_ocid
}

locals {
  # TNS Connect String (Description....)
  db_url = data.oci_database_pluggable_database.starter_pluggable_database.connection_strings.0.pdb_ip_default
  db_host = "todo"
  jdbc_url = format("jdbc:oracle:thin:@%s", local.db_url)
}
