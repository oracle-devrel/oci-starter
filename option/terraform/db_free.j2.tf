# DB23c Free in OCI Compute
{%- if db_install == "shared_compute" and shape != "ampere" %}
locals {
  db_free_ip = oci_core_instance.starter_instance.private_ip
}

{%- else %}  
resource "oci_core_instance" "starter_db_free" {

  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = local.lz_database_cmp_ocid
  display_name        = "${var.prefix}-db-free"
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_shape_config_memory_in_gbs
    # baseline_ocpu_utilization = "BASELINE_1_8"
  }

  create_vnic_details {
    subnet_id                 = data.oci_core_subnet.starter_private_subnet.id
    display_name              = "Primaryvnic"
    assign_public_ip          = false
    assign_private_dns_record = true
    hostname_label            = "${var.prefix}-db"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oraclelinux.images.0.id
  }

/*
  // XXXX Potential connection issue
  // If changed to private network - not possible for private IP.
  connection {
    agent       = false
    host        = oci_core_instance.starter_db_free.public_ip
    user        = "opc"
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "date"
    ]
  }
*/

  freeform_tags = local.freeform_tags
}

locals {
  db_free_ip = oci_core_instance.starter_db_free.private_ip
}
{%- endif %}  

locals {
  db_url = format("%s:1521/FREEPDB1", local.db_free_ip)
  db_host = "todo"
  jdbc_url = format("jdbc:oracle:thin:@%s", local.db_url)
}

output "db_free_ip" {
   value = local.db_free_ip
}
