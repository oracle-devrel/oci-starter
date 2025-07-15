## BUILD_DEPLOY
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
    {{key}},
{%- endfor %}    
  ]
}

{%- if terraform_resources_part2|length>0 %}
# PART2
#
# In case like instance_pool, oke, function, container_instance, ...
# More terraform resources need to be created after build_deploy.
# Reread the env viables
data "external" "env_part2" {
  program = ["cat", "target/resource_manager_variables.json"]
  depends_on = [
    null_resource.build_deploy
  ]
}
{%- endif %}

## AFTER_BUILD
# Last action at the end of the build
resource "null_resource" "after_build" {
  provisioner "local-exec" {
    command = "cat target/terraform.tfstate; export; ./starter.sh frm after_build"
  }
  depends_on = [
    null_resource.build_deploy
{%- for key in terraform_resources_part2 %}
    {{key}},
{%- endfor %}      
  ]

  provisioner "local-exec" {
      when = destroy    
      command = <<-EOT
        ./starter.sh destroy --called_by_resource_manager
        EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }    
}