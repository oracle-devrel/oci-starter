{% import "build.j2_macro" as m with context %}
{{ m.build_common() }}

java_build_common

if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
    mvn package -Dpackaging=native-image
else 
    mvn package 
fi
exit_on_error  

if is_deploy_compute; then
    build_rsync target
else
    docker_build ${APP_NAME}
fi  
