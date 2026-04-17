# Gets home and current regions
data "oci_identity_tenancy" "tenant_details" {
  tenancy_id = var.tenancy_ocid
}

data oci_identity_regions regions {
}

# HOME REGION
locals {
  region_map = {
    for r in data.oci_identity_regions.regions.regions :
    r.key => r.name
  } 
  # - Try to read from tenancy details
  # - If no access to it, use home_region that can be read in OCI Cloud Shell
  # - Else use the current region
  # - If for some reasons, it does not work. Please add "home_region=xxx" in terraform.vars
  home_region = coalesce( try( lookup( local.region_map, data.oci_identity_tenancy.tenant_details.home_region_key ), var.home_region ), var.region )
}

# Provider Home Region
provider "oci" {
  alias  = "home"
  region = local.home_region
}