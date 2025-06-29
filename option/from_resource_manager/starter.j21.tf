# starter.tf

## VARIABLES

{%- for param in env_params %}
variable "{{ param }}" { default = null }
{%- endfor %}

## BEFORE TERRAFORM
# resource "null_resource" "before_terraform" {
#  provisioner "local-exec" {
#    command = "pwd; ./starter.sh frm before_terraform; ls -al target; export; echo '----BEFORE ----'; cat target/resource_manager_variables.json; echo '----AFTER ----'; "
#  }
#  provisioner "local-exec" {
#    when = destroy
#    command = "pwd; ./starter.sh frm before_terraform; ls -al target; export; echo '----BEFORE ----'; cat target/resource_manager_variables.json; echo '----AFTER ----'; "
#  }  
#  triggers = {
#    always_run = "${timestamp()}"
#  }  
#}

data "external" "env" {
  program = ["bash", "-c", "./starter.sh frm before_terraform 1>&2; cat target/resource_manager_variables.json"]
#  depends_on = [
#    null_resource.before_terraform
#  ]
}

module "terraform_module" {
  source = "./src/terraform" # Path to your local module directory
  # tenancy_ocid = var.tenancy_ocid
  # compartment_ocid = var.compartment_ocid
  # region = var.region
  # Pass all the variable defined in src/terraform. If the value is not defined, it will use the default value in the module.
  # Issues: 
  # - ssh_public_key
  # - ssh_private_key - Solution Cloud Init... starts then wait
  #                   - Upload some files to an object storage
  #                   - Down them and execute them (*)
  # - instance_shape  - use data to find out what shape is available ?? 
  #                   - no way to detect Luna nor LiveLabs... 
  # - availability_domain_number -  issue for free compute shape
  # - db_password     - todo check the complexity in ./starter.sh rm before_terraform
  # - certificate_ocid - XXX in shared_bash - retrieved in different way based on the scenario...
  # - home_region - XXX in shared_bash
{%- for key in terraform_variables %}
{%- if key in env_params %}
  {{key}} = var.{{key}}
{%- elif key in ["lz_web_cmp_ocid", 
                 "lz_app_cmp_ocid", 
                 "lz_db_cmp_ocid",
                 "lz_serv_cmp_ocid", 
                 "lz_network_cmp_ocid", 
                 "lz_security_cmp_ocid",
                 "log_group_ocid",                 
                 "instance_ocpus", 
                 "instance_shape_config_memory_in_gbs",
                 "java_version",
                 "java_framework",
                 "group_name",
                 "idcs_domain_name",
                 "idcs_url",
                 "db_user",
                 "db_password" ] %}
  {{key}} = try( var.{{key}}, null )
{%- else %}
  {{key}} = try(data.external.env.result.{{key}}, null)
{%- endif %}
{%- endfor %}
}

{%- for key in terraform_outputs %}
output "{{ key }}" {
  value = "${module.terraform_module.{{key}}}"
}
{%- endfor %}

resource "null_resource" "build_deploy" {
  provisioner "local-exec" {
    command = <<-EOT
{%- for key in terraform_outputs %}
        export output_{{key}}="${module.terraform_module.{{key}}}"
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
