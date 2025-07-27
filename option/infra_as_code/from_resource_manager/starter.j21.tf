# starter.tf

## Env Variables
{%- for param in env_params %}
variable "{{ param }}" { default = null }
{%- endfor %}

## Terraform Variables
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
  project_dir = "."

  providers = {
    oci.home = oci.home
  }

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


