# Doc: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengsettingupnativeingresscontroller-addon-prereqs.htm#contengsettingupnativeingresscontroller-addon-permissions
resource "oci_identity_policy" "starter_hosted_app_policy" {
    provider       = oci.home    
    name           = "${var.prefix}-hosted-app-policy-${random_string.id.result}"
    description    = "${var.prefix}-hosted-app-policy"
    compartment_id = local.lz_app_cmp_ocid
    statements = [
        "allow service vulnerability-scanning-service to read compartments in compartment id ${local.lz_app_cmp_ocid}",
        "allow service vulnerability-scanning-service to read repos in compartment id ${local.lz_app_cmp_ocid}",
        "allow any-user to read repos in compartment id ${local.lz_serv_cmp_ocid} where any( request.resource.type='generativeaihostedapplication', request.resource.type='generativeaihosteddeployment')",
        "allow any-user to read vss-family in compartment id ${local.lz_serv_cmp_ocid} where any( request.resource.type='generativeaihostedapplication', request.resource.type='generativeaihosteddeployment')",
    ]
    freeform_tags = local.freeform_tags
}
