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
    docker image rm ${TF_VAR_prefix}-${APP_NAME}:latest
    if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
        docker build -f Dockerfile.native -t ${TF_VAR_prefix}-${APP_NAME}:latest .
    else
        docker build -t ${TF_VAR_prefix}-${APP_NAME}:latest . 
    fi
    exit_on_error "docker build"
    {{ m.deploy_oke() }}
fi  
