#!/bin/bash
{% import "start_sh.j2_macro" as m with context %}
{{ m.env() }}

/opt/tomcat/bin/startup.sh
# curl http://localhost:8080/starter-1.0/info
# curl http://localhost:8080/starter-1.0/dept