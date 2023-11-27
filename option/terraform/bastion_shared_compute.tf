output "bastion_public_ip" {
  value = oci_core_instance.starter_instance.public_ip
}
