{% import "build.j2_macro" as m with context %}
{{ m.build_common() }}

## XXXXX Check Language version

if is_deploy_compute; then
    build_rsync .
else
    {{ m.build_docker() }}
fi  
