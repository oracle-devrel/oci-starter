# starter.tf

resource "null_resource" "before_terraform4" {
  provisioner "local-exec" {
    command = "pwd; ./starter.sh frm before_terraform; ls -al target; export; echo '----BEFORE ----'; cat target/resource_manager_variables.json; echo '----AFTER ----'; "
  }
  provisioner "local-exec" {
    when = destroy
    command = "pwd; ./starter.sh frm before_terraform; ls -al target; export; echo '----BEFORE ----'; cat target/resource_manager_variables.json; echo '----AFTER ----'; "
  }  
  triggers = {
    always_run = "${timestamp()}"
  }  
}

data "external" "env" {
  program = ["cat", "target/resource_manager_variables.json"]
  depends_on = [
    null_resource.before_terraform4
  ]
}

module "terraform_module" {
  source = "./src/terraform" # Path to your local module directory

  // tenancy_ocid = data.external.env2.result.tenancy_ocid
  // region = data.external.env2.result.region
  // compartment_ocid = data.external.env2.result.compartment_ocid

  tenancy_ocid = var.tenancy_ocid
  compartment_ocid = var.compartment_ocid
  region = var.region

  // namespace = data.external.env.result.namespace
  ssh_public_key = data.external.env.result.ssh_public_key
  ssh_private_key = data.external.env.result.ssh_private_key
  instance_shape = data.external.env.result.instance_shape
}

{%- for key in terraform_outputs %}
output "{{ key }}" {
  value       = "{{ value }}"
}
{%- endfor %}

resource "null_resource" "build_deploy" {
  provisioner "local-exec" {
    command = <<-EOT
{%- for key in terraform_outputs %}
    export {{key.upper()}}=${module.terraform_module.{{key}}}
{%- endfor %}
        cat target/terraform.tfstate
        export
        ./starter.sh frm build_deploy
        EOT
  }
  depends_on = [
    module.terraform_module
  ]

  triggers = {
    always_run = "${timestamp()}"
  }    
}

{%- if deploy_type in ["instance_pool", "oke", "function", "container_instance"] %}

data "external" "env2" {
  program = ["cat", "target/resource_manager_variables.json"]
  depends_on = [
    null_resource.build_deploy
  ]
}

module "terraform_after_build_module" {
  source = "./src/terraform2" # Path to your local module directory

  tenancy_ocid = var.tenancy_ocid
  compartment_ocid = var.compartment_ocid
  region = var.region

  namespace = data.external.env2.result.namespace
  ssh_public_key = data.external.env2.result.ssh_public_key
  ssh_private_key = data.external.env2.result.ssh_private_key
}
{%- endif %}

resource "null_resource" "after_build" {
  provisioner "local-exec" {
    command = "cat target/terraform.tfstate; export; ./starter.sh frm after_build"
  }
  depends_on = [
{%- if deploy_type in ["instance_pool", "oke", "function", "container_instance"] %}
    module.terraform2_after_build_module
{%- else %}
    null_resource.build_deploy
{%- endif %}
  ]

  triggers = {
    always_run = "${timestamp()}"
  }    
}
