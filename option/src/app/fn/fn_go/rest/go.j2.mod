{% import "go.j2_macro" as m with context %}
module func

require (
    github.com/fnproject/fdk-go v0.0.24
    {{ m.mod() }}     
)    