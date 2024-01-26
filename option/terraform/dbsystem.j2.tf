# Database Cloud
{%- if db_ocid is defined %}
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

{%- else %}   
variable "db_version" {}

variable n_character_set {
  default = "AL16UTF16"
}

variable character_set {
  default = "AL32UTF8"
}

resource "oci_database_db_system" "starter_dbsystem" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = local.lz_database_cmp_ocid
  database_edition    = "##db_edition##"

  db_home {
    database {
      admin_password = var.db_password
      db_name        = substr(var.prefix,0,8)
      pdb_name       = "PDB1"
    }

    // XXX Not sure what happens when a new version is available XXX
    db_version   = var.db_version
    display_name = "${var.prefix}home"
  }

  db_system_options {
    storage_management = "##storage_management##"
  }

  shape                   = "VM.Standard.E4.Flex"
  cpu_core_count          = ##cpu_core_count##
  subnet_id               = data.oci_core_subnet.starter_private_subnet.id
  ssh_public_keys         = [var.ssh_public_key]
  display_name            = "${var.prefix}db"
  hostname                = "${var.prefix}db"
  data_storage_size_in_gb = "256"
  license_model           = var.license_model
  node_count              = ##db_node_count##

  freeform_tags = local.freeform_tags
}

# Compatibility with db_existing.tf 
data "oci_database_db_homes" "starter_db_homes" {
  compartment_id = local.lz_database_cmp_ocid
  db_system_id   = oci_database_db_system.starter_dbsystem.id
}

locals {
  db_compartment_ocid = local.lz_database_cmp_ocid
  db_ocid = oci_database_db_system.starter_dbsystem.id
}
{%- endif %}  

{%- if group_name is not defined %}
data "oci_database_databases" "starter_dbs" {
  compartment_id = local.db_compartment_ocid
  db_home_id     = data.oci_database_db_homes.starter_db_homes.db_homes.0.db_home_id
}

data "oci_database_pluggable_databases" "starter_pdbs" {
  database_id = data.oci_database_databases.starter_dbs.databases.0.id
}

data "oci_database_db_nodes" "starter_nodes" {
  compartment_id = local.db_compartment_ocid 
  db_system_id = local.db_ocid 
}

data "oci_core_vnic" "starter_node_vnic" {
    #Required
    vnic_id = data.oci_database_db_nodes.starter_nodes.db_nodes[0].vnic_id
}

locals {
  # TNS Connect String (Description....)
  db_url = data.oci_database_pluggable_databases.starter_pdbs.pluggable_databases.0.connection_strings.0.pdb_ip_default
  db_host = "todo"
  jdbc_url = format("jdbc:oracle:thin:@%s", local.db_url)
}

{%- endif %}  


