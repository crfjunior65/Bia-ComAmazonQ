#!/bin/bash

# Script de Otimização CloudWatch Logs
# Economia estimada: $0.10-0.20/mês

echo "🔧 Otimizando CloudWatch Logs para reduzir custos..."

# 1. Configurar retenção de 7 dias para logs do ECS
echo "📅 Configurando retenção de logs para 7 dias..."
aws logs put-retention-policy \
    --log-group-name "/ecs/task-def-bia" \
    --retention-in-days 7 \
    --region us-east-1

# 2. Criar filtro de logs para reduzir volume (opcional)
echo "🔍 Configurando filtro de logs para reduzir ruído..."
aws logs put-metric-filter \
    --log-group-name "/ecs/task-def-bia" \
    --filter-name "bia-error-filter" \
    --filter-pattern "[timestamp, request_id, level=\"ERROR\", ...]" \
    --metric-transformations \
        metricName=BiaErrors,metricNamespace=BIA/Application,metricValue=1 \
    --region us-east-1

# 3. Verificar grupos de logs existentes e suas configurações
echo "📊 Verificando configurações atuais..."
aws logs describe-log-groups \
    --log-group-name-prefix "/ecs/" \
    --region us-east-1 \
    --query 'logGroups[*].[logGroupName,retentionInDays,storedBytes]' \
    --output table

# 4. Script para limpeza de logs antigos (executar manualmente se necessário)
cat > /tmp/cleanup-old-logs.sh << 'EOF'
#!/bin/bash
# Limpar logs mais antigos que 7 dias manualmente
LOG_GROUP="/ecs/task-def-bia"
CUTOFF_DATE=$(date -d '7 days ago' +%s)000

aws logs describe-log-streams \
    --log-group-name "$LOG_GROUP" \
    --region us-east-1 \
    --query "logStreams[?lastEventTime<\`$CUTOFF_DATE\`].logStreamName" \
    --output text | while read stream; do
    if [ ! -z "$stream" ]; then
        echo "Deletando stream antigo: $stream"
        aws logs delete-log-stream \
            --log-group-name "$LOG_GROUP" \
            --log-stream-name "$stream" \
            --region us-east-1
    fi
done
EOF

chmod +x /tmp/cleanup-old-logs.sh
echo "📝 Script de limpeza criado em /tmp/cleanup-old-logs.sh"

echo "✅ Otimização CloudWatch concluída!"
echo "💰 Economia estimada: $0.10-0.20/mês"
