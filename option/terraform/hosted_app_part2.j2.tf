resource "oci_generative_ai_hosted_application" "starter_hosted_application" {
  #Required
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-hosted-app"

  inbound_auth_config {
    #Required
    inbound_auth_config_type = "IDCS_AUTH_CONFIG"

    # idcs_config {
    #   #Required
    #  domain_url = "domainUrl"
    #  scope      = "scope"
    # }
  }

  networking_config {
    #Required
    inbound_networking_config {
      #Required
      endpoint_mode = "PUBLIC"
    }

    outbound_networking_config {
      #Required
      network_mode = "MANAGED"
    }
  }

  freeform_tags = local.freeform_tags
}

resource "oci_generative_ai_hosted_deployment" "starter_hosted_deployment" {
  #Required
  active_artifact {
    #Required
    artifact_type = "SIMPLE_DOCKER_ARTIFACT"
    container_uri = "${var.region}.ocir.io/axk4z7krhqfx/cost-service"
    tag           = "latest"
  }
  compartment_id        = local.lz_app_cmp_ocid
  hosted_application_id = oci_generative_ai_hosted_application.starter_hosted_application.id

  freeform_tags = local.freeform_tags
}

data "oci_generative_ai_hosted_deployments" "starter_hosted_deployments" {
  #Required
  compartment_id = local.lz_app_cmp_ocid

  #Optional
  application_id = oci_generative_ai_hosted_application.starter_hosted_application.id
  id             = oci_generative_ai_hosted_deployment.starter_hosted_deployment.id
  state          = "ACTIVE"
}
