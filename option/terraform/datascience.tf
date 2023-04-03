resource "oci_identity_policy" "starter_datascience_policy" {
  name           = "${var.prefix}-datascience-policy"
  description    = "policy created for datascience"
  compartment_id = var.compartment_ocid

  statements = [
    "allow service datascience to use virtual-network-family in compartment id ${var.compartment_ocid}"
    // "allow group xxxxxx to use virtual-network-family in compartment id ${var.compartment_ocid}",
    // "allow group xxxxxx to manage data-science-family in compartment id ${var.compartment_ocid}"
  ]
}

resource "oci_datascience_project" "starter_project" {
  compartment_id = var.compartment_ocid

  description  = "${var.prefix} Project"
  display_name = "${var.prefix} Project"

  depends_on = [
    data.oci_core_subnet.starter_private_subnet
  ]
}

# FIXME bad hack to avoid: The specified subnet is not accessible. Select a different subnet.
resource "time_sleep" "wait_a_bit" {
  create_duration = "120s"
}

resource "oci_datascience_notebook_session" "starter_notebook_session" {
  compartment_id = var.compartment_ocid
  project_id     = oci_datascience_project.starter_project.id

  display_name = "${var.prefix} Notebook Session"

  notebook_session_config_details {
    shape = data.oci_datascience_notebook_session_shapes.ds_shapes.notebook_session_shapes[0].name
    subnet_id = data.oci_core_subnet.starter_private_subnet.id 
  }

  depends_on = [
    time_sleep.wait_a_bit
  ]
}

data "oci_datascience_notebook_session_shapes" "ds_shapes" {
  compartment_id = var.compartment_ocid
  filter {
    name   = "core_count"
    values = [1]
  }
}

output "ds_notebook_session_shape" {
  value = data.oci_datascience_notebook_session_shapes.ds_shapes.notebook_session_shapes[0].name
}

output "ds_notebook_session" {
  value = oci_datascience_notebook_session.starter_notebook_session.notebook_session_url
}

