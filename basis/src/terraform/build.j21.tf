## BUILD_DEPLOY
data "external" "env_part2" {
  program = ["bash", "-c", "./starter.sh frm build_deploy 1>&2; cat target/resource_manager_variables.json"]
  depends_on = [
{%- for key in terraform_resources %}
    {{key}},
{%- endfor %}    
  ]
}

resource "null_resource" "log_frm_build_deploy" {
  provisioner "local-exec" {
    command = <<-EOT
        cat target/frm_build_deploy.log
        EOT
  }
  depends_on = [ data.external.env_part2 ]   

  triggers = {
    always_run = "${timestamp()}"
  }    
}

## AFTER_BUILD
# Last action at the end of the build
resource "null_resource" "after_build" {
  provisioner "local-exec" {
    command = "cat target/terraform.tfstate; export; ./starter.sh frm after_build"
  }
  depends_on = [
{%- for key in terraform_resources_part2 %}
    {{key}},
{%- endfor %}   
    null_resource.log_frm_build_deploy   
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