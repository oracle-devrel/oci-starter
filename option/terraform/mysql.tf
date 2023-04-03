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

