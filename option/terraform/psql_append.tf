locals {
    db_host = data.oci_psql_db_system.starter_psql.network_details[0].primary_db_endpoint_private_ip
    db_port = "5432"
    db_url = local.db_host
    // jdbc:postgresql://localhost:5432/postgres
    jdbc_url = format("jdbc:postgresql://%s:%s/postgres", local.db_host, local.db_port )
}
