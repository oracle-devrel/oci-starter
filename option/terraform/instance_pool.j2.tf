variable compute_ready { default = "" }

resource "oci_core_image" "custom_image" {
  count          = var.compute_ready == "" ? 0 : 1
  compartment_id = local.lz_appdev_cmp_ocid
  instance_id    = oci_core_instance.starter_instance.id
  launch_mode = "NATIVE"
  display_name = "${var.prefix}-image"
  freeform_tags = local.freeform_tags

  timeouts {
    create = "30m"
  }
}

resource "oci_load_balancer" "starter_pool_lb" {
  shape          = "flexible"
  compartment_id = local.lz_appdev_cmp_ocid
  subnet_ids = [ data.oci_core_subnet.starter_public_subnet.id ]
  shape_details {
    #Required
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 100
  }

  display_name ="${var.prefix}-pool-lb"
}

resource "oci_load_balancer_backend_set" "starter_pool_backend_set" {
  name             = "${substr(var.prefix,0,8)}-pool-bes"
  load_balancer_id = oci_load_balancer.starter_pool_lb.id
  policy           = "ROUND_ROBIN"

  health_checker {
    port                = "80"
    protocol            = "HTTP"
    response_body_regex = ".*"
    url_path            = "/"
  }
}

resource "oci_load_balancer_listener" "starter_pool_lb_listener" {
  load_balancer_id         = oci_load_balancer.starter_pool_lb.id
  name                     = "HTTP-80"
  default_backend_set_name = oci_load_balancer_backend_set.starter_pool_backend_set.name
  port                     = 80
  protocol                 = "HTTP"
{%- if tls == "new" %} 
  path_route_set_name = oci_load_balancer_path_route_set.starter-bastion-routeset.name
{%- endif %} 
}


resource "oci_core_instance_configuration" "starter_instance_configuration" {
  count          = var.compute_ready == "" ? 0 : 1
  compartment_id = local.lz_appdev_cmp_ocid
  display_name   = "${var.prefix}-instance-config"

  instance_details {
    instance_type = "compute"

    launch_details {
        availability_domain = data.oci_identity_availability_domain.ad.name
        compartment_id      = local.lz_appdev_cmp_ocid
        display_name        = "${var.prefix}-launch-details"
        shape               = var.instance_shape

        shape_config {
            ocpus         = var.instance_ocpus
            memory_in_gbs = var.instance_shape_config_memory_in_gbs
            # baseline_ocpu_utilization = "BASELINE_1_8"
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
            image_id   = oci_core_image.custom_image[0].id
        }

        freeform_tags = local.freeform_tags
    }

  }
}

resource "oci_core_instance_pool" "starter_instance_pool" {
  count          = var.compute_ready == "" ? 0 : 1
  compartment_id = local.lz_appdev_cmp_ocid
  instance_configuration_id = oci_core_instance_configuration.starter_instance_configuration[0].id
  size = 2
  state = "RUNNING"
  display_name = "${var.prefix}-pool"
  instance_display_name_formatter = "${var.prefix}-pool$${launchCount}"
  instance_hostname_formatter = "${var.prefix}-pool$${launchCount}"

  placement_configurations {
    availability_domain = data.oci_identity_availability_domain.ad.name
    primary_subnet_id = data.oci_core_subnet.starter_public_subnet.id
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
  count            = var.compute_ready == "" ? 0 : 1  
  compartment_id   = local.lz_appdev_cmp_ocid
  instance_pool_id = oci_core_instance_pool.starter_instance_pool[0].id
}

# Usage of singular instance datasources to show the public_ips, private_ips, and hostname_labels for the instances in the pool
data "oci_core_instance" "starter_instance_pool_instance_singular_datasource" {
  count       = var.compute_ready == "" ? 0 : 2
  instance_id = data.oci_core_instance_pool_instances.starter_instance_pool_instances_datasource[0].instances[count.index]["id"]
}

output "pooled_instances_private_ips" {
  value = [data.oci_core_instance.starter_instance_pool_instance_singular_datasource.*.private_ip]
}

output "pooled_instances_public_ips" {
  value = [data.oci_core_instance.starter_instance_pool_instance_singular_datasource.*.public_ip]
}

output "pooled_instances_hostname_labels" {
  value = [data.oci_core_instance.starter_instance_pool_instance_singular_datasource.*.hostname_label]
}

locals {
  instance_pool_lb_ip = oci_load_balancer.starter_pool_lb.ip_address_details[0].ip_address
}

output "instance_pool_lb_ip" {
  value = local.instance_pool_lb_ip
}