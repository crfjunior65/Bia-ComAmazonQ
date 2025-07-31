# 🏗️ Templates Terraform para Otimização de Custos

## 📋 Templates Disponíveis

### 💰 Spot Instances Optimization
**Arquivo:** `terraform-spot-optimization.tf`
**Economia:** $3.79/mês (50% de redução no EC2)
**Descrição:** Implementa Spot Instances com mixed instance policy para ECS

## 🚀 Como Usar

### 1. Backup da Configuração Atual
```bash
# Fazer backup do terraform atual
cp ../terraform/main.tf ../terraform/main.tf.backup
```

### 2. Integrar Template de Spot Instances
```bash
# Opção 1: Substituir launch template existente
cat terraform-spot-optimization.tf >> ../terraform/main.tf

# Opção 2: Aplicar apenas o recurso específico
terraform plan -target=aws_launch_template.ecs_spot_template
terraform apply -target=aws_launch_template.ecs_spot_template
```

### 3. Aplicar Mudanças
```bash
cd ../terraform

# Planejar mudanças
terraform plan

# Aplicar (com confirmação)
terraform apply

# Ou aplicar automaticamente
terraform apply -auto-approve
```

## ⚙️ Configurações do Template

### Spot Instance Configuration
```hcl
instance_market_options {
  market_type = "spot"
  spot_options {
    max_price                      = "0.0052"  # 50% do preço On-Demand
    spot_instance_type            = "one-time"
    instance_interruption_behavior = "terminate"
  }
}
```

### Mixed Instance Policy
```hcl
mixed_instances_policy {
  instances_distribution {
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 0  # 100% Spot
    spot_allocation_strategy                 = "diversified"
    spot_instance_pools                      = 2
    spot_max_price                          = "0.0052"
  }
}
```

### Instance Types Suportados
- `t3.micro` (principal)
- `t3a.micro` (alternativa mais barata)

## 🛡️ Recursos de Segurança

### Spot Interruption Handler
O template inclui script automático para lidar com interrupções:

```bash
# Script executado automaticamente na instância
/opt/spot-interruption-handler.sh
```

**Funcionalidades:**
- Monitora notificações de interrupção
- Drena tasks do ECS gracefully
- Aguarda 2 minutos antes da terminação

### Auto Scaling Group
- **Min Size:** 1
- **Max Size:** 2  
- **Desired:** 1
- **Strategy:** Diversified across AZs

## 📊 Monitoramento

### Verificar Spot Instances
```bash
# Verificar requests de Spot Instance
aws ec2 describe-spot-instance-requests --region us-east-1

# Verificar instâncias ativas
aws ec2 describe-instances \
  --filters "Name=instance-lifecycle,Values=spot" \
  --region us-east-1
```

### Monitorar Interrupções
```bash
# CloudWatch Logs do spot interruption handler
aws logs describe-log-streams \
  --log-group-name "/aws/ec2/spot" \
  --region us-east-1
```

### Verificar ECS Health
```bash
# Status do cluster
aws ecs describe-clusters --clusters custer-bia --region us-east-1

# Status do serviço
aws ecs describe-services \
  --cluster custer-bia \
  --services service-bia \
  --region us-east-1
```

## ⚠️ Considerações Importantes

### Riscos
- **Interrupção:** Spot instances podem ser interrompidas com 2 min de aviso
- **Disponibilidade:** Pode haver momentos sem capacidade disponível
- **Latência:** Restart pode levar alguns minutos

### Mitigações
- **Graceful Shutdown:** Script automático drena tasks
- **Multiple AZs:** Diversificação reduz risco
- **Mixed Policy:** Fallback para diferentes tipos de instância
- **Auto Scaling:** Substitui instâncias automaticamente

### Quando Usar
- ✅ **Desenvolvimento:** Ideal para reduzir custos
- ✅ **Staging:** Aceitável com monitoramento
- ⚠️ **Produção:** Apenas com arquitetura resiliente

## 🔄 Rollback

### Voltar para On-Demand
```bash
# Restaurar configuração original
cp ../terraform/main.tf.backup ../terraform/main.tf

# Aplicar mudanças
terraform plan
terraform apply
```

### Rollback Parcial
```bash
# Remover apenas recursos de Spot
terraform destroy -target=aws_launch_template.ecs_spot_template
terraform destroy -target=aws_autoscaling_group.ecs_spot_asg
```

## 💡 Otimizações Futuras

### Reserved Instances
Para uso de longo prazo, considere Reserved Instances:
- **Economia:** 30-40% vs On-Demand
- **Commitment:** 1-3 anos
- **Estabilidade:** Sem risco de interrupção

### Fargate Spot
Para workloads containerizados:
```hcl
capacity_providers = ["FARGATE_SPOT"]
```

### Savings Plans
Alternativa flexível às Reserved Instances:
- **Compute Savings Plans:** Até 66% de economia
- **EC2 Instance Savings Plans:** Até 72% de economia

## 📈 Métricas de Sucesso

### Economia Esperada
- **Custo Atual:** $7.59/mês (t3.micro On-Demand)
- **Custo Novo:** $3.80/mês (t3.micro Spot)
- **Economia:** $3.79/mês (50% de redução)

### KPIs para Monitorar
- Spot interruption rate (< 5% aceitável)
- Application uptime (> 99% desejável)
- Cost per hour (50% de redução esperada)
- Time to recovery (< 5 min desejável)

---

*Templates testados em: 31/07/2025*
*Compatível com: Terraform >= 1.0, AWS Provider ~> 5.0*
*Região: us-east-1*
