resource "oci_load_balancer" "starter_pool_lb" {
  shape          = "flexible"
  compartment_id = local.lz_app_cmp_ocid
  subnet_ids = [ data.oci_core_subnet.starter_web_subnet.id ]
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