variable tenancy_ocid {}
variable region {}
variable compartment_ocid {}
# variable user_ocid {}
variable ssh_public_key {}
variable ssh_private_key {}

# Prefix
variable prefix { default = "starter" }

# Java
variable language { default = "java" }
variable java_version { default = "21" }

variable db_user { default="" }
variable db_password{ default="" }

# Compute Instance size
variable instance_shape { default = "VM.Standard.x86.Generic" }
variable instance_ocpus { default = 1 }
variable instance_shape_config_memory_in_gbs { default = 8 }

# Landing Zones
variable lz_appdev_cmp_ocid { default="" }
variable lz_database_cmp_ocid { default="" }
variable lz_network_cmp_ocid { default="" }
variable lz_security_cmp_ocid { default="" }

# OCIR
variable username { default="" }

# Availability Domain
variable availability_domain_number { default = 1 }

# BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED
variable license_model {
  default="BRING_YOUR_OWN_LICENSE"
}

# Group
variable group_name { default="" }

# Log Group
variable log_group_ocid  { default="" }

# Certificate
variable "certificate_ocid" { default = "" }

locals {
  group_name = var.group_name == "" ? "none" : var.group_name

  # Tags
  freeform_tags = {
    group = local.group_name
    app_prefix = var.prefix
    SSS_stop = "-"
  }
  
  # Landing Zone
  lz_appdev_cmp_ocid = var.lz_appdev_cmp_ocid == "" ? var.compartment_ocid : var.lz_appdev_cmp_ocid
  lz_database_cmp_ocid = var.lz_database_cmp_ocid == "" ? var.compartment_ocid : var.lz_database_cmp_ocid
  lz_network_cmp_ocid = var.lz_network_cmp_ocid == "" ? var.compartment_ocid : var.lz_network_cmp_ocid
  lz_security_cmp_ocid = var.lz_security_cmp_ocid == "" ? var.compartment_ocid : var.lz_security_cmp_ocid
}
