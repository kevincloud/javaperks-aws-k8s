#!/bin/bash

echo "Pre-installation tasks..."

# 
# Install OS updates
# 
echo 'libc6 libraries/restart-without-asking boolean true' | sudo debconf-set-selections
export DEBIAN_FRONTEND=noninteractive
echo "...installing Ubuntu updates"

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt-get -y update

sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    mysql-client \
    default-libmysqlclient-dev \
    curl \
    unzip \
    python3-pip \
    software-properties-common \
    gnupg2 \
    jq \
    ldap-utils

sudo apt-get install -y \
    containerd.io=1.2.13-1 \
    docker-ce=5:19.03.8~3-0~ubuntu-$(lsb_release -cs) \
    docker-ce-cli=5:19.03.8~3-0~ubuntu-$(lsb_release -cs)

sudo apt-get install -y \
    kubelet \
    kubeadm \
    kubectl

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl enable docker
systemctl daemon-reload
systemctl restart docker

pip3 install Flask
pip3 install botocore
pip3 install boto3
pip3 install mysqlclient
pip3 install awscli
pip3 install hvac

mkdir -p /root/.aws
sudo bash -c "cat >/root/.aws/config" <<EOT
[default]
aws_access_key_id=${AWS_ACCESS_KEY}
aws_secret_access_key=${AWS_SECRET_KEY}
EOT
sudo bash -c "cat >/root/.aws/credentials" <<EOT
[default]
aws_access_key_id=${AWS_ACCESS_KEY}
aws_secret_access_key=${AWS_SECRET_KEY}
EOT

echo "...setting environment variables"
export MYSQL_HOST="${MYSQL_HOST}"
export MYSQL_USER="${MYSQL_USER}"
export MYSQL_PASS="${MYSQL_PASS}"
export MYSQL_DB="${MYSQL_DB}"
export AWS_ACCESS_KEY="${AWS_ACCESS_KEY}"
export AWS_SECRET_KEY="${AWS_SECRET_KEY}"
export AWS_KMS_KEY_ID="${AWS_KMS_KEY_ID}"
export AWS_REGION="${REGION}"
export S3_BUCKET="${S3_BUCKET}"
export VAULT_LICENSE="${VAULT_LICENSE}"
export CONSUL_LICENSE="${CONSUL_LICENSE}"
export CONSUL_TOKEN="${CONSUL_TOKEN}"
export TABLE_PRODUCT="${TABLE_PRODUCT}"
export TABLE_CART="${TABLE_CART}"
export TABLE_ORDER="${TABLE_ORDER}"
export LDAP_ADMIN_PASS="${LDAP_ADMIN_PASS}"
export LDAP_ADMIN_USER="cn=admin,dc=javaperks,dc=local"
export ZONE_ID="${ZONE_ID}"
export CLIENT_IP=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`
export PUBLIC_IP=`curl -s http://169.254.169.254/latest/meta-data/public-ipv4`
export AWS_HOSTNAME=`curl -s http://169.254.169.254/latest/meta-data/local-hostname`

echo $AWS_HOSTNAME > /etc/hostname
# echo "$CLIENT_IP k8s-master" >> /etc/hosts
hostnamectl set-hostname $AWS_HOSTNAME

# 
# Clone the repo so we can run 
# our actual build scripts
# 
echo "...cloning repo"
cd /root
git clone --branch "${BRANCH_NAME}" https://github.com/kevincloud/javaperks-aws-k8s.git

echo "Preparation complete."

# 
# Run the build scripts
# 
cd /root/javaperks-aws-k8s/

# Configure Kubernetes

. /root/javaperks-aws-k8s/scripts/01_install_k8s.sh

# Set variables

export KUBEJOIN="$(cat /root/kubeadm-join.txt | sed -e ':a;N;$!ba;s/ \\\n    / /g')"
export KUBECONFIG=/etc/kubernetes/admin.conf

# Configure the Consul server

. /root/javaperks-aws-k8s/scripts/02_install_consul.sh

# Install the Vault server

. /root/javaperks-aws-k8s/scripts/03_install_vault.sh

# Install and configure Ambassador

/root/javaperks-aws-k8s/scripts/04_install_ambassador.sh

# Initial data load

/root/javaperks-aws-k8s/scripts/05_prepopulate_data.sh

# Launch JavaPerks

/root/javaperks-aws-k8s/scripts/06_launch_javaperks.sh

# Final data load

/root/javaperks-aws-k8s/scripts/07_postpopulate_data.sh

# Create DNS records

/root/javaperks-aws-k8s/scripts/08_dns_records.sh

echo "All Done!!!"
