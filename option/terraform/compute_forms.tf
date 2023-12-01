# DATA 1 - Get a list of element in Marketplace, using filters, eg name of the stack
data "oci_marketplace_listings" "forms_listings" {
  name = ["Oracle Forms"]
  compartment_id = local.lz_appdev_cmp_ocid
}

# DATA 2 - Get details cf the specific listing you are interested in and which you obtained through generic listing
data "oci_marketplace_listing" "forms_listing" {
  listing_id     = data.oci_marketplace_listings.forms_listings.listings[0].id
  compartment_id = local.lz_appdev_cmp_ocid
}

# DATA 3 - Get the list of versions for the specific entry (11.3, 12.2.1, ....)
data "oci_marketplace_listing_packages" "forms_listing_packages" {
  #Required
  listing_id = data.oci_marketplace_listing.forms_listing.id

  #Optional
  compartment_id = local.lz_appdev_cmp_ocid
  package_version = data.oci_marketplace_listing.forms_listing.default_package_version
}

# DATA 4 - Get details about a specfic version
data "oci_marketplace_listing_package" "forms_listing_package" {
  #Required
  listing_id      = data.oci_marketplace_listing.forms_listing.id
  package_version = data.oci_marketplace_listing_packages.forms_listing_packages.package_version

  #Optional
  compartment_id = local.lz_appdev_cmp_ocid
}

# DATA 5 - agreement for a specific version
data "oci_marketplace_listing_package_agreements" "forms_listing_package_agreements" {
  #Required
  listing_id      = data.oci_marketplace_listing.forms_listing.id
  package_version = data.oci_marketplace_listing_packages.forms_listing_packages.package_version

  #Optional
  compartment_id = local.lz_appdev_cmp_ocid
}

data "oci_core_app_catalog_listing_resource_version" "forms_catalog_listing" {
  listing_id = data.oci_marketplace_listing_package.forms_listing_package.app_catalog_listing_id
  resource_version = data.oci_marketplace_listing_package.forms_listing_package.app_catalog_listing_resource_version
}

# RESOURCE 1 - agreement for a specific version
resource "oci_marketplace_listing_package_agreement" "forms_listing_package_agreement" {
  #Required
  agreement_id    = data.oci_marketplace_listing_package_agreements.forms_listing_package_agreements.agreements[0].id
  listing_id      = data.oci_marketplace_listing.forms_listing.id
  package_version = data.oci_marketplace_listing_packages.forms_listing_packages.package_version
}

# RESOURCE 2 - Accepted agreement
resource "oci_marketplace_accepted_agreement" "forms_accepted_agreement" {
  #Required
  agreement_id    = oci_marketplace_listing_package_agreement.forms_listing_package_agreement.agreement_id
  compartment_id  = local.lz_appdev_cmp_ocid
  listing_id      = data.oci_marketplace_listing.forms_listing.id
  package_version = data.oci_marketplace_listing_packages.forms_listing_packages.package_version
  signature       = oci_marketplace_listing_package_agreement.forms_listing_package_agreement.signature
}

output "image_id" {
  value = data.oci_marketplace_listing_package.forms_listing_package.image_id
}

output "forms_listing_id" {
   value = data.oci_marketplace_listing.forms_listing.id
}

output "signature" {
  value = oci_marketplace_listing_package_agreement.forms_listing_package_agreement.signature
}

output "listing_resource_id" {
  value = data.oci_core_app_catalog_listing_resource_version.forms_catalog_listing.listing_resource_id
}

resource oci_core_instance starter_instance {

  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = local.lz_appdev_cmp_ocid
  display_name        = "${var.prefix}-instance"
  shape               = "VM.Standard.E4.Flex"
  
  shape_config {
    ocpus         = "1"
    memory_in_gbs = "16"
  }
  
  create_vnic_details {
    subnet_id                 = data.oci_core_subnet.starter_public_subnet.id
    display_name              = "Primaryvnic"    
    assign_public_ip          = "true"
    hostname_label            = "${var.prefix}-instance"
  }

  metadata = {
    "ssh_authorized_keys" = var.ssh_public_key
  }

  source_details {
    boot_volume_size_in_gbs = "75"
    source_id = data.oci_core_app_catalog_listing_resource_version.forms_catalog_listing.listing_resource_id
    source_type = "image"
  }
  /*
  provisioner "file" {    
    connection {
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = var.ssh_private_key
      host        = oci_core_instance.starter_instance.public_ip
    }
    source      = "../app/.success"
    destination = "/u01/oracle/.frm_config/msg/.success"  
  }

  provisioner "file" {    
    connection {
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = var.ssh_private_key
      host        = oci_core_instance.starter_instance.public_ip
    }
    source      = "../app/.autosetup.ini"
    destination = "/u01/oracle/.autosetup.ini"  
  }

  provisioner "file" {    
    connection {
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = var.ssh_private_key
      host        = oci_core_instance.starter_instance.public_ip
    }
    source      = "../app/.autosetup.json"
    destination = "/u01/oracle/.autosetup.json"  
  }

  provisioner "file" {    
    connection {
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = var.ssh_private_key
      host        = oci_core_instance.starter_instance.public_ip
    }
    source      = "../app/domainconfig.sh"
    destination = "/u01/oracle/.frm_config/domainconfig.sh"  
  }

  provisioner "remote-exec" {    
    connection {
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = var.ssh_private_key
      host        = oci_core_instance.starter_instance.public_ip
    }
    inline = [
      "sh /u01/oracle/.frm_config/domainconfig.sh"
    ]
  }
  */
}

locals {
  compute_ocid = oci_core_instance.starter_instance.id
  compute_public_ip = oci_core_instance.starter_instance.public_ip
  compute_private_ip = oci_core_instance.starter_instance.private_ip
}
