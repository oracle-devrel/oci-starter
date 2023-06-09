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

    // XXX The last version should be dynamic
    db_version   = "21.0.0.0"
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