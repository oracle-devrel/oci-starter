module func

require (
    github.com/fnproject/fdk-go v0.0.24
	github.com/gorilla/mux v1.8.0
	{%- if db_family == "oracle" %}
	github.com/godror/godror v0.35.1
	{%- elif db_family == "mysql" %}
	github.com/go-sql-driver/mysql v1.7.0
	{%- elif db_family == "psql" %}
	github.com/lib/pq v1.10.9
	{%- endif %}	
)    