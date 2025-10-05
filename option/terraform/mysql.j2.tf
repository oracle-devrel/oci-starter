{%- if mysql_ocid is defined %}
variable "mysql_ocid" {
  description = "Existing MySQL Database OCID"
}

data "oci_mysql_mysql_db_system" "starter_mysql" {
    #Required
    db_system_id = var.mysql_ocid
}

{%- else %}   
resource "oci_mysql_mysql_db_system" "starter_mysql" {
  display_name        = "${var.prefix}-mysql"

  admin_username      = "root"
  admin_password      = var.db_password
  availability_domain = local.availability_domain_name
  compartment_id      = local.lz_db_cmp_ocid
  shape_name          = "MySQL.2"
  subnet_id           = data.oci_core_subnet.starter_db_subnet.id
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
    local_db_url = format("%s:%s", local.db_host, local.db_port)
    // jdbc:mysql://10.1.1.237/db1?user=root&password=xxxxx
    local_jdbc_url = format("jdbc:mysql://%s/db1", local.db_host)
}
{%- endif %}  
