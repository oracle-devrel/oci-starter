## Copyright (c) 2022, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# Prepopulated variable by Resource Manager
variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}
variable current_user_ocid {}

# variable "user_ocid" {}
# variable "fingerprint" {}
# variable "private_key_path" {}

variable "prefix" {
  default     = "starter"
  description = "Application name. Will be used as prefix to identify resources"
}

variable "oci_username" {
  default="oracleidentitycloudservice/name@domain.com"
}

locals {
  ocir_docker_repository = join("", [lower(lookup(data.oci_identity_regions.current_region.regions[0], "key")), ".ocir.io"])
  ocir_namespace = lookup(data.oci_objectstorage_namespace.ns, "namespace")
}

variable "compartment_id" {}
variable "language" {}
variable "java_framework" {default="SpringBoot"}
variable "java_vm" {default="JDK"}
variable "java_version" {}
variable "vcn_strategy" {}
variable "vcn_ocid" {default=""}
variable "subnet_ocid" {default=""}
variable "ui_strategy" {}
variable "deploy_strategy" {}
variable "kubernetes_strategy" {default=""}
variable "oke_strategy" {default=""}
variable "oke_ocid" {default=""}
variable "db_strategy" {}
variable "db_existing_strategy" {}
variable "atp_ocid" {default=""}
variable "db_ocid" {default=""}
variable "mysql_ocid" {default=""}
variable "db_user" {default="admin"}
variable "db_password" {}
variable "vault_strategy" {}
variable "secret_strategy" { default="" }
variable "vault_ocid" { default="" }
variable "vault_secret_authtoken_ocid" { default="" }
variable "oci_token" { default="" }

