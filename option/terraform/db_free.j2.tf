# DB23c Free in OCI Compute
{%- if deploy_type == "public_compute" %}
locals {
  local_db_free_ip = oci_core_instance.starter_compute.private_ip
}

{%- else %}  
resource "oci_core_instance" "starter_db_free" {

  availability_domain = local.availability_domain_name
  compartment_id      = local.lz_db_cmp_ocid
  display_name        = "${var.prefix}-db-free"
  shape               = local.shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_shape_config_memory_in_gbs
    # baseline_ocpu_utilization = "BASELINE_1_8"
  }

  create_vnic_details {
    subnet_id                 = data.oci_core_subnet.starter_db_subnet.id
    display_name              = "Primaryvnic"
    assign_public_ip          = false
    assign_private_dns_record = true
    hostname_label            = "${var.prefix}-db"
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
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
    private_key = local.ssh_private_key
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
  local_db_free_ip = oci_core_instance.starter_db_free.private_ip
}
{%- endif %}  

locals {
  db_host = "todo"
  local_db_url = format("%s:1521/FREEPDB1", local.local_db_free_ip)
  local_jdbc_url = format("jdbc:oracle:thin:@%s", local.local_db_url)
}

output "db_free_ip" {
   value = local.local_db_free_ip
}
