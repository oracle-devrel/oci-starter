## Copyright (c) 2022, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# Create log and log group

resource "oci_logging_log_group" "test_log_group" {
  compartment_id = var.compartment_ocid
  display_name   = "devops-log-group_${random_string.id.result}"
}

resource "oci_logging_log" "test_log" {
  #Required
  display_name = "${var.prefix}-devops-log"
  log_group_id = oci_logging_log_group.test_log_group.id
  log_type     = "SERVICE"

  #Optional
  configuration {
    #Required
    source {
      #Required
      category    = "all"
      resource    = oci_devops_project.test_project.id
      service     = "devops"
      source_type = "OCISERVICE"
    }

    #Optional
    compartment_id = var.compartment_ocid
  }

  is_enabled         = true
  retention_duration = "30"
}

# Create OCI Notification

resource "oci_ons_notification_topic" "test_notification_topic" {
  compartment_id = var.compartment_ocid
  name           = "${var.prefix}-devops-topic-${random_string.id.result}"
}

# Create devops project

resource "oci_devops_project" "test_project" {
  compartment_id = var.compartment_ocid
  name           = "${var.prefix}-devops"
  description    = "${var.prefix}-devops"

  notification_config {
    #Required
    topic_id = oci_ons_notification_topic.test_notification_topic.id
  }
}
