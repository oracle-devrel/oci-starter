#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# https://yum.oracle.com/oracle-linux-python.html

{%- if db_family == "psql" %}
sudo yum -y install postgresql-devel 
{%- endif %}

sudo dnf install -y python39 python39-devel
sudo pip3.9 install pip --upgrade
sudo pip3.9 install -r requirements.txt
