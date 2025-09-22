locals {
  compute_ready=data.external.env_part2.result.compute_ready
}

resource "oci_core_image" "custom_image" {
  depends_on = [ local.compute_ready ]
  compartment_id = local.lz_app_cmp_ocid
  instance_id    = oci_core_instance.starter_compute.id
  launch_mode = "NATIVE"
  display_name = "${var.prefix}-image"
  freeform_tags = local.freeform_tags

  timeouts {
    create = "30m"
  }
}

resource "oci_core_instance_configuration" "starter_instance_configuration" {
  depends_on = [ local.compute_ready ]
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-instance-config"

  instance_details {
    instance_type = "compute"

    launch_details {
        availability_domain = data.oci_identity_availability_domain.ad.name
        compartment_id      = local.lz_app_cmp_ocid
        display_name        = "${var.prefix}-launch-details"
        shape               = local.local_shape

        shape_config {
            ocpus         = var.instance_ocpus
            memory_in_gbs = var.instance_shape_config_memory_in_gbs
            # baseline_ocpu_utilization = "BASELINE_1_8"
        }

        create_vnic_details {
            subnet_id                 = data.oci_core_subnet.starter_app_subnet.id
            display_name              = "Primaryvnic"
            assign_public_ip          = false
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
            ssh_authorized_keys = local.ssh_public_key
        }

        source_details {
            source_type = "image"
            image_id   = oci_core_image.custom_image.id
        }

        freeform_tags = local.freeform_tags
    }

  }
}

resource "oci_core_instance_pool" "starter_instance_pool" {
  depends_on = [ local.compute_ready ]
  compartment_id = local.lz_app_cmp_ocid
  instance_configuration_id = oci_core_instance_configuration.starter_instance_configuration.id
  size = 2
  state = "RUNNING"
  display_name = "${var.prefix}-pool"
  instance_display_name_formatter = "${var.prefix}-pool$${launchCount}"
  instance_hostname_formatter = "${var.prefix}-pool$${launchCount}"

  placement_configurations {
    availability_domain = data.oci_identity_availability_domain.ad.name
    primary_subnet_id = data.oci_core_subnet.starter_app_subnet.id
  }

  load_balancers {
    load_balancer_id = oci_load_balancer.starter_pool_lb.id
    backend_set_name = oci_load_balancer_backend_set.starter_pool_backend_set.name
    port = 80
    vnic_selection = "primaryvnic"
  }

  lifecycle {
    ignore_changes = [size]
  }
}

data "oci_core_instance_pool_instances" "starter_instance_pool_instances_datasource" {
  compartment_id   = local.lz_app_cmp_ocid
  instance_pool_id = oci_core_instance_pool.starter_instance_pool.id
}

# Usage of singular instance datasources to show the public_ips, private_ips, and hostname_labels for the instances in the pool
data "oci_core_instance" "starter_instance_pool_instance_singular_datasource" {
  count = 2
  instance_id = data.oci_core_instance_pool_instances.starter_instance_pool_instances_datasource.instances[count.index]["id"]
}

# output "pooled_instances_private_ips" {
#   value = [data.oci_core_instance.starter_instance_pool_instance_singular_datasource.*.private_ip]
# }

# output "pooled_instances_public_ips" {
#   value = [data.oci_core_instance.starter_instance_pool_instance_singular_datasource.*.public_ip]
# }

# output "pooled_instances_hostname_labels" {
#   value = [data.oci_core_instance.starter_instance_pool_instance_singular_datasource.*.hostname_label]
# }

locals {
  local_instance_pool_lb_ip = oci_load_balancer.starter_pool_lb.ip_address_details[0].ip_address
}

output "instance_pool_lb_ip" {
  value = local.local_instance_pool_lb_ip
}