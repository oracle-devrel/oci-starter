// ------------------------ Autonomous database -----------------------------
variable "atp_ocid" {}

data "oci_database_autonomous_database" "starter_atp" {
  #Required
  autonomous_database_id = var.atp_ocid
}