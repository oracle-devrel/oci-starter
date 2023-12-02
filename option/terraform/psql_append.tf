locals {
    db_host = data.oci_psql_db_system.starter_psql.endpoints.0.ip_address 
    db_port = data.ooci_psql_db_system.starter_psql.endpoints.0.port
    db_url = format("%s:%s", local.db_host, local.db_port)
    // jdbc:postgresql://localhost:5432/db1
    jdbc_url = format("jdbc:postgresql://%s:%s/db1", local.db_host, local.db_port )
}
