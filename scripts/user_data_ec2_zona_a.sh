#!/bin/bash

#Instalar Docker e Git
sudo yum update -y
sudo yum install git -y
sudo yum install docker -y
sudo usermod -a -G docker ec2-user
sudo usermod -a -G docker ssm-user
id ec2-user ssm-user
sudo newgrp docker

#Ativar docker
sudo systemctl enable docker.service
sudo systemctl start docker.service

#Instalar docker compose 2
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose


#Adicionar swap
sudo dd if=/dev/zero of=/swapfile bs=128M count=32
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo echo "/swapfile swap swap defaults 0 0" >> /etc/fstab


#Instalar node e npm
curl -fsSL https://rpm.nodesource.com/setup_21.x | sudo bash -
sudo yum install -y nodejs

#Configurar python 3.11 e uv para uso com mcp servers da aws
sudo dnf install python3.11 -y
sudo ln -sf /usr/bin/python3.11 /usr/bin/python3

curl -LsSf https://astral.sh/uv/install.sh | sh

cd /home/ec2-user

#Instalar o mcp servers da aws
git clone https://github.com/aws/mcp-servers.git
cd mcp-servers
uv pip install -r requirements.txt
uv pip install aws-mcp-servers
uv pip install aws-mcp-servers-cli
uv pip install aws-mcp-servers-cli-aws
uv pip install aws-mcp-servers-cli-aws-ec2
uv pip install aws-mcp-servers-cli-aws-ec2-zona-a

# Instalando jq
sudo yum install jq -y

#Instalando AWS CLI v2
sudo yum install unzip -y
curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
unzip awscliv2.zip
sudo ./aws/install

#Instalando AmazonQ CLI
#https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-installing-ssh-setup-autocomplete.html
cd /home/ec2-user
curl --proto '=https' --tlsv1.2 -sSf "https://desktop-release.q.us-east-1.amazonaws.com/latest/q-x86_64-linux.zip" -o "q.zip"
unzip q.zip 

#./q/install.sh
#Confirm the following code in the browser
#Code: XPBF-VKJT

#Open this URL: https://view.awsapps.com/start/#/device?user_code=XPBF-VKJT
#Device authorized
#Logged in successfully

#Gerar Par de Chaves
#ssh-keygen

#Instalando AmazonQ 

sudo curl -s https://raw.githubusercontent.com/aws/amazonq-cli/main/install.sh | bash
