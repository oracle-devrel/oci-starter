## Copyright (c) 2023, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

# Gets home and current regions
data "oci_identity_tenancy" "tenant_details" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_regions" "current_region" {
  filter {
    name   = "name"
    values = [var.region]
  }
}

data oci_identity_regions regions {
}

locals {
  region_map = {
    for r in data.oci_identity_regions.regions.regions :
    r.key => r.name
  } 
  home_region = lookup(
    local.region_map, 
    data.oci_identity_tenancy.tenant_details.home_region_key
  )
}

# Provider Home Region
provider "oci" {
  alias  = "home"
  region = local.home_region
}

# Gets a list of supported images based on the shape, operating_system and operating_system_version provided
data "oci_core_images" "node_pool_images" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "7.9"
  shape                    = "VM.Standard.E4.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
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

/*
# Oracle-Linux-Cloud-Developer-8.5-2022.05.22-0
# Oracle-Linux-Cloud-Developer-8.5-aarch64-2022.05.22-0
data "oci_core_images" "oracledevlinux" {
  compartment_id = var.tenancy_ocid
  operating_system = "Oracle Linux Cloud Developer"
  operating_system_version = "8"
  filter {
    name = "display_name"
    values = [local.regex_dev_linux]
    regex = true
  }
}

output "oracle-dev-linux-latest-name" {
  value = data.oci_core_images.oracledevlinux.images.0.display_name
}
*/

locals {
  oracle_linux_latest_name = coalesce( data.oci_core_images.oraclelinux.images.0.display_name, "Oracle-Linux-8.8-2023.10.24-0")
}

output "oracle_linux_latest_name" {
  value = local.oracle_linux_latest_name
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

locals {
  ocir_docker_repository = join("", [lower(lookup(data.oci_identity_regions.current_region.regions[0], "key")), ".ocir.io"])
  ocir_namespace = lookup(data.oci_objectstorage_namespace.ns, "namespace")
  ocir_username = join( "/", [ coalesce(local.ocir_namespace, "missing_privilege"), var.username ])
}
