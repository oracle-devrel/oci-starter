# Defines the number of instances to deploy
data "oci_core_instance" "starter_instance" {
    #Required
    instance_id = var.compute_ocid
}

locals {
  compute_ocid = var.compute_ocid
}

# Output the private and public IPs of the instance
output "instance_private_ips" {
  value = [oci_core_instance.starter_instance.private_ip]
}

output "instance_public_ips" {
  value = [oci_core_instance.starter_instance.public_ip]
}

output "ui_url" {
  value = format("http://%s", oci_core_instance.starter_instance.public_ip)
}

