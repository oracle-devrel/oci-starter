// ------------------------ PostgreSQL -----------------------------
variable "psql_ocid" {}

data "oci_database_autonomous_database" "starter_atp" {
  #Required
  autonomous_database_id = var.atp_ocid
}

# Compatibility with postgresql_existing.tf 
data "oci_psql_db_system" "starter_psql" {
  #Required
  db_system_id =  var.psql_ocid
}