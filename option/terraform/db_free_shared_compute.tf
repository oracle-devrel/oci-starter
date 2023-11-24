# DB23c Free in OCI Compute
locals {
  db_free_ip = oci_core_instance.starter_instance.private_ip
  # TNS Connect String (Description....)
  db_url = format("%s:1521/FREEPDB1", local.db_free_ip)
  db_host = "todo"
  jdbc_url = format("jdbc:oracle:thin:@%s", local.db_url)
}

output "db_free_ip" {
   value = local.db_free_ip
}
