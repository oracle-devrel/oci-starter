# Output the private and public IPs of the instance
output "bastion_private_ip" {
  value = oci_core_instance.starter_instance.private_ip
}

output "bastion_public_ip" {
  value = oci_core_instance.starter_instance.public_ip
}
