{% import "go.j2_macro" as m with context %}
module starter/app
go 1.19

require (
    {{ m.mod() }}     
)
