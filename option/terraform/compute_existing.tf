# Existing Compute
variable "compute_ocid" {}

data "oci_core_instance" "starter_instance" {
    #Required
    instance_id = var.compute_ocid
}

locals {
  compute_ocid = var.compute_ocid
  compute_private_ip = data.oci_core_instance.starter_instance.private_ip
}

output "compute_ip" {
  value = data.oci_core_instance.starter_instance.public_ip
}
