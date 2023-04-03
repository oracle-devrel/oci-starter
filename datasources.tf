## Copyright (c) 2022, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

################### Tenancy 
data "oci_identity_tenancy" "tenant_details" {
  tenancy_id = var.tenancy_ocid
  provider   = oci.current_region
}

################### Region 
data "oci_identity_regions" "home_region" {
  filter {
    name   = "key"
    values = [data.oci_identity_tenancy.tenant_details.home_region_key]
  }
  provider = oci.current_region
}

data "oci_identity_regions" "current_region" {
  filter {
    name   = "name"
    values = [var.region]
  }
  provider = oci.current_region
}

################### User 
data "oci_identity_user" "current_user" {
  user_id = var.current_user_ocid
}

locals {
  current_user_name = data.oci_identity_user.current_user.name
}

################### Random 
# Randoms
resource "random_string" "id" {
  length  = 4
  special = false
}

resource "random_id" "tag" {
  byte_length = 2
}

################### ObjectStorage 
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}


#-- Vault -------------------------------------------------------------------
data "oci_kms_vault" "starter_vault" {
  #Required
  count = var.vault_strategy=="Use Existing Vault" ? 1 : 0
  vault_id = var.vault_ocid
}

