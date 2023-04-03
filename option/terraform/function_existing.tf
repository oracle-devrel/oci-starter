variable fnapp_ocid {}


data "oci_functions_application" "test_application" {
    #Required
    application_id = var.fnapp_ocid
}

locals {
  fnapp_ocid = var.fnapp_ocid
}