#!/bin/bash

# Script de Otimização RDS
# Economia estimada: $0.30/mês

echo "🗄️  Otimizando RDS para reduzir custos de storage..."

# 1. Verificar configuração atual do RDS
echo "📊 Verificando configuração atual..."
aws rds describe-db-instances \
    --db-instance-identifier bia \
    --region us-east-1 \
    --query 'DBInstances[0].[DBInstanceIdentifier,AllocatedStorage,StorageType,Iops]' \
    --output table

# 2. Verificar uso atual de storage
echo "📈 Verificando uso atual de storage..."
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name FreeStorageSpace \
    --dimensions Name=DBInstanceIdentifier,Value=bia \
    --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 86400 \
    --statistics Average \
    --region us-east-1 \
    --query 'Datapoints[*].[Timestamp,Average]' \
    --output table

# 3. Criar script para migração para GP3 (executar em janela de manutenção)
cat > /tmp/migrate-rds-to-gp3.sh << 'EOF'
#!/bin/bash
# ATENÇÃO: Este script causa downtime. Execute em janela de manutenção.

echo "⚠️  ATENÇÃO: Esta operação causará downtime!"
echo "Pressione ENTER para continuar ou Ctrl+C para cancelar..."
read

echo "🔄 Migrando RDS de GP2 para GP3..."

# Modificar o tipo de storage para GP3
aws rds modify-db-instance \
    --db-instance-identifier bia \
    --storage-type gp3 \
    --allocated-storage 20 \
    --apply-immediately \
    --region us-east-1

echo "✅ Migração iniciada. Monitorando status..."

# Monitorar o status da modificação
while true; do
    STATUS=$(aws rds describe-db-instances \
        --db-instance-identifier bia \
        --region us-east-1 \
        --query 'DBInstances[0].DBInstanceStatus' \
        --output text)
    
    echo "Status atual: $STATUS"
    
    if [ "$STATUS" = "available" ]; then
        echo "✅ Migração concluída!"
        break
    fi
    
    sleep 30
done

# Verificar nova configuração
aws rds describe-db-instances \
    --db-instance-identifier bia \
    --region us-east-1 \
    --query 'DBInstances[0].[StorageType,AllocatedStorage]' \
    --output table

echo "💰 Economia estimada: $0.30/mês (GP3 vs GP2)"
EOF

chmod +x /tmp/migrate-rds-to-gp3.sh

# 4. Verificar se há snapshots desnecessários
echo "📸 Verificando snapshots automáticos..."
aws rds describe-db-snapshots \
    --db-instance-identifier bia \
    --snapshot-type automated \
    --region us-east-1 \
    --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime,AllocatedStorage]' \
    --output table

# 5. Calcular economia potencial
echo "💰 Calculando economia potencial..."
echo "Atual (GP2): 20GB × \$0.115/GB = \$2.30/mês"
echo "Novo (GP3):  20GB × \$0.100/GB = \$2.00/mês"
echo "Economia:    \$0.30/mês (13% de redução)"

echo "📝 Script de migração criado em /tmp/migrate-rds-to-gp3.sh"
echo "⚠️  Execute apenas durante janela de manutenção!"

echo "✅ Análise RDS concluída!"
