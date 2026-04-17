{% import "build.j2_macro" as m with context %}
{{ m.build_common() }}

if is_deploy_compute; then
    build_rsync .
else
    {{ m.build_docker() }}
fi  
