locals {
  openid_client_id = oci_identity_domains_app.starter_confidential_app.name
  openid_client_secret = oci_identity_domains_app.starter_confidential_app.client_secret
}

variable "vault_ocid" {}

variable "vault_key_ocid" {}

resource "oci_kms_vault" "starter_vault" {
  count = var.vault_ocid==null ? 1 : 0  
  compartment_id = local.lz_app_cmp_ocid
  display_name   = "${var.prefix}-vault"
  vault_type     = "DEFAULT"
}

data "oci_kms_vault" "starter_vault" {
  vault_id = local.vault_ocid
}

resource "oci_kms_key" "starter_key" {
  #Required
  count = var.vault_key_ocid==null ? 1 : 0  
  compartment_id      = local.lz_app_cmp_ocid
  display_name        = "${var.prefix}-key"
  management_endpoint = data.oci_kms_vault.starter_vault.management_endpoint
  key_shape {
    #Required
    algorithm = "AES"
    length    = "16"
  }
  protection_mode="SOFTWARE"
}

data "oci_kms_key" "starter_key" {
  key_id = local.vault_key_ocid
  management_endpoint = data.oci_kms_vault.starter_vault.management_endpoint
}

locals {
  apigw_hostname = oci_apigateway_gateway.starter_apigw.hostname
  vault_ocid = var.vault_ocid==null ? oci_kms_vault.starter_vault[0].id : var.vault_ocid 
  vault_key_ocid = var.vault_key_ocid==null ? oci_kms_key.starter_key[0].id : var.vault_key_ocid 
}

resource "oci_vault_secret" "starter_openid_secret" {
  #Required
  compartment_id = local.lz_app_cmp_ocid
  secret_content {
    #Required
    content_type = "BASE64"

    #Optional
    content = base64encode(local.openid_client_secret)
    name    = "${var.prefix}-openid-secret"
    stage   = "CURRENT"
  }
  key_id      = local.vault_key_ocid
  secret_name = "${var.prefix}-openid-secret-${random_string.id.result}"
  vault_id    = local.vault_ocid
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
  display_name = "${var.prefix}-confidential-app"
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
  post_logout_redirect_uris = [
    "https://${local.apigw_hostname}/${var.prefix}/",
  ]
  redirect_uris = [
    "https://${local.apigw_hostname}/${var.prefix}/",
    "https://${local.apigw_hostname}/${var.prefix}/app/dept",
    "https://${local.apigw_hostname}/${var.prefix}/app/info"
  ]
  schemas = [
    "urn:ietf:params:scim:schemas:oracle:idcs:App"
  ]
  show_in_my_apps = "false"
  trust_scope     = "Account"
}
