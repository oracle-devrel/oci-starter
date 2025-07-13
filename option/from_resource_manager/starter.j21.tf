# starter.tf

## VARIABLES

{%- for param in env_params %}
variable "{{ param }}" { default = null }
{%- endfor %}
{%- for key in terraform_variables %}
{%- if key in env_params %}
{%- else %}
variable "{{ key }}" { default = null }
{%- endif %}
{%- endfor %}

## BEFORE TERRAFORM
# Phase: PLAN
# Todo: criteria to check
# - plan, then apply means that it gets executed twice
# - no error raised if plan then apply is executed
# - no ssh password lost or db password reset if plan, apply, plan is done
#   - if no other way, store the settings in an Object Storage or in Vault.
# - if an error happens, the log is visible in the RM logs
# - if no error happens, the log is visible in the RM logs (check if TRACE is needed ??)
data "external" "env" {
  program = ["bash", "-c", "./starter.sh frm before_terraform 1>&2; cat target/resource_manager_variables.json"]
}

resource "null_resource" "log_frm_before_terraform" {
  provisioner "local-exec" {
    command = <<-EOT
        cat target/frm_before_terraform.log
        EOT
  }
  depends_on = [
    data.external.env
  ]   
}

# TERRAFORM 
# Phase: APPLY
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

  depends_on = [
    null_resource.log_frm_before_terraform
  ]   
}

## OUTPUT
# Output in Resource Manager all the OUTPUTs of the module
{%- for key in terraform_outputs %}
output "{{ key }}" {
  value = "${module.terraform_module.{{key}}}"
}

{%- endfor %}

## BUILD
# call ./starter.sh frm build_deploy
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

## TERRAFORM_PART2
# In case like instance_pool, oke, function, container_instance, ...
# A second terraform module need to be called to finish the installation. Ex:
# - instance_pool: from the image of the compute of part1, build the instance pool with several compute and a LN
# - container_instance, function: from docker container of build_deploy, build the real container_instance
# Todo:
# - oke: xxxx
# - check all count= in *.tf
# - is there a need for a part3 ?

data "external" "env_part2" {
  program = ["cat", "target/resource_manager_variables.json"]
  depends_on = [
    null_resource.build_deploy
  ]
}

module "terraform_part2" {
  source = "./src/terraform_part2" # Path to your local module directory

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
  {{key}} = try(data.external.env_part2.result.{{key}}, null)
{%- endif %}
{%- endfor %}

  depends_on = [
    data.external.env_part2
  ]   
}
{%- endif %}

## AFTER_BUILD
# Post terraform
# - ./starter.sh frm after_build
# - run done.sh
# - run custom src/after_done.sh
# Todo:
# - Run always_run really needed ?
# - How to taint a resource in resource manager  
resource "null_resource" "after_build" {
  provisioner "local-exec" {
    command = "cat target/terraform.tfstate; export; ./starter.sh frm after_build"
  }
  depends_on = [
{%- if deploy_type in ["instance_pool", "oke", "function", "container_instance"] %}
    module.terraform_part2
{%- else %}
    null_resource.build_deploy
{%- endif %}
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

