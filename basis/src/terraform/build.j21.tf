variable project_dir { default="../.." }

## BUILD_DEPLOY
resource "null_resource" "build_deploy" {
  provisioner "local-exec" {
    command = <<-EOT
        sleep 5
        cd ${var.project_dir}
        pwd
        # cat target/terraform.tfstate
        # export
        # ./starter.sh frm build_deploy        
        . starter.sh env
        # Run config command on the DB directly (ex RAC)
        if [ -f $BIN_DIR/deploy_db_node.sh ]; then
            title "Deploy DB Node"
            $BIN_DIR/deploy_db_node.sh
        fi 

        # Build the DB tables (via Bastion)
        if [ -d src/db ]; then
            title "Deploy Bastion"
            $BIN_DIR/deploy_bastion.sh
        fi  

        # Init target/compute
        if is_deploy_compute; then
            mkdir -p target/compute
            cp -r src/compute target/compute/.
        fi

        # Build all app* directories
        for APP_DIR in `app_dir_list`; do
            title "Build App $APP_DIR"
            src/$APP_DIR/build_app.sh
            exit_on_error
        done

        if [ -f src/ui/build_ui.sh ]; then
            title "Build UI"
            src/ui/build_ui.sh 
            exit_on_error
        fi

        # Deploy
        title "Deploy $TF_VAR_deploy_type"
        if is_deploy_compute; then
            $BIN_DIR/deploy_compute.sh
            exit_on_error
        elif [ "$TF_VAR_deploy_type" == "kubernetes" ]; then
            $BIN_DIR/oke_deploy.sh
            exit_on_error
        elif [ "$TF_VAR_deploy_type" == "container_instance" ]; then
            $BIN_DIR/ci_deploy.sh
            exit_on_error
        fi
        . starter.sh frm
        # cat target/resource_manager_variables.json
        EOT
  }
  depends_on = [
{%- for key in terraform_resources %}
    {{key}},
{%- endfor %}    
  ]

  triggers = {
    always_run = "${timestamp()}"
  }      
}

{%- if terraform_resources_part2|length>0 %}
# PART2
#
# In case like instance_pool, oke, function, container_instance, ...
# More terraform resources need to be created after build_deploy.
# Reread the env viables
data "external" "env_part2" {
  program = ["cat", "${var.project_dir}/target/resource_manager_variables.json"]
  depends_on = [
    null_resource.build_deploy
  ]
}
{%- endif %}

## AFTER_BUILD
# Last action at the end of the build
resource "null_resource" "after_build" {
  provisioner "local-exec" {
    command = <<-EOT
        cd ${var.project_dir}    
        # cat target/terraform.tfstate
        # export
        ./starter.sh frm after_build
        EOT
  }
  depends_on = [
{%- for key in terraform_resources_part2 %}
    {{key}},
{%- endfor %}      
    null_resource.build_deploy
  ]

  triggers = {
    always_run = "${timestamp()}"
  }    
}

# BEFORE_DESTROY
resource "null_resource" "before_destroy" {
  provisioner "local-exec" {
      when = destroy
      command = <<-EOT
        if [ ! -f starter.sh ]; then 
          cd ../..
        fi
        ./starter.sh destroy --called_by_resource_manager
        EOT
  }

  depends_on = [  
    null_resource.after_build
  ]
}
