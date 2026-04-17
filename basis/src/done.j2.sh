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
  append_done "Vibe Coding (Build done in Bastion):"
  append_done
  append_done "1. Be sure your SSH key is available in your laptop (or see the key created target/*ssh*)"
  append_done "2. Clone the git repo of the starter app in your laptop"
  append_done "> git clone opc@$BASTION_IP:~/app.git app"
  append_done "> cd app"
  append_done "3. Do some changes with your favorite editor."
  append_done "4. Check what git_push.sh does and run it."
  append_done "> ./git_push.sh"
  append_done "The build will start automatically in the bastion and redeploy the app."
  append_done
  append_done "5. If you want to see the log. ssh opc@$BASTION_IP"
  append_done "> cat compute/rebuild.log"
  append_done "> cd app/xxxx" 
  append_done "> cat xxxx.log"
  {%- endif %} 

elif [ ! -f $FILE_DONE ]; then
  echo "-" > $FILE_DONE  
fi
cat $FILE_DONE  