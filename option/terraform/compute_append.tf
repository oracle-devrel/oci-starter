# Output the public IP of the instance
output "compute_ip" {
  value = local.compute_public_ip
}

locals {
  dns_ip = local.compute_public_ip
}

output "ui_url" {
  value = format("http://%s", local.compute_public_ip) 
}
