# 🛠️ Scripts de Otimização de Custos

## 📋 Scripts Disponíveis

### 🐳 ECR Optimization
**Arquivo:** `optimize-ecr.sh`
**Economia:** $0.03-0.10/mês
**Downtime:** 0
**Descrição:** Configura lifecycle policy para manter apenas 5 imagens mais recentes

```bash
./optimize-ecr.sh
```

### 📊 CloudWatch Optimization  
**Arquivo:** `optimize-cloudwatch.sh`
**Economia:** $0.10-0.20/mês
**Downtime:** 0
**Descrição:** Configura retenção de 7 dias e filtros de logs

```bash
./optimize-cloudwatch.sh
```

### 🗄️ RDS Optimization
**Arquivo:** `optimize-rds.sh`
**Economia:** $0.30/mês
**Downtime:** 5-10 minutos
**Descrição:** Migra storage de GP2 para GP3

```bash
./optimize-rds.sh
# Executa análise, script de migração fica em /tmp/migrate-rds-to-gp3.sh
```

### ⏰ Schedule Implementation
**Arquivo:** `implement-schedule.sh`
**Economia:** $10.80/mês (apenas desenvolvimento)
**Downtime:** 0
**Descrição:** Implementa schedule automático (para às 18h, inicia às 8h)

```bash
./implement-schedule.sh
```

## 🚀 Execução Rápida

### Otimizações Básicas (0 Downtime)
```bash
# Executar em sequência
chmod +x *.sh

./optimize-ecr.sh
./optimize-cloudwatch.sh

echo "✅ Otimizações básicas concluídas!"
echo "💰 Economia: ~$0.13-0.30/mês"
```

### Otimização Completa (Com Downtime Mínimo)
```bash
# Incluir RDS (requer janela de manutenção)
./optimize-rds.sh
# Depois executar: /tmp/migrate-rds-to-gp3.sh

echo "✅ Otimização completa!"
echo "💰 Economia: ~$0.43-0.60/mês"
```

### Schedule para Desenvolvimento
```bash
# APENAS para ambiente de desenvolvimento
./implement-schedule.sh

# Controle manual disponível em:
# /tmp/manual-ecs-control.sh {start|stop|status}
```

## ⚠️ Considerações Importantes

### Pré-requisitos
- AWS CLI configurado
- Permissões adequadas (ECS, RDS, ECR, CloudWatch, Lambda, EventBridge)
- Acesso à região us-east-1

### Logs e Troubleshooting
- Logs dos scripts: `/tmp/`
- Verificar permissões IAM se houver erros
- Testar em ambiente de desenvolvimento primeiro

### Rollback
- ECR: Lifecycle policies podem ser removidas
- CloudWatch: Retenção pode ser alterada de volta
- RDS: Migração GP3→GP2 possível (com downtime)
- Schedule: Remover regras do EventBridge

## 📊 Monitoramento Pós-Execução

### Verificar Implementação
```bash
# ECR
aws ecr describe-repository --repository-name bia --region us-east-1

# CloudWatch
aws logs describe-log-groups --log-group-name-prefix "/ecs/" --region us-east-1

# RDS
aws rds describe-db-instances --db-instance-identifier bia --region us-east-1

# Schedule (se implementado)
aws events list-rules --name-prefix "bia-" --region us-east-1
```

### Métricas de Economia
- Acompanhar fatura AWS nos próximos 30 dias
- Verificar redução no Cost Explorer
- Monitorar alertas de budget

## 🆘 Suporte

### Em caso de problemas:
1. Verificar logs em `/tmp/`
2. Confirmar permissões IAM
3. Testar conectividade AWS CLI
4. Consultar documentação detalhada em `../docs/`

### Scripts de Diagnóstico
```bash
# Verificar configuração AWS
aws sts get-caller-identity

# Verificar recursos
aws ecs describe-clusters --clusters custer-bia --region us-east-1
aws rds describe-db-instances --db-instance-identifier bia --region us-east-1
```

---

*Scripts testados em: 31/07/2025*
*Compatível com: AWS CLI v2, Bash 4+*
*Região: us-east-1*
