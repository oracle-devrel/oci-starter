#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

. $HOME/compute/shared_compute.sh

{%- if db_family == "psql" %}
sudo dnf install -y postgresql-devel 
{%- endif %}

# Python 
install_python
