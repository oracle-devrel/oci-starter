# Database Cloud
{%- if pdb_ocid is defined %}
variable "pdb_ocid" {}

data "oci_database_pluggable_database" "starter_pluggable_database" {
    pluggable_database_id = var.pdb_ocid
}

{%- else %}   
# OCID of the DBSYSTEM
variable "db_ocid" {}

# OCID of the COMPARTMENT of the DBSYSTEM (usecase where it is <> Landing Zone DB Compartment )
variable "db_compartment_ocid" { default="" }

locals {
  db_compartment_ocid = var.db_compartment_ocid == "" ? local.lz_database_cmp_ocid : var.db_compartment_ocid
  db_ocid = var.db_ocid
}

data "oci_database_db_homes" "starter_db_homes" {
  compartment_id = local.db_compartment_ocid
  db_system_id   = var.db_ocid
}

data "oci_database_databases" "starter_dbs" {
  compartment_id = local.lz_database_cmp_ocid
  db_home_id     = data.oci_database_db_homes.starter_db_homes.db_homes.0.db_home_id
}

resource "oci_database_pluggable_database" "starter_pluggable_database" {
  #Required
  container_database_id = data.oci_database_databases.starter_dbs.databases.0.id
  pdb_name = replace(substr("${var.prefix}pdb", 0, 29), "-", "_")

  pdb_admin_password = var.db_password
  should_pdb_admin_account_be_locked = false
  tde_wallet_password = var.db_password

  freeform_tags = local.freeform_tags
}

data "oci_database_pluggable_databases" "starter_pdbs" {
  database_id = data.oci_database_databases.starter_dbs.databases.0.id
}

data "oci_database_pluggable_database" "starter_pluggable_database" {
  pluggable_database_id = oci_database_pluggable_database.starter_pluggable_database.id
}
{%- endif %}   

locals {
  # TNS Connect String (Description....)
  db_url = data.oci_database_pluggable_database.starter_pluggable_database.connection_strings.0.pdb_ip_default
  db_host = "todo"
  jdbc_url = format("jdbc:oracle:thin:@%s", local.db_url)
}
