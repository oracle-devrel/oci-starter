
variable "vcn_ocid" {}
variable "public_subnet_ocid" {}
variable "private_subnet_ocid" {}

data "oci_core_vcn" "starter_vcn" {
  vcn_id = var.vcn_ocid
}

data "oci_core_subnet" "starter_public_subnet" {
  subnet_id = var.public_subnet_ocid
}

data "oci_core_subnet" "starter_private_subnet" {
  subnet_id = var.private_subnet_ocid
}


