#!/bin/bash

# Script de Otimização ECR
# Economia estimada: $0.05-0.10/mês

echo "🐳 Otimizando ECR para reduzir custos de storage..."

# 1. Criar lifecycle policy para manter apenas 5 imagens mais recentes
echo "📋 Configurando lifecycle policy..."

cat > /tmp/ecr-lifecycle-policy.json << 'EOF'
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 5 tagged images",
            "selection": {
                "tagStatus": "tagged",
                "countType": "imageCountMoreThan",
                "countNumber": 5
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 2,
            "description": "Delete untagged images older than 1 day",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF

# 2. Aplicar a policy no repositório BIA
aws ecr put-lifecycle-policy \
    --repository-name bia \
    --lifecycle-policy-text file:///tmp/ecr-lifecycle-policy.json \
    --region us-east-1

# 3. Verificar imagens atuais no repositório
echo "📊 Verificando imagens atuais no repositório..."
aws ecr describe-images \
    --repository-name bia \
    --region us-east-1 \
    --query 'imageDetails[*].[imageTags[0],imageSizeInBytes,imagePushedAt]' \
    --output table

# 4. Calcular economia estimada
TOTAL_SIZE=$(aws ecr describe-images \
    --repository-name bia \
    --region us-east-1 \
    --query 'sum(imageDetails[*].imageSizeInBytes)' \
    --output text)

if [ "$TOTAL_SIZE" != "None" ] && [ "$TOTAL_SIZE" -gt 0 ]; then
    SIZE_GB=$(echo "scale=3; $TOTAL_SIZE / 1024 / 1024 / 1024" | bc)
    MONTHLY_COST=$(echo "scale=3; $SIZE_GB * 0.10" | bc)
    echo "📈 Tamanho total atual: ${SIZE_GB}GB"
    echo "💰 Custo mensal atual: \$${MONTHLY_COST}"
else
    echo "📊 Não foi possível calcular o tamanho total"
fi

# 5. Limpeza manual de imagens antigas (executar se necessário)
cat > /tmp/manual-ecr-cleanup.sh << 'EOF'
#!/bin/bash
# Limpeza manual de imagens não taggeadas
echo "🧹 Limpando imagens não taggeadas..."

aws ecr list-images \
    --repository-name bia \
    --filter tagStatus=UNTAGGED \
    --region us-east-1 \
    --query 'imageIds[*]' \
    --output json > /tmp/untagged-images.json

if [ -s /tmp/untagged-images.json ] && [ "$(cat /tmp/untagged-images.json)" != "[]" ]; then
    aws ecr batch-delete-image \
        --repository-name bia \
        --image-ids file:///tmp/untagged-images.json \
        --region us-east-1
    echo "✅ Imagens não taggeadas removidas"
else
    echo "ℹ️  Nenhuma imagem não taggeada encontrada"
fi
EOF

chmod +x /tmp/manual-ecr-cleanup.sh
echo "📝 Script de limpeza manual criado em /tmp/manual-ecr-cleanup.sh"

echo "✅ Otimização ECR concluída!"
echo "💰 Economia estimada: $0.05-0.10/mês"
