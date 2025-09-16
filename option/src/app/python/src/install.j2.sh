#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# https://yum.oracle.com/oracle-linux-python.html

{%- if db_family == "psql" %}
sudo yum -y install postgresql-devel 
{%- endif %}

sudo dnf install -y python3.12 python3.12-pip python3-devel
# sudo pip3.12 install pip --upgrade
sudo update-alternatives --set python /usr/bin/python3.12
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install virtual env python_env
uv venv myenv/
source myvenv/bin/activate
uv pip install -r requirements.txt