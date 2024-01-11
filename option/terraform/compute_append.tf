# Output the public IP of the instance
output "compute_ip" {
  value = local.compute_public_ip
}
