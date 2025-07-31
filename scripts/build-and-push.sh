#!/bin/bash

# Script para build e push manual das imagens BIA
# Uso: ./scripts/build-and-push.sh [tag-personalizada]

set -e

# Configurações
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="905418381762"
IMAGE_REPO_NAME="bia"
REPOSITORY_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_REPO_NAME"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== BIA - Build and Push Script ===${NC}"

# Verificar se estamos no diretório correto
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}Erro: Dockerfile não encontrado. Execute o script na raiz do projeto.${NC}"
    exit 1
fi

# Login no ECR
echo -e "${YELLOW}Fazendo login no ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REPOSITORY_URI

# Obter informações de versionamento
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CUSTOM_TAG=${1:-"dev-$TIMESTAMP"}

echo -e "${BLUE}Informações da build:${NC}"
echo "Repository URI: $REPOSITORY_URI"
echo "Commit Hash: $COMMIT_HASH"
echo "Timestamp: $TIMESTAMP"
echo "Custom Tag: $CUSTOM_TAG"

# Build da imagem
echo -e "${YELLOW}Iniciando build da imagem...${NC}"
docker build -t $REPOSITORY_URI:latest .

# Criando tags
echo -e "${YELLOW}Criando tags...${NC}"
docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$COMMIT_HASH
docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$CUSTOM_TAG

# Push das imagens
echo -e "${YELLOW}Fazendo push das imagens...${NC}"
docker push $REPOSITORY_URI:latest
docker push $REPOSITORY_URI:$COMMIT_HASH
docker push $REPOSITORY_URI:$CUSTOM_TAG

# Limpeza local
echo -e "${YELLOW}Limpando imagens locais...${NC}"
docker rmi $REPOSITORY_URI:latest || true
docker rmi $REPOSITORY_URI:$COMMIT_HASH || true
docker rmi $REPOSITORY_URI:$CUSTOM_TAG || true

echo -e "${GREEN}=== Build e Push concluídos com sucesso! ===${NC}"
echo -e "${GREEN}Tags disponíveis no ECR:${NC}"
echo "- latest"
echo "- $COMMIT_HASH"
echo "- $CUSTOM_TAG"

# Listar imagens no ECR
echo -e "${BLUE}Listando imagens no ECR:${NC}"
aws ecr describe-images --repository-name $IMAGE_REPO_NAME --region $AWS_REGION --query 'imageDetails[*].[imageTags[0],imageDigest,imagePushedAt]' --output table || echo "Erro ao listar imagens do ECR"
