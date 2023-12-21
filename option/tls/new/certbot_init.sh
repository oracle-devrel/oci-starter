#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install certbot
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y
sudo dnf install snapd nginx -y
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Install nginx
sudo systemctl enable nginx
sudo systemctl restart nginx
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
sudo firewall-cmd --reload
sudo certbot --agree-tos --nginx --email $CERTIFICATE_EMAIL -d $TF_VAR_dns_name

# Place the certificate in an OPC directory so that it can be copied via SSH.
mkdir certificate
sudo cp -r /etc/letsencrypt/live/$TF_VAR_dns_name /home/opc/tls/certificate
sudo chown -R opc certificate