#############################################################################
# Used to run terraform from DevOps to keep the state in a fixed place
# Not needed when using ResourceManager

resource "oci_objectstorage_bucket" "tf_bucket" {
  compartment_id = var.compartment_ocid
  namespace      = local.ocir_namespace
  name           = "${var.prefix}-terraform"
  access_type    = "NoPublicAccess"
}

resource "oci_objectstorage_object" "tf_object" {
  namespace      = local.ocir_namespace
  bucket              = oci_objectstorage_bucket.tf_bucket.name
  object              = "tfstate.tf"
  content_language    = "en-US"
  content_type        = "text/plain"
  content             = ""
  content_disposition = "attachment; filename=\"filename.html\""
}


resource "oci_objectstorage_preauthrequest" "object_par" {
  namespace    = local.ocir_namespace
  bucket       = oci_objectstorage_bucket.tf_bucket.name
  object_name  = oci_objectstorage_object.tf_object.object
  name         = "objectPar"
  access_type  = "ObjectReadWrite"
  time_expires = "2030-01-01T00:00:00Z"
}

locals {
  par_request_url = "https://objectstorage.${var.region}.oraclecloud.com${oci_objectstorage_preauthrequest.object_par.access_uri}"
}

#############################################################################

resource "oci_devops_build_pipeline" "test_build_pipeline" {

  #Required
  project_id = oci_devops_project.test_project.id

  description  = "Build pipeline"
  display_name = "build-pipeline"

  build_pipeline_parameters {
    items {
      default_value = var.tenancy_ocid
      description   = ""
      name          = "TF_VAR_tenancy_ocid"
    }  
    items {
      default_value = var.compartment_ocid
      description   = ""
      name          = "TF_VAR_compartment_ocid"
    }
    items {
      default_value = var.region
      description   = ""
      name          = "TF_VAR_region"
    }
    items {
      default_value = local.par_request_url
      description   = ""
      name          = "TF_VAR_terraform_state_url"
    }
    items {
      default_value = local.function_image_uri
      description   = ""
      name          = "TF_VAR_function_image_uri"
    }
  }
}

#############################################################################

locals {
  function_image_uri="${local.ocir_docker_repository}/${local.ocir_namespace}/${oci_artifacts_container_repository.oci_starter_container_repository.display_name}:function"
}

#############################################################################


resource "oci_artifacts_container_repository" "oci_starter_container_repository" {
  #Required
  compartment_id = var.compartment_ocid
  display_name   = "${var.prefix}-function-${random_id.tag.hex}"
  #Optional
  is_public = true
}

resource "oci_devops_deploy_artifact" "oci_starter_deploy_artifact_default" {

  #Required
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_source {
    #Required
    deploy_artifact_source_type = "OCIR"

    #Optional
    image_uri     = local.function_image_uri
    image_digest  = " "
    #image_digest  = oci_devops_build_run.test_build_run.build_outputs[0].delivered_artifacts[0].items[0].delivered_artifact_hash
    repository_id = oci_devops_repository.test_repository.id
  }

  deploy_artifact_type = "DOCKER_IMAGE"
  project_id           = oci_devops_project.test_project.id

  #Optional
  display_name = "${oci_artifacts_container_repository.oci_starter_container_repository.display_name}"
}


resource "oci_devops_build_pipeline_stage" "build_function" {
  #Required
  build_pipeline_id = oci_devops_build_pipeline.test_build_pipeline.id
  build_pipeline_stage_predecessor_collection {
    #Required
    items {
      #Required
      id = oci_devops_build_pipeline.test_build_pipeline.id
    }
  }
  build_pipeline_stage_type = "BUILD"
  
  #Optional
  build_source_collection {

    #Optional
    items {
      #Required
      connection_type = "DEVOPS_CODE_REPOSITORY"

      #Optional
      branch = "main"
      # connection_id  = oci_devops_connection.test_connection.id
      name           = "build"
      repository_id  = oci_devops_repository.test_repository.id
      repository_url = "https://devops.scmservice.${var.region}.oci.oraclecloud.com/namespaces/${local.ocir_namespace}/projects/${oci_devops_project.test_project.name}/repositories/${oci_devops_repository.test_repository.name}"
    }
  }

  build_spec_file                    = "build_spec_app.yaml"
  description                        = "Build function"
  display_name                       = "build-function"
  image                              = "OL7_X86_64_STANDARD_10"
  stage_execution_timeout_in_seconds = "36000"
  wait_criteria {
    #Required
    wait_duration = "waitDuration"
    wait_type     = "ABSOLUTE_WAIT"
  }
}

resource "oci_devops_build_pipeline_stage" "deliver_function" {

  depends_on = [oci_devops_build_pipeline_stage.build_function]

  #Required
  build_pipeline_id = oci_devops_build_pipeline.test_build_pipeline.id
  build_pipeline_stage_predecessor_collection {
    #Required
    items {
      #Required
      id = oci_devops_build_pipeline_stage.build_function.id
    }
  }

  build_pipeline_stage_type = "DELIVER_ARTIFACT"

  deliver_artifact_collection {

    #Optional
    items {
      #Optional
      artifact_name = "output_fn_default_image"
      artifact_id   = oci_devops_deploy_artifact.oci_starter_deploy_artifact_default.id
    }
  }
  display_name = "deliver-function"
}

resource "oci_devops_build_pipeline_stage" "build_other" {
  #Required
  build_pipeline_id = oci_devops_build_pipeline.test_build_pipeline.id
  build_pipeline_stage_predecessor_collection {
    #Required
    items {
      #Required
      id = oci_devops_build_pipeline_stage.deliver_function.id
    }
  }
  build_pipeline_stage_type = "BUILD"
  
  #Optional
  build_source_collection {

    #Optional
    items {
      #Required
      connection_type = "DEVOPS_CODE_REPOSITORY"

      #Optional
      branch = "main"
      # connection_id  = oci_devops_connection.test_connection.id
      name           = "build"
      repository_id  = oci_devops_repository.test_repository.id
      repository_url = "https://devops.scmservice.${var.region}.oci.oraclecloud.com/namespaces/${local.ocir_namespace}/projects/${oci_devops_project.test_project.name}/repositories/${oci_devops_repository.test_repository.name}"
    }
  }

  build_spec_file                    = ""
  description                        = "Build stage"
  display_name                       = "build-stage"
  image                              = "OL7_X86_64_STANDARD_10"
  stage_execution_timeout_in_seconds = "36000"
  wait_criteria {
    #Required
    wait_duration = "waitDuration"
    wait_type     = "ABSOLUTE_WAIT"
  }
}

#############################################################################
/*
resource "null_resource" "sleep_before_build" {
  depends_on = [ oci_devops_build_pipeline_stage.build_other ]
  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "oci_devops_build_run" "test_build_run_1" {
  depends_on = [null_resource.sleep_before_build]
  #Required
  build_pipeline_id = oci_devops_build_pipeline.test_build_pipeline.id
  #Optional
  display_name = "build-run-${random_id.tag.hex}"
}
*/
#############################################################################

