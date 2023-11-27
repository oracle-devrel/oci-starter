variable "bastion_ocid" {}

data "oci_core_instance" "starter_bastion" {
  instance_id = var.bastion_ocid
}

output "bastion_public_ip" {
  value = data.oci_core_instance.starter_bastion.public_ip
}
