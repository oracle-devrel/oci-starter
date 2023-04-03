terraform {
  backend "http" {
    address = "XX_TERRAFORM_STATE_URL_XX"
    update_method = "PUT"
  }
}

# OCI Provider with ResourcePrincipal
provider "oci" {
  auth = "ResourcePrincipal"
  region = "${var.region}"
}
