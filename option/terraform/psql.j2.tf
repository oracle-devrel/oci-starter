// ------------------------ PostgreSQL -----------------------------
{%- if psql_ocid is defined %}
variable "psql_ocid" {
  description = "Existing PostgreSQL OCID"
}

# Compatibility with postgresql_existing.tf 
data "oci_psql_db_system" "starter_psql" {
  #Required
  db_system_id =  var.psql_ocid
}

{%- else %}   
resource "oci_psql_db_system" "starter_psql" {
  compartment_id      = local.lz_db_cmp_ocid
  instance_count = "1"
  system_type = "OCI_OPTIMIZED_STORAGE"

  #Required
  db_version          = "16"
  display_name = "${var.prefix}psql"
  network_details {
    subnet_id = data.oci_core_subnet.starter_db_subnet.id
  }
  shape = "PostgreSQL.VM.Standard.E5.Flex"
  instance_ocpu_count = 1
  storage_details {
    is_regionally_durable = true
    # availability_domain = local.availability_domain_name
    system_type = "OCI_OPTIMIZED_STORAGE"
  }
  credentials {
    username = "postgres"
    password_details {
      password_type = "PLAIN_TEXT"
      password = var.db_password
    }
  }
  freeform_tags = local.freeform_tags
}

# Compatibility with plsql_existing.tf 
data "oci_psql_db_system" "starter_psql" {
  #Required
  db_system_id = oci_psql_db_system.starter_psql.id
}
{%- endif %}  

{%- if group_name is not defined %}
locals {
    db_host = data.oci_psql_db_system.starter_psql.network_details[0].primary_db_endpoint_private_ip
    db_port = "5432"
    // jdbc:postgresql://localhost:5432/postgres
    local_db_url = local.db_host
    local_jdbc_url = format("jdbc:postgresql://%s:%s/postgres", local.db_host, local.db_port )
}
{%- endif %}  

