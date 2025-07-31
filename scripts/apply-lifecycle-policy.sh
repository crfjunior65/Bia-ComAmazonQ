#!/bin/bash

# Script para aplicar lifecycle policy no repositório ECR

set -e

# Configurações
AWS_REGION="us-east-1"
IMAGE_REPO_NAME="bia"
POLICY_FILE="scripts/ecr-lifecycle-policy.json"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Aplicando Lifecycle Policy no ECR ===${NC}"

# Verificar se o arquivo de política existe
if [ ! -f "$POLICY_FILE" ]; then
    echo "Erro: Arquivo de política não encontrado: $POLICY_FILE"
    exit 1
fi

echo -e "${YELLOW}Aplicando política de lifecycle...${NC}"

# Aplicar a política
aws ecr put-lifecycle-policy \
    --repository-name $IMAGE_REPO_NAME \
    --region $AWS_REGION \
    --lifecycle-policy-text file://$POLICY_FILE

echo -e "${GREEN}Lifecycle policy aplicada com sucesso!${NC}"

# Mostrar a política aplicada
echo -e "${BLUE}Política atual:${NC}"
aws ecr get-lifecycle-policy \
    --repository-name $IMAGE_REPO_NAME \
    --region $AWS_REGION \
    --query 'lifecyclePolicyText' \
    --output text | jq .
