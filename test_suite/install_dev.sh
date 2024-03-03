# Missing steps
# - Add PATH in .bash_profile
# - Copy .oci files
# - Create .oci_starter_profile
# - Create $HOME/bin/env_oci_starter_testsuite.sh 
mkdir -p $HOME/data/github/mgueury.skynet.be/test_suite
mkdir .oci

oci setup repair-file-permissions --file $HOME/.oci/config
oci setup repair-file-permissions --file $HOME/.oci/oci_api_key.pem

# Already Installed
# sudo dnf install -y dnf-utils zip unzip
# sudo dnf -y install oraclelinux-developer-release-el8

# Docker-CE
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce
sudo usermod -aG docker opc
sudo systemctl enable docker
sudo systemctl start docker

# GIT - OCICLI
sudo dnf install -y git python36-oci-cli

cd $HOME/data/github/mgueury.skynet.be
git clone https://github.com/mgueury/oci-starter.git
cp oci-starter/test_suite/* test_suite/.

# Java
sudo dnf install -y graalvm22-ee-17-jdk 
sudo dnf install -y graalvm-21-jdk
sudo update-alternatives --set java /usr/lib64/graalvm/graalvm22-ee-java17/bin/java

# Maven
sudo dnf install -y maven

# Terraform
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf -y install terraform

# JQ
sudo dnf install -y jq

# Kubectl
cd $HOME/bin
curl -LO https://dl.k8s.io/release/v1.29.2/bin/linux/arm64/kubectl
chmod +x kubectl

# tmux
sudo dnf install -y tmux