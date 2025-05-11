variable docker_image_ui {
    default=""
}

variable docker_image_app {
    default=""
}

{%- if db_type == "nosql" %} 
variable nosql_endpoint {}
{%- endif %} 

resource oci_container_instances_container_instance starter_container_instance {
  count = var.docker_image_ui == "" ? 0 : 1
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = local.lz_app_cmp_ocid  
  container_restart_policy = "ALWAYS"
  containers {
    display_name = "app"
    image_url = var.docker_image_app
    is_resource_principal_disabled = "false"
    environment_variables = {
      {%- if db_type != "none" %} 
      "DB_URL" = local.db_url,
      "JDBC_URL" = local.jdbc_url,
      "DB_USER" = var.db_user,
      "DB_PASSWORD" = var.db_password,
      "JAVAX_SQL_DATASOURCE_DS1_DATASOURCE_URL" = local.jdbc_url
      {%- endif %} 
      {%- if db_type == "nosql" %} 
      "TF_VAR_compartment_ocid" = var.compartment_ocid,
      "TF_VAR_nosql_endpoint" = var.nosql_endpoint,
      {%- endif %} 
    }    
  }
  containers {
    display_name = "ui"
    image_url = var.docker_image_ui
    is_resource_principal_disabled = "false"
  }  
  display_name = "${var.prefix}-ci"
  graceful_shutdown_timeout_in_seconds = "0"
  {%- if shape == "ampere" %}
  shape                                = "CI.Standard.A1.Flex"
  {%- else %}
  shape                                = "CI.Standard.E4.Flex"
  {%- endif %}  
  shape_config {
    memory_in_gbs = "4"
    ocpus         = "1"
  }
  state = "ACTIVE"
  vnics {
    display_name           = "${var.prefix}-ci"
    hostname_label         = "${var.prefix}-ci"
    skip_source_dest_check = "true"
    subnet_id              = data.oci_core_subnet.starter_app_subnet.id
  }
  freeform_tags = local.freeform_tags    
}

# Store the containers in the APP Compartment
resource "random_string" "repo_prefix" {
  length  = 8
  numeric  = false
  special = false
  upper = false
}

resource "oci_artifacts_container_repository" "starter_repo_app" {
  compartment_id = local.lz_app_cmp_ocid  
  display_name   = "${random_string.repo_prefix.result}/${var.prefix}-app"
  freeform_tags = local.freeform_tags    
}

resource "oci_artifacts_container_repository" "starter_repo_ui" {
  compartment_id = local.lz_app_cmp_ocid  
  display_name   = "${random_string.repo_prefix.result}/${var.prefix}-ui"
  freeform_tags = local.freeform_tags    
}

output "repo_app" {
  value = oci_artifacts_container_repository.starter_repo_app.display_name
}

output "repo_ui" {
  value = oci_artifacts_container_repository.starter_repo_ui.display_name
}
