{% import "build.j2_macro" as m with context %}
{{ m.build_common() }}

java_build_common

mvn package
exit_on_error

if is_deploy_compute; then
    cp nginx_app.locations $TARGET_DIR/compute/compute
    build_rsync target
else
    {{ m.build_docker() }}
fi  
