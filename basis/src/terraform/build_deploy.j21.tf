## BUILD
# call ./starter.sh frm build_deploy
resource "null_resource" "build_deploy" {
  provisioner "local-exec" {
    command = <<-EOT
        pwd
        cat target/terraform.tfstate
        export
        ./starter.sh frm build_deploy
        EOT
  }
  depends_on = [
{%- for key in terraform_resources %}
    "{{key}}",
{%- endfor %}    
  ]
}

{%- if terraform_resources_part2.length>0 %}

## TERRAFORM_PART2
# In case like instance_pool, oke, function, container_instance, ...
# More terraform resources need to be created after build_deploy.
data "external" "env_part2" {
  program = ["cat", "target/resource_manager_variables.json"]
  depends_on = [
    null_resource.build_deploy
  ]
}
{%- endif %}
