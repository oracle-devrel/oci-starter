variable tenancy_ocid {}
variable region {}
variable compartment_ocid {}

# Prefix
variable prefix { 
  default = "starter"
  nullable = false
}

# Java
variable language { 
  default = "java" 
  nullable = false
}

# Java Version
variable java_version { 
  default = "21"
  nullable = false
}

# Home Region
variable home_region {
  default=null
}

# Database user
variable db_user { default=null }
variable db_password{ default=null }

# Compute Instance size
variable instance_shape { 
  default = "VM.Standard.x86.Generic" 
  nullable = false
}
variable instance_ocpus { 
  default = 1
  nullable = false
}
variable instance_shape_config_memory_in_gbs { 
  default = 8
  nullable = false
}

# Landing Zones
variable lz_web_cmp_ocid { default=null }
variable lz_app_cmp_ocid { default=null }
variable lz_db_cmp_ocid { default=null }
variable lz_serv_cmp_ocid { default=null }
variable lz_network_cmp_ocid { default=null }
variable lz_security_cmp_ocid { default=null }

# Availability Domain
variable availability_domain_number { 
  default = "1"
  nullable = false
  description="Availability Domain"
}

# BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED
variable license_model {
  default="BRING_YOUR_OWN_LICENSE"
  nullable = false
}

# Deploy Type
variable deploy_type { default=null }

# UI Type
variable ui_type { default=null }

# Database Type
variable db_type { default=null }

# Group
variable group_name { default=null }

# Log Group
variable log_group_ocid  { default=null }

# Certificate
variable "certificate_ocid" { default=null }

# Infrastructure as code
variable "infra_as_code" { default=null }

# SSH Keys
variable ssh_public_key { default=null }
variable ssh_private_key { default=null }

resource "tls_private_key" "ssh_key" {
  count = var.ssh_public_key == null ? 1 : 0
  algorithm   = "RSA"
  rsa_bits = "2048"
}

locals {
  group_name = var.group_name == null ? "none" : var.group_name

  # Tags
  freeform_tags = {
    group = local.group_name
    app_prefix = var.prefix
    # 3s_not_stop = "-"
    path = path.cwd
  }
  
  # Landing Zone
  lz_web_cmp_ocid = var.lz_web_cmp_ocid == null ? var.compartment_ocid : var.lz_web_cmp_ocid
  lz_app_cmp_ocid = var.lz_app_cmp_ocid == null ? var.compartment_ocid : var.lz_app_cmp_ocid
  lz_db_cmp_ocid = var.lz_db_cmp_ocid == null ? var.compartment_ocid : var.lz_db_cmp_ocid
  lz_serv_cmp_ocid = var.lz_serv_cmp_ocid == null ? var.compartment_ocid : var.lz_serv_cmp_ocid
  lz_network_cmp_ocid = var.lz_network_cmp_ocid == null ? var.compartment_ocid : var.lz_network_cmp_ocid
  lz_security_cmp_ocid =var.lz_security_cmp_ocid == null ? var.compartment_ocid : var.lz_security_cmp_ocid

  # SSH Key
  ssh_public_key  = var.ssh_public_key != null ? var.ssh_public_key  : tls_private_key.ssh_key[0].public_key_openssh
  ssh_private_key = var.ssh_public_key != null ? var.ssh_private_key : tls_private_key.ssh_key[0].private_key_pem
}

output "ssh-key-public" {
  value = var.ssh_public_key != null ? "Created" : "-"
}

output "ssh-key-private" {
  value = var.ssh_public_key != null ? "Created" : "-"
  sensitive = true 
}

