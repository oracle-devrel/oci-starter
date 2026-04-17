#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

. starter.sh env -silent

get_ui_url

echo 
echo "Build done"

# Do not show the Done URLs if after_build.sh exists 
if [ "$UI_URL" != "" ]; then
  echo "URLs" > $FILE_DONE
  {%- if ui_type != "api" %}
    append_done "- User Interface: $UI_URL/"
  {%- endif %}     
  if [ "$UI_HTTP" != "" ]; then
    append_done "- HTTP : $UI_HTTP/"
  fi
  append_done "- REST: $UI_URL/app/dept"
  append_done "- REST: $UI_URL/app/info"    
  {%- if language=="java" and java_framework=="tomcat" %}
  append_done "- REST: $UI_URL/app/index.jsp"
  {%- endif %}    
  {%- if language=="php" %}
  append_done "- REST: $UI_URL/app/index.php"
  {%- endif %}        
  {%- if (deploy_type=="public_compute" or deploy_type=="private_compute") and ui_type=="api" %}
  export APIGW_URL=https://${APIGW_HOSTNAME}/${TF_VAR_prefix}  
  append_done "- API Gateway URL : $APIGW_URL/app/dept" 
  {%- endif %}     
  {%- if language=="java" and java_framework=="springboot" and ui_type=="html" and db_subtype=="rac" %}
  append_done "- RAC Page        : $UI_URL/rac.html"
  {%- endif %}     
  {%- if language == "apex" %}
  append_done "-----------------------------------------------------------------------"
  append_done "APEX login:"
  append_done
  append_done "APEX Workspace"
  append_done "$UI_URL/ords/_/landing"
  append_done "  Workspace: APEX_APP"
  append_done "  User: APEX_APP"
  append_done "  Password: $TF_VAR_db_password"
  append_done
  append_done "APEX APP"
  append_done "$UI_URL/ords/r/apex_app/apex_app/"
  append_done "  User: APEX_APP / $TF_VAR_db_password"
  {%- endif %} 


  {%- if build_host == "bastion" %}
  append_done "-----------------------------------------------------------------------"
  append_done "Build in Bastion:"
  append_done
  append_done "git clone opc@$BASTION_IP:~/app.git my-app"
  append_done "cd my-app"
  append_done "<do some changes>"
  append_done "cat git_push.sh"
  append_done "./git_push.sh"
  append_done "Build will start automatically in the bastion"
  append_done
  append_done "Build logs ssh to opc@$BASTION_IP"
  append_done "- compute/rebuild.log"
  append_done "Application logs" 
  append_done "- app/rest/rest.log"
  {%- endif %} 

elif [ ! -f $FILE_DONE ]; then
  echo "-" > $FILE_DONE  
fi
cat $FILE_DONE  