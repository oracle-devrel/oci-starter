locals {
    db_host = data.oci_mysql_mysql_db_system.starter_mysql.endpoints.0.ip_address 
    db_port = data.oci_mysql_mysql_db_system.starter_mysql.endpoints.0.port
    db_url = format("%s:%s", local.db_host, local.db_port)
    // jdbc:mysql://10.1.1.237/db1?user=root&password=xxxxx
    jdbc_url = format("jdbc:mysql://%s/db1", local.db_host)
}
