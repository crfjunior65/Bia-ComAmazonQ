#!/bin/bash

# Script para limpeza de imagens antigas no ECR
# Mantém apenas as N imagens mais recentes (padrão: 10)

set -e

# Configurações
AWS_REGION="us-east-1"
IMAGE_REPO_NAME="bia"
KEEP_IMAGES=${1:-10}

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ECR Cleanup Script ===${NC}"
echo "Repository: $IMAGE_REPO_NAME"
echo "Região: $AWS_REGION"
echo "Manter últimas: $KEEP_IMAGES imagens"

# Listar imagens ordenadas por data (mais antigas primeiro)
echo -e "${YELLOW}Buscando imagens antigas...${NC}"

# Obter lista de imagens (excluindo 'latest')
IMAGES_TO_DELETE=$(aws ecr describe-images \
    --repository-name $IMAGE_REPO_NAME \
    --region $AWS_REGION \
    --query "sort_by(imageDetails[?!contains(imageTags[0], 'latest')], &imagePushedAt)[:-$KEEP_IMAGES].imageDigest" \
    --output text)

if [ -z "$IMAGES_TO_DELETE" ]; then
    echo -e "${GREEN}Nenhuma imagem antiga encontrada para limpeza.${NC}"
    exit 0
fi

echo -e "${YELLOW}Imagens que serão removidas:${NC}"
for digest in $IMAGES_TO_DELETE; do
    echo "- $digest"
done

# Confirmação
read -p "Deseja continuar com a limpeza? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Operação cancelada.${NC}"
    exit 0
fi

# Deletar imagens
echo -e "${YELLOW}Removendo imagens antigas...${NC}"
for digest in $IMAGES_TO_DELETE; do
    echo "Removendo: $digest"
    aws ecr batch-delete-image \
        --repository-name $IMAGE_REPO_NAME \
        --region $AWS_REGION \
        --image-ids imageDigest=$digest \
        --output text
done

echo -e "${GREEN}Limpeza concluída com sucesso!${NC}"

# Mostrar status final
echo -e "${BLUE}Imagens restantes no repositório:${NC}"
aws ecr describe-images \
    --repository-name $IMAGE_REPO_NAME \
    --region $AWS_REGION \
    --query 'imageDetails[*].[imageTags[0],imageDigest,imagePushedAt]' \
    --output table
