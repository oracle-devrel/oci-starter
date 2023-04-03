# Defines the number of instances to deploy
resource "oci_core_instance" "starter_instance" {

  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = local.lz_appdev_cmp_ocid
  display_name        = "${var.prefix}-instance"
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
    hostname_label            = "${var.prefix}-instance"
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
    source_id   = data.oci_core_images.oraclelinux.images.0.id
  }

  connection {
    agent       = false
    host        = oci_core_instance.starter_instance.public_ip
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

# Output the private and public IPs of the instance
output "instance_private_ips" {
  value = [oci_core_instance.starter_instance.private_ip]
}

output "instance_public_ips" {
  value = [oci_core_instance.starter_instance.public_ip]
}

output "ui_url" {
  value = format("http://%s", oci_core_instance.starter_instance.public_ip)
}

