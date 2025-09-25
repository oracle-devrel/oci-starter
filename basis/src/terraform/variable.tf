variable tenancy_ocid {}
variable region {}
variable compartment_ocid {}

# Prefix
variable prefix { 
  default = "starter"
  nullable = false
  description= "Prefix added to all created resources"   
}

# Home Region
variable home_region {
  default=null
  description= "OCI Home Region"   
}

# Database user
variable db_user { 
  default = null
  description= "Database Username"   
}
variable db_password { 
  default = null
  description= "Database Password"   
}
# Compute Instance size
variable instance_shape { 
  default = "VM.Standard.x86.Generic"
  description="Instance - Shape"    
  nullable = false
}

variable instance_ocpus { 
  default = 1
  description="Instance - Number of OCPUs"   
  nullable = false
}
variable instance_shape_config_memory_in_gbs { 
  default = 8
  description="Instance - Memory in GBs"   
  nullable = false
}

# Landing Zones
variable lz_web_cmp_ocid { 
  default=null 
  description="Landing Zone - Web Compartment OCID" 
}
variable lz_app_cmp_ocid { 
  default=null 
  description="Landing Zone - Application Compartment OCID" 
}
variable lz_db_cmp_ocid { 
  default=null 
  description="Landing Zone - Database Compartment OCID" 
}
variable lz_serv_cmp_ocid { 
  default=null 
  description="Landing Zone - Services Compartment OCID" 
}
variable lz_network_cmp_ocid { 
  default=null 
  description="Landing Zone - Network Compartment OCID" 
}
variable lz_security_cmp_ocid { 
  default=null 
  description="Landing Zone - Security Compartment OCID" 
}

# Availability Domain
variable availability_domain_number { 
  default = null
  description="Availability Domain"
}

# BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED
variable license_model {
  default = "BRING_YOUR_OWN_LICENSE"
  description = "Type of license (BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED)"
  nullable = false
}

# Group
variable group_name {
  default=null
  description="OCI Starter - Group Name"
}

# Log Group
variable log_group_ocid  { 
  default=null 
  description="LogGroup OCID"  
}

# Certificate
variable "certificate_ocid" {
  default=null 
  description="Certificate OCID"  
}

# Infrastructure as code
variable "infra_as_code" {
  default=null
  description="OCI Starter - Infrastructure as code"
}

# SSH Keys
variable ssh_public_key { 
  default=null
  description="Public SSH Key"
}
variable ssh_private_key {
  default=null
  description="Private SSH Key"
}

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
  value = var.ssh_public_key != null ? "-" : tls_private_key.ssh_key[0].public_key_openssh
}

output "ssh-key-private" {
  value = var.ssh_public_key != null ? "-" : "See Stack / Stack Resources / tls_private_key.ssh_key.private_key_pem"
}

