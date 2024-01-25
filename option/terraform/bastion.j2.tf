{%- if db_install == "shared_compute" %}
data "oci_core_instance" "starter_bastion" {
  instance_id = oci_core_instance.starter_instance.id
}

{%- elif bastion_ocid is defined %}
variable "bastion_ocid" {}

data "oci_core_instance" "starter_bastion" {
  instance_id = var.bastion_ocid
}

{%- elif db_type != "none" %}
resource "oci_core_instance" "starter_bastion" {

  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = local.lz_appdev_cmp_ocid
  display_name        = "${var.prefix}-bastion"
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_shape_config_memory_in_gbs
  }

  create_vnic_details {
    subnet_id                 = data.oci_core_subnet.starter_public_subnet.id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "${var.prefix}-bastion"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oraclelinux.images.0.id
  }

  connection {
    agent       = false
    host        = oci_core_instance.starter_bastion.public_ip
    user        = "opc"
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "date"
    ]
  }

  freeform_tags = local.freeform_tags   
}

data "oci_core_instance" "starter_bastion" {
  instance_id = oci_core_instance.starter_bastion.id
}
{%- endif %}

output "bastion_public_ip" {
  value = data.oci_core_instance.starter_bastion.public_ip
}
