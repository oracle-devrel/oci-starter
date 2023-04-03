variable "mysql_ocid" {}

data "oci_mysql_mysql_db_system" "starter_mysql" {
    #Required
    db_system_id = var.mysql_ocid
}