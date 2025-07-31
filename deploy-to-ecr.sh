#!/bin/env bash

# Configurações
AWS_ACCOUNT_ID="873976612170"
AWS_REGION="us-east-1"
ECR_REPO_NAME="bia"
ECR_REPO_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

# Obter a versão do projeto (ajuste conforme sua necessidade)
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.1")

# 1. Fazer login no AWS ECR
echo "Fazendo login no ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# 2. Construir a imagem Docker
echo "Construindo a imagem Docker..."
docker build -t ${ECR_REPO_NAME} .

# 3. Taggear a imagem com latest e com a versão
echo "Taggeando a imagem..."
docker tag ${ECR_REPO_NAME}:latest ${ECR_REPO_URI}:latest
docker tag ${ECR_REPO_NAME}:latest ${ECR_REPO_URI}:${VERSION}

# 4. Fazer push das imagens para o ECR
echo "Fazendo push das imagens para o ECR..."
docker push ${ECR_REPO_URI}:latest
docker push ${ECR_REPO_URI}:${VERSION}

echo "Processo concluído!"
echo "Imagem disponível no ECR com as tags:"
echo "- ${ECR_REPO_URI}:latest"
echo "- ${ECR_REPO_URI}:${VERSION}"
