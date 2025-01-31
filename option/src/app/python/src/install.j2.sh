#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# https://yum.oracle.com/oracle-linux-python.html

{%- if db_family == "psql" %}
sudo yum -y install postgresql-devel 
{%- endif %}

sudo dnf install -y python3.11 python3.11-pip python3-devel
sudo pip3.11 install pip --upgrade

# Install virtual env python_env
python3.11 -m venv myenv
source myenv/bin/activate
pip3 install --upgrade pip
pip3 install -r requirements.txt