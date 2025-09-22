## Copyright (c) 2023, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
terraform {
  required_providers {
    oci = {
      source = "hashicorp/oci"
      configuration_aliases = [
        oci.home
      ]
    }
  }
}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_regions" "current_region" {
  filter {
    name   = "name"
    values = [var.region]
  }
}

# Identity Domain
variable idcs_domain_name { 
  default = "Default" 
  nullable = false
}
variable idcs_url { default = null }

data "oci_identity_domains" "starter_domains" {
  #Required
  compartment_id = var.tenancy_ocid
  display_name = var.idcs_domain_name
}

locals {
  # Try: LiveLabs has no access to IDCS
  local_idcs_url = try( (var.idcs_url!=null)?var.idcs_url:data.oci_identity_domains.starter_domains.domains[0].url, "" )
}

output "idcs_url" {
  value = local.local_idcs_url
}

# OCI Services
## Available Services
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

locals {
  # ex: Oracle-Linux-7.9-2022.12.15-0
  #     Oracle-Linux-7.9-aarch64-2022.12.15-0
  regex_amd_linux = "^([a-zA-z]+)-([a-zA-z]+)-([\\.0-9]+)-([\\.0-9-]+)$"
  regex_ampere_linux= "^([a-zA-z]+)-([a-zA-z]+)-([\\.0-9]+)-aarch64-([\\.0-9-]+)$"
  regex_linux = (var.instance_shape=="VM.Standard.A1.Flex")?local.regex_ampere_linux:local.regex_amd_linux
  #     Oracle-Linux-Cloud-Developer-8.5-2022.05.22-0
  #     Oracle-Linux-Cloud-Developer-8.5-aarch64-2022.05.22-0
  regex_amd_dev_linux = "^([a-zA-z]+)-([a-zA-z]+)-([a-zA-z]+)-([a-zA-z]+)-([\\.0-9]+)-([\\.0-9-]+)$"
  regex_ampere_dev_linux= "^([a-zA-z]+)-([a-zA-z]+)-([a-zA-z]+)-([a-zA-z]+)-([\\.0-9]+)-aarch64-([\\.0-9-]+)$"
  regex_dev_linux = (var.instance_shape=="VM.Standard.A1.Flex")?local.regex_ampere_dev_linux:local.regex_amd_dev_linux

  regex_shape_amd = "^VM.Standard.E.*Flex$" 
  regex_shape_ampere = "^VM.Standard.A.*Flex$" 
  regex_shape = (var.instance_shape=="VM.Standard.A1.Flex")?local.regex_shape_ampere:local.regex_shape_amd
}

# Get latest Oracle Linux image 
data "oci_core_images" "oraclelinux" {
  compartment_id = var.compartment_ocid
  operating_system = "Oracle Linux"
  operating_system_version = "8"
  filter {
    name = "display_name"
    values = [local.regex_linux]
    regex = true
  }
}

## Object Storage
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

## Availability domains
data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = var.availability_domain_number
}

## Compartment
data "oci_identity_compartment" "compartment" {
  id = var.compartment_ocid
}

# Instance shape
data "oci_core_shapes" "shapes" {
  compartment_id = var.compartment_ocid
  # availability_domain = var.availability_domain_number
  filter {
    name = "name"
    values = [local.regex_shape]
    regex = true
  }  
}

# Random ID
resource "random_string" "id" {
  length  = 4
  special = false
  upper = false
}

# Username (not needed anymore)
# variable username { default=null }
# variable current_user_ocid { default=null }

# data "oci_identity_user" "user" {
#   count = var.username == null ? 1 : 0
#   user_id = var.current_user_ocid
# }

locals {
  local_ocir_host = join("", [lower(lookup(data.oci_identity_regions.current_region.regions[0], "key")), ".ocir.io"])
  ocir_namespace = lookup(data.oci_objectstorage_namespace.ns, "namespace")
  
  # Create a list of shapes
  shape_names = [for shape in data.oci_core_shapes.shapes.shapes : shape.name]
  # Reverse Sort the list of shapes (Goal is to have the latest on the top) 
  reverse_sorted_shape_names = reverse(sort(local.shape_names))
  local_shape = local.reverse_sorted_shape_names[0]

  # username = var.username != null ? var.username : oci_identity_user.user[0].name
  # ocir_username = join( "/", [ coalesce(local.ocir_namespace, "missing_privilege"), local.username ])
}

output "ocir_host" {
  value = local.local_ocir_host
}

output "shape" {
  value = local.local_shape
}