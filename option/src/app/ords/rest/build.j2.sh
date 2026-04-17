{% import "build.j2_macro" as m with context %}
{{ m.build_common() }}

if is_deploy_compute; then
    echo "Nothing to deploy on compute"
else
    # No docker build
    {{ m.deploy_oke() }}
fi  
