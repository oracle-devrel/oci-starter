variable "bastion_ocid" {}

data "oci_core_instance" "starter_bastion" {
  instance_id = var.bastion_ocid
}

# Output the private and public IPs of the instance
output "bastion_private_ips" {
  value = [data.oci_core_instance.starter_bastion.*.private_ip]
}

output "bastion_public_ips" {
  value = [data.oci_core_instance.starter_bastion.*.public_ip]
}
