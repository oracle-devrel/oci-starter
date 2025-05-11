# Store the containers in the APP Compartment
# Avoid container's name conflict by adding a random prefix
resource "random_string" "container_prefix" {
  length  = 8
  numeric  = false
  special = false
  upper = false
}

resource "oci_artifacts_container_repository" "starter_repo_app" {
  compartment_id = local.lz_app_cmp_ocid  
  display_name   = "${random_string.container_prefix.result}/${var.prefix}-app"
  freeform_tags = local.freeform_tags    
}

resource "oci_artifacts_container_repository" "starter_repo_ui" {
  compartment_id = local.lz_app_cmp_ocid  
  display_name   = "${random_string.container_prefix.result}/${var.prefix}-ui"
  freeform_tags = local.freeform_tags    
}

output "container_prefix" {
  value = random_string.container_prefix.result
}