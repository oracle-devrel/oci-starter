{% import "build.j2_macro" as m with context %}
{{ m.build_common() }}

java_build_common

mkdir src/main/resources
cp application.properties.tmpl src/main/resources/application.properties
replace_db_user_password_in_file src/main/resources/application.properties

if is_deploy_compute; then
    if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
        # Native Build about 14 mins. Output is ./demo
        mvn -Pnative native:compile
    else 
        mvn package -DskipTests
    fi
    exit_on_error

    build_rsync target
else
    docker image rm ${TF_VAR_prefix}-${APP_NAME}:latest
    
    if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
        mvn -Pnative spring-boot:build-image -Dspring-boot.build-image.imageName=${TF_VAR_prefix}-${APP_NAME}:latest
    else
        # It does not use mvn build image. Else no choice of the JIT
        # mvn spring-boot:build-image -Dspring-boot.build-image.imageName=${TF_VAR_prefix}-${APP_NAME}:latest
        mvn package -DskipTests
        exit_on_error
        docker build -t ${TF_VAR_prefix}-${APP_NAME}:latest . 
    fi
    exit_on_error "docker build"
    {{ m.deploy_oke() }}
fi  
