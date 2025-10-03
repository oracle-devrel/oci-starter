{%- if deploy_type == "public_compute" %}
data "oci_core_instance" "starter_bastion" {
  instance_id = oci_core_instance.starter_compute.id
}

{%- elif bastion_ocid is defined %}
variable "bastion_ocid" {
  description = "Existing Bastion (OCI Compute) OCID"     
}

data "oci_core_instance" "starter_bastion" {
  instance_id = var.bastion_ocid
}

{%- else %}

{%- if bastion_type=="bastion_service" %}

#-- Bastion Service ---------------------------------------------------------

resource "oci_bastion_bastion" "starter_bastion" {
  name = "${var.prefix}-bastion"
  bastion_type     = "STANDARD"
  compartment_id   = var.compartment_ocid
  target_subnet_id =  data.oci_core_subnet.starter_app_subnet.id
  freeform_tags = local.freeform_tags      
  client_cidr_block_allow_list = [
    "0.0.0.0/0"
  ]
}

resource "oci_bastion_session" "starter_bastion_session" {
  bastion_id = oci_bastion_bastion.starter_bastion.id
  key_details {
      public_key_content = local.ssh_public_key
  }

  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id = data.oci_core_instance.starter_compute.id
    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = "22"
  }
  key_type = "PUB"
  session_ttl_in_seconds = 3600
  display_name = "${var.prefix}-bastion-session"
}

locals {
  local_bastion_command = oci_bastion_session.starter_bastion_session.ssh_metadata.command
}

output "bastion_command" {
  value = local.local_bastion_command
}

{%- else %}

resource "oci_core_instance" "starter_bastion" {

  availability_domain = local.availability_domain_name
  compartment_id      = local.lz_web_cmp_ocid
  display_name        = "${var.prefix}-bastion"
  shape               = local.shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_shape_config_memory_in_gbs
  }

  create_vnic_details {
    subnet_id                 = data.oci_core_subnet.starter_web_subnet.id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "${var.prefix}-bastion"
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
  }

  source_details {
    source_type = "image"
    # boot_volume_size_in_gbs = "50" 
    source_id   = data.oci_core_images.oraclelinux.images.0.id
  }

  connection {
    agent       = false
    host        = oci_core_instance.starter_bastion.public_ip
    user        = "opc"
    private_key = local.ssh_private_key
  }

  lifecycle {
    ignore_changes = [
      source_details[0].source_id,
      shape
    ]
  }

  freeform_tags = local.freeform_tags   
}

data "oci_core_instance" "starter_bastion" {
  instance_id = oci_core_instance.starter_bastion.id
}
{%- endif %}
{%- endif %}

locals {
  local_bastion_ip = data.oci_core_instance.starter_bastion.public_ip
}

output "bastion_ip" {
  value = local.local_bastion_ip
}
