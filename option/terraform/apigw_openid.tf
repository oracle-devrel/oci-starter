variable "client_id" {
  description = "OAuth2 Client ID"
  default = "UNKNOWN"
}
variable "client_secret" {
  description = "OAuth2 Client Secret"
  default = "UNKNOWN"
}
variable "client_secret_version_number" {
  default = 1
}

resource "oci_kms_vault" "starter_vault" {
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-vault"
  vault_type     = var.vault_type[0]
}

resource "oci_kms_key" "starter_key" {
  #Required
  compartment_id      = local.lz_app_cmp_ocid
  display_name        = "${var.prefix}-key"
  management_endpoint = data.oci_kms_vault.starter_vault.management_endpoint
  key_shape {
    #Required
    algorithm = "AES"
    length    = "256"
  }
}

resource "oci_vault_secret" "starter_openid_secret" {
  #Required
  compartment_id = local.lz_app_cmp_ocid
  secret_content {
    #Required
    content_type = "BASE64"

    #Optional
    content = base64encode(var.client_secret)
    name    = "${var.prefix}-openid-secret"
    stage   = "CURRENT"
  }
  key_id      = oci_kms_key.starter_key.id
  secret_name = "${var.prefix}-openid-secret"
  vault_id    = oci_kms_vault.starter_vault.id
}

resource "oci_identity_domains_app" "starter_confidential_app" {
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
  display_name = "starter-confidential-app"
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
  login_mechanism = "OIDC"
  logout_uri = "https://${local.apigw_hostname}/${var.prefix}/"
  name       = "777b363ffc7b43bd92f0a9c3a7e108d5"
  ocid       = "ocid1.domainapp.oc1.eu-frankfurt-1.amaaaaaa3gcex5iazzvu3de2wsug4evhs3ltmh6o47ibd4d6bqecvd5gvffq"
  post_logout_redirect_uris = [
    "https://${local.apigw_hostname}/${var.prefix}/",
  ]
  redirect_uris = [
    "https://${local.apigw_hostname}/${var.prefix}/",
    "https://${local.apigw_hostname}/${var.prefix}/app/dept",
  ]
  schemas = [
    "urn:ietf:params:scim:schemas:oracle:idcs:App",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags",
  ]
  show_in_my_apps = "false"
  trust_scope     = "Account"
}
