{%- if compute_ocid is defined %}
variable "compute_ocid" {}

data "oci_core_instance" "starter_compute" {
    instance_id = var.compute_ocid
}

{%- else %}   
resource "oci_core_instance" "starter_compute" {

  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = local.lz_app_cmp_ocid
  display_name        = "${var.prefix}-compute"
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_shape_config_memory_in_gbs
    # baseline_ocpu_utilization = "BASELINE_1_8"
  }

  create_vnic_details {
{%- if deploy_type == "public_compute" %}
    subnet_id                 = data.oci_core_subnet.starter_web_subnet.id
    assign_public_ip          = true
{%- else %}
    subnet_id                 = data.oci_core_subnet.starter_app_subnet.id
    assign_public_ip          = false
{%- endif %}
    display_name              = "Primaryvnic"
    assign_private_dns_record = true
    hostname_label            = "${var.prefix}-compute"
  }

  # XXXX Should be there only for Java
  agent_config {
    plugins_config {
      desired_state =  "ENABLED"
      name = "Oracle Java Management Service"
    }
    plugins_config {
      desired_state =  "ENABLED"
      name = "Management Agent"
    }
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  source_details {
    source_type = "image"
    boot_volume_size_in_gbs = "50" 
    source_id   = data.oci_core_images.oraclelinux.images.0.id
  }

  connection {
    agent       = false
    host        = oci_core_instance.starter_compute.public_ip
    user        = "opc"
    private_key = var.ssh_private_key
  }

  freeform_tags = local.freeform_tags
}

data "oci_core_instance" "starter_compute" {
    instance_id = oci_core_instance.starter_compute.id
}
{%- endif %}   

locals {
  compute_ocid = data.oci_core_instance.starter_compute.id
  compute_public_ip = data.oci_core_instance.starter_compute.public_ip
  compute_private_ip = data.oci_core_instance.starter_compute.private_ip
}

output "compute_ip" {
  value = local.compute_private_ip
}
