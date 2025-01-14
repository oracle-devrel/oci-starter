# Confidential app: Goal get the IDCS Token
resource oci_identity_domains_app starter_oic_confidential_app {
  active                  = "true"
  all_url_schemes_allowed = "false"
  allow_access_control    = "false"
  allowed_grants = [
    "client_credentials",
    "urn:ietf:params:oauth:grant-type:jwt-bearer",
  ]
  allowed_operations = [
  ]
  attr_rendering_metadata {
    name = "aliasApps"
    section = ""
    visible = "false"
    widget  = ""
  }
  based_on_template {
    value         = "CustomWebAppTemplateId"
    well_known_id = "CustomWebAppTemplateId"
  }
  bypass_consent     = "false"
  client_ip_checking = ""
  client_type        = "confidential"
  display_name      = "${var.prefix}-oic-app"
  idcs_endpoint     = "${local.idcs_url}"
  is_alias_app      = "false"
  is_enterprise_app = "false"
  is_kerberos_realm = "false"
  is_login_target   = "true"
  is_mobile_target  = "false"
  is_oauth_client   = "true"
  is_oauth_resource = "false"
  is_saml_service_provider = "false"
  is_unmanaged_app         = "false"
  is_web_tier_policy       = "false"
  login_mechanism = "OIDC"
  post_logout_redirect_uris = [
  ]
  redirect_uris = [
  ]
  schemas = [
    "urn:ietf:params:scim:schemas:oracle:idcs:App"
  ]
  secondary_audiences = [
  ]
  show_in_my_apps = "false"
  trust_scope = "Explicit"
}

/*
resource "oci_identity_domains_app" "starter_oic_confidential_app" {
  active                  = "true"
  all_url_schemes_allowed = "false"
  allow_access_control    = "false"
  allowed_grants = [
    "client_credentials",
    "authorization_code",
  ]
  allowed_operations = [
    "introspect",
  ]
  attr_rendering_metadata {
    name = "aliasApps"
    section = ""
    visible = "false"
    widget  = ""
  }
  based_on_template {
    value         = "CustomWebAppTemplateId"
    well_known_id = "CustomWebAppTemplateId"
  }
  client_ip_checking = "anywhere"
  client_type        = "confidential"
  delegated_service_names = [
  ]
  display_name = "${var.prefix}-oic-app"
  idcs_endpoint = "${local.idcs_url}"
  is_alias_app      = "false"
  is_enterprise_app = "false"
  is_kerberos_realm = "false"
  is_login_target   = "true"
  is_mobile_target  = "false"
  is_oauth_client   = "true"
  is_oauth_resource = "false"
  is_saml_service_provider = "false"
  is_unmanaged_app         = "false"
  is_web_tier_policy       = "false"
  login_mechanism   = "OIDC"
  schemas = [
    "urn:ietf:params:scim:schemas:oracle:idcs:App"
    # "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags"
  ]
  show_in_my_apps = "false"
  trust_scope     = "Account"
}
*/

locals {
  oic_client_id = oci_identity_domains_app.starter_oic_confidential_app.name
  oic_client_secret = oci_identity_domains_app.starter_oic_confidential_app.client_secret
}

# XXX - Maybe there is a terraform way for this
resource "null_resource" "get_idcs_token" { 
  provisioner "local-exec" {
      command = <<EOT
        curl -X POST ${local.idcs_url}/oauth2/v1/token -H 'Authorization: Basic ${base64encode(format("%s:%s",local.oic_client_id,local.oic_client_secret))}' -d 'grant_type=client_credentials&scope=urn:opc:idm:__myscopes__' | jq -r ".access_token" > idcs_token
EOT
  }
}

# curl --location '<Domain URL>/oauth2/v1/token' \
# --header 'Content-Type: application/x-www-form-urlencoded' \
# --header 'Authorization: Basic <BAse64 encoded of ClientID:ClientSecret>' \
# --data-urlencode 'grant_type=client_credentials' \
# --data-urlencode 'scope=urn:opc:idm:__myscopes__'

# IDCS TOKEN
data "local_file" "idcs_token" {
  depends_on = [ null_resource.get_idcs_token ]
  filename = "idcs_token"
}

resource "oci_integration_integration_instance" "oic_instance" {
  compartment_id            = local.lz_app_cmp_ocid
  display_name              = "${var.prefix}-oic"
  integration_instance_type = "ENTERPRISEX"                 #  Gen 2 STANDARD/ENTERPRISE - OIC Gen3 STANDARDX/ENTERPRISEX"
  is_byol                   = var.license_model == "BRING_YOUR_OWN_LICENSE" ? "true":"false"
  message_packs             = 1

  is_file_server_enabled    = "true"
  is_visual_builder_enabled = "true"
  state                     = "ACTIVE"

  idcs_at = data.local_file.idcs_token.content
}

