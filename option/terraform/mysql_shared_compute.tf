locals {
    db_host = oci_core_instance.starter_instance.private_ip
    db_port = "3306"
    db_url = format("%s:%s", local.db_host, local.db_port)
    // jdbc:mysql://10.1.1.237/db1?user=root&password=xxxxx
    jdbc_url = format("jdbc:mysql://%s/db1", local.db_host)
}

output "mysql_compute_ip" {
   value = local.db_host
}
