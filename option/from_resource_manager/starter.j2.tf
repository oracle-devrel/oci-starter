# starter.tf

resource "null_resource" "before_terraform" {
  provisioner "local-exec" {
    command = "starter.sh before_terraform"
  }
  depends_on = [
    module.terraform_module
  ]
}

data "external" "env" {
  program = ["cat", "target/resource_manager_variables.json"]
  depends_on = [
    before_terraform
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
  user_ocid = var.current_user_ocid

  namespace = data.external.env.result.namespace
  ssh_public_key = data.external.env.result.ssh_public_key
  ssh_private_key = data.external.env.result.ssh_private_key
}

resource "null_resource" "build_deploy" {
  provisioner "local-exec" {
    command = "starter.sh build_deploy"
  }
  depends_on = [
    module.terraform_module
  ]
}

{%- if deploy_type in ["instance_pool", "oke", "function", "container_instance"] %}

data "external" "env2" {
  program = ["cat", "target/resource_manager_variables.json"]
  depends_on = [
    build_deploy
  ]
}

module "terraform_after_build_module" {
  source = "./src/terraform2" # Path to your local module directory

  tenancy_ocid = var.tenancy_ocid
  compartment_ocid = var.compartment_ocid
  region = var.region
  user_ocid = var.current_user_ocid

  namespace = data.external.env2.result.namespace
  ssh_public_key = data.external.env2.result.ssh_public_key
  ssh_private_key = data.external.env2.result.ssh_private_key
}
{%- endif %}

resource "null_resource" "after_build" {
  provisioner "local-exec" {
    command = "starter.sh after_build"
  }
  depends_on = [
{%- if deploy_type in ["instance_pool", "oke", "function", "container_instance"] %}
    module.terraform2_after_build_module
{%- else %}
    build_deploy
{%- endif %}
  ]
}
