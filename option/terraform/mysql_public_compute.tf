locals {
    db_host = oci_core_instance.starter_compute.private_ip
    db_port = "3306"
    local_db_url = format("localhost:%s", local.db_port)
    local_jdbc_url = "jdbc:mysql://localhost/db1" 
    local_mysql_compute_ip = db_host
}

output "mysql_compute_ip" {
   value = local.local_mysql_compute_ip
}
