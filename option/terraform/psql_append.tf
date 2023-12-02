locals {
    db_host = data.oci_psql_db_system.starter_psql.network_details.primary_db_endpoint_private_ip
    db_port = "5432"
    db_url = format("%s:%s", local.db_host, local.db_port)
    // jdbc:postgresql://localhost:5432/db1
    jdbc_url = format("jdbc:postgresql://%s:%s/db1", local.db_host, local.db_port )
}
