# Temporary solution to generate a PROJECT_OCID in terraform
locals {
    project_id_filename = "${local.project_dir}/target/tf_genai_project.ocid"
    genai_region = var.region == "eu-amsterdam-1" ? "eu-frankfurt-1" : local.home_region
}

resource "null_resource" "genai_project" {
    provider       = oci.genai 
    
    triggers = {
        project_id_filename = local.project_id_filename
    }

    provisioner "local-exec" {
        interpreter = ["/bin/bash", "-c"]
        command = <<-EOT
        set -euo pipefail

        project_id="$(
            oci generative-ai generative-ai-project create \
            --compartment-id ""${local.lz_app_cmp_ocid}"" \
            --display-name "${var.prefix}-project" \
            --description "${var.prefix}-project" \
            --wait-for-state SUCCEEDED \
            --wait-interval-seconds 10 \
            --max-wait-seconds 120 \
            --query 'data.resources[0].identifier' \
            --region "${genai_region}"
            --raw-output
        )"

        printf '%s' "$project_id" > "${local.project_id_filename}"
        echo "Created Generative AI project: $project_id"
        EOT
    }

    provisioner "local-exec" {
        when        = destroy
        interpreter = ["/bin/bash", "-c"]
        environment = {
            PROJECT_ID_FILE = self.triggers.project_id_filename
        }
        command = <<-EOT
        set -euo pipefail

        if [ -f "$PROJECT_ID_FILE" ]; then
            project_id="$(cat "$PROJECT_ID_FILE")"

            oci generative-ai generative-ai-project delete \
            --generative-ai-project-id "$project_id" \
            --force \
            --wait-for-state SUCCEEDED \
            --wait-interval-seconds 10 \
            --max-wait-seconds 120

            rm -f "$PROJECT_ID_FILE"
            echo "Deleted Generative AI project: $project_id"
        else
            echo "Project id file not found, skipping delete."
        fi
        EOT
    }
}

data "local_file" "project_file" {
    filename   = local.project_id_filename
    depends_on = [null_resource.genai_project]
}

locals {
    local_project_ocid = data.local_file.project_file.content
}

