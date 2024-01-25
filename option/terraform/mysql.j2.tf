{%- if mysql_ocid is defined %}
variable "mysql_ocid" {}

data "oci_mysql_mysql_db_system" "starter_mysql" {
    #Required
    db_system_id = var.mysql_ocid
}

{%- else %}   
resource "oci_mysql_mysql_db_system" "starter_mysql" {
  display_name        = "${var.prefix}-mysql"

  admin_password      = var.db_password
  admin_username      = var.db_user == "" ? "root": var.db_user 
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = local.lz_database_cmp_ocid
  shape_name          = "MySQL.VM.Standard.E4.1.8GB"
  subnet_id           = data.oci_core_subnet.starter_private_subnet.id
  freeform_tags       = local.freeform_tags
}

# Compatibility with mysql_existing.tf 
data "oci_mysql_mysql_db_system" "starter_mysql" {
    #Required
    db_system_id = oci_mysql_mysql_db_system.starter_mysql.id
}
{%- endif %}  

{%- if group_name is not defined %}
locals {
    db_host = data.oci_mysql_mysql_db_system.starter_mysql.endpoints.0.ip_address 
    db_port = data.oci_mysql_mysql_db_system.starter_mysql.endpoints.0.port
    db_url = format("%s:%s", local.db_host, local.db_port)
    // jdbc:mysql://10.1.1.237/db1?user=root&password=xxxxx
    jdbc_url = format("jdbc:mysql://%s/db1", local.db_host)
}
{%- endif %}  
