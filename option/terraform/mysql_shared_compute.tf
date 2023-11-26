locals {
    db_host = oci_core_instance.starter_instance.private_ip
    db_port = "3306"
    db_url = format("localhost:%s", local.db_port)
    jdbc_url = format("jdbc:localhost://%s/db1", local.db_host)
}

output "mysql_compute_ip" {
   value = local.db_host
}
