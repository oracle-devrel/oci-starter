# Missing steps
# - Add PATH in .bash_profile
# - Copy .oci files
# - Create .oci_starter_profile
# - Create $HOME/bin/env_oci_starter_testsuite.sh 
# - Copy data/tls/dns6.xxxx

# SSH
# add in /etc/ssh/sshd_config
# ClientAliveInterval 120
# ClientAliveCountMax 3

mkdir -p $HOME/data/github/mgueury.skynet.be/test_suite
mkdir .oci


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

oci setup repair-file-permissions --file $HOME/.oci/config
oci setup repair-file-permissions --file $HOME/.oci/oci_api_key.pem


# Java
sudo dnf install -y graalvm22-ee-17-jdk 
sudo dnf install -y graalvm-21-jdk
sudo update-alternatives --set java /usr/lib64/graalvm/graalvm22-ee-java17/bin/java
echo "export JAVA_HOME=/usr/lib64/graalvm/graalvm22-ee-java17" >> $HOME/.bashrc

# Node (JET/Angular/ReactJS)
sudo dnf module enable -y nodejs:18
sudo dnf install -y nodejs

# Maven
sudo dnf install -y maven

# Terraform
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf -y install terraform

# JQ
sudo dnf install -y jq

# Kubectl
# XXX Got forbidden and had to download manually ?
mkdir -p $HOME/bin
cd $HOME/bin
if [ `arch` == "x86_64" ]; then
  ARCH_PREFIX=amd64
else
  ARCH_PREFIX=arm64
fi
curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH_PREFIX}/kubectl
chmod +x kubectl
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "shopt -s direxpand" >> ~/.bashrc

# Helm
cd /tmp
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# FN
curl -LSs https://raw.githubusercontent.com/fnproject/cli/master/install | sh

# tmux
sudo dnf install -y tmux

# VIM
cat >> $HOME/.vimrc <<'EOT' 
set tabstop=2
set expandtab
set shiftwidth=2
set paste
EOT
