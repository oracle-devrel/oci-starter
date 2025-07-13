resource "oci_functions_function" "starter_fn_function" {
  #Required
  count          = var.fn_image == null ? 0 : 1
  application_id = local.fnapp_ocid
  display_name   = "${var.prefix}-fn-function"
  image          = var.fn_image
  memory_in_mbs  = "2048"
  config = {
    {%- if language == "java" %} 
    JDBC_URL      = var.fn_db_url,
    {%- else %}     
    DB_URL      = var.fn_db_url,
    {%- endif %}     
    DB_USER     = var.db_user,
    DB_PASSWORD = var.db_password,
    {%- if db_type == "nosql" %} 
    TF_VAR_compartment_ocid = var.compartment_ocid,
    TF_VAR_nosql_endpoint = var.nosql_endpoint,
    {%- endif %}     
  }
  #Optional
  timeout_in_seconds = "300"
  trace_config {
    is_enabled = true
  }

  freeform_tags = local.freeform_tags
/*
  # To start faster
  provisioned_concurrency_config {
    strategy = "CONSTANT"
    count = 40
  }
*/    
}
