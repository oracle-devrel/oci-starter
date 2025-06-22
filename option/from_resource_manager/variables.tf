## Copyright (c) 2023, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# Prepopulated variable by Resource Manager
variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}
# variable "current_user_ocid" {}

# variable "user_ocid" {}
# variable "fingerprint" {}
# variable "private_key_path" {}

variable "prefix" {
  default     = "starter"
  description = "Application name. Will be used as prefix to identify resources"
}

