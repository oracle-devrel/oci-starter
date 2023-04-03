# OCID of the DBSYSTEM
variable "db_ocid" {}

# OCID of the COMPARTMENT of the DBSYSTEM (usecase where it is <> Landing Zone DB Compartment )
variable "db_compartment_ocid" { default="" }

locals {
  db_compartment_ocid = var.db_compartment_ocid == "" ? local.lz_database_cmp_ocid : var.db_compartment_ocid
}

data "oci_database_db_homes" "starter_db_homes" {
  compartment_id = local.db_compartment_ocid
  db_system_id   = var.db_ocid
}
