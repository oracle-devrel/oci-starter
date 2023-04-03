
variable git_url {}

locals {
  api_git_tags = {
      group = local.group_name
      app_prefix = var.prefix

      api_icon = var.language
      api_git_url = var.git_url 
      api_git_spec_path = "src/app/openapi_spec.yaml"
      api_git_spec_type = "OpenAPI"
      api_git_endpoint_path = "src/terraform/apigw_existing.tf"
      api_endpoint_url = "app/dept"
  }
  api_tags = var.git_url !=""? local.api_git_tags:local.freeform_tags
}

