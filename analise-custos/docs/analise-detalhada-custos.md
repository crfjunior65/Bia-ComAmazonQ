# Análise de Custos Mensais - Projeto BIA

## 💰 Resumo Executivo de Custos

**Custo Total Estimado Mensal: $23.50 - $28.50 USD**

---

## 📊 Detalhamento por Serviço AWS

### 1. Amazon EC2 (ECS Cluster)
**Configuração Atual:**
- Instância: t3.micro
- Região: us-east-1
- Uso: 24/7 (730 horas/mês)

**Custos:**
- **On-Demand:** $0.0104/hora × 730h = **$7.59/mês**
- **Spot Instance (recomendado):** ~$3.80/mês (50% desconto)

### 2. Amazon RDS PostgreSQL
**Configuração Atual:**
- Instância: db.t3.micro
- Engine: PostgreSQL 17.4
- Storage: 20GB GP2
- Multi-AZ: Não
- Backup: Desabilitado

**Custos:**
- **Instância:** $0.017/hora × 730h = **$12.41/mês**
- **Storage:** 20GB × $0.115/GB = **$2.30/mês**
- **Total RDS:** **$14.71/mês**

### 3. Amazon ECR (Container Registry)
**Configuração Atual:**
- Repository: bia
- Imagens armazenadas: ~2-3 imagens
- Tamanho estimado: 500MB

**Custos:**
- **Storage:** 0.5GB × $0.10/GB = **$0.05/mês**
- **Data Transfer:** Mínimo (dentro da região)

### 4. Amazon CloudWatch
**Configuração Atual:**
- Log Group: /ecs/task-def-bia
- Retenção: Padrão (indefinida)
- Logs estimados: 100MB/mês

**Custos:**
- **Log Ingestion:** 0.1GB × $0.50/GB = **$0.05/mês**
- **Log Storage:** 0.1GB × $0.03/GB = **$0.003/mês**
- **Total CloudWatch:** **$0.05/mês**

### 5. AWS CodeBuild
**Configuração Atual:**
- Builds ocasionais (desenvolvimento)
- Tipo: build.general1.small
- Estimativa: 10 builds/mês × 5 min cada

**Custos:**
- **Compute:** 50 min × $0.005/min = **$0.25/mês**

### 6. Elastic Load Balancer (Recomendado)
**Não implementado atualmente, mas necessário:**
- Application Load Balancer
- Target Groups

**Custos Adicionais:**
- **ALB:** $16.20/mês (fixo)
- **LCU:** ~$5.00/mês (estimado)
- **Total ALB:** **$21.20/mês**

### 7. Data Transfer
**Configuração Atual:**
- Tráfego de saída estimado: 1GB/mês
- Tráfego interno: Gratuito

**Custos:**
- **Data Transfer Out:** 1GB × $0.09/GB = **$0.09/mês**

---

## 📈 Cenários de Custo

### Cenário Atual (Configuração Básica)
```
EC2 t3.micro (On-Demand)     $7.59
RDS db.t3.micro              $14.71
ECR Storage                  $0.05
CloudWatch Logs              $0.05
CodeBuild                    $0.25
Data Transfer                $0.09
─────────────────────────────────
TOTAL MENSAL:                $22.74
```

### Cenário Recomendado (Com ALB)
```
EC2 t3.micro (Spot)          $3.80
RDS db.t3.micro              $14.71
ECR Storage                  $0.05
CloudWatch Logs              $0.05
CodeBuild                    $0.25
ALB + Target Groups          $21.20
Data Transfer                $0.09
─────────────────────────────────
TOTAL MENSAL:                $40.15
```

### Cenário Otimizado (Produção)
```
EC2 t3.small (2x instâncias) $30.40
RDS db.t3.small              $29.42
ECR Storage                  $0.10
CloudWatch (+ métricas)      $2.00
CodeBuild                    $1.00
ALB + Target Groups          $21.20
WAF                          $5.00
Data Transfer                $2.00
─────────────────────────────────
TOTAL MENSAL:                $91.12
```

---

## 🎯 Oportunidades de Otimização

### 1. Savings Plans / Reserved Instances
**Economia potencial: 30-50%**
- EC2 Reserved Instance (1 ano): $4.50/mês (40% economia)
- RDS Reserved Instance (1 ano): $8.80/mês (40% economia)

### 2. Spot Instances para ECS
**Economia potencial: 50-70%**
- EC2 Spot: $3.80/mês vs $7.59/mês On-Demand

### 3. Storage Optimization
**RDS Storage:**
- Migrar para GP3: $2.00/mês vs $2.30/mês (GP2)
- Implementar backup com retenção otimizada

### 4. CloudWatch Optimization
**Log Management:**
- Configurar retenção de 7 dias: Reduz custos de storage
- Usar log filtering para reduzir volume

---

## 📊 Comparativo de Custos por Ambiente

### Desenvolvimento
```
EC2 t3.micro (Spot)          $3.80
RDS db.t3.micro              $14.71
Outros serviços              $0.50
─────────────────────────────────
TOTAL DEV:                   $19.01/mês
```

### Staging
```
EC2 t3.micro (On-Demand)     $7.59
RDS db.t3.micro              $14.71
ALB                          $21.20
Outros serviços              $1.00
─────────────────────────────────
TOTAL STAGING:               $44.50/mês
```

### Produção
```
EC2 t3.small (2x, Reserved)  $18.00
RDS db.t3.small (Reserved)   $17.60
ALB + WAF                    $26.20
CloudWatch + Monitoring      $5.00
Outros serviços              $3.00
─────────────────────────────────
TOTAL PROD:                  $69.80/mês
```

---

## 🚨 Alertas de Custo Recomendados

### 1. Budget Alerts
```
Desenvolvimento: $25/mês
Staging: $50/mês
Produção: $80/mês
```

### 2. Cost Anomaly Detection
- Configurar para detectar aumentos > 20%
- Alertas via SNS/Email

### 3. Resource Tagging
```
Environment: dev/staging/prod
Project: bia
Owner: henrylle
CostCenter: bootcamp
```

---

## 💡 Recomendações Estratégicas

### Curto Prazo (1-2 meses)
1. **Implementar Spot Instances:** Economia de $3.79/mês
2. **Configurar log retention:** Economia de $0.10/mês
3. **Otimizar ECR lifecycle:** Economia de $0.05/mês

### Médio Prazo (3-6 meses)
1. **Reserved Instances:** Economia de $8.50/mês
2. **Migrar para GP3 storage:** Economia de $0.30/mês
3. **Implementar auto-scaling:** Otimização dinâmica

### Longo Prazo (6+ meses)
1. **Considerar Fargate:** Pode reduzir custos operacionais
2. **Implementar CDN:** Reduzir data transfer costs
3. **Multi-region strategy:** Otimização global

---

## 📋 Checklist de Monitoramento

### Diário
- [ ] Verificar instâncias em execução
- [ ] Monitorar uso de CPU/Memória

### Semanal
- [ ] Revisar logs do CloudWatch
- [ ] Verificar builds do CodeBuild
- [ ] Analisar data transfer

### Mensal
- [ ] Revisar fatura AWS
- [ ] Otimizar recursos subutilizados
- [ ] Avaliar necessidade de scaling

---

## 🎓 Considerações Educacionais

Para o contexto do bootcamp, o custo atual de **~$23/mês** é adequado para:
- Demonstrar conceitos de arquitetura
- Permitir experimentação
- Manter custos controlados

**Recomendação:** Manter configuração atual durante o bootcamp e implementar otimizações gradualmente conforme o aprendizado evolui.

---

*Última atualização: 31/07/2025*
*Preços baseados na região us-east-1*
*Valores podem variar conforme uso real*
