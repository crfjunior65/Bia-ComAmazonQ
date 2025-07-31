# Terraform - Projeto BIA ECS

Este diretório contém a infraestrutura como código (IaC) para deploy do projeto BIA no Amazon ECS com EC2.

## Arquivos

- `main.tf` - Infraestrutura completa do ECS
- `variables.tf` - Variáveis de entrada
- `outputs.tf` - Outputs importantes
- `terraform.tfvars.template` - Template para suas configurações

## Pré-requisitos

1. **Terraform instalado** (>= 1.0)
2. **AWS CLI configurado** com credenciais válidas
3. **Imagem Docker no ECR** - Execute antes:
   ```bash
   # Criar repositório ECR
   aws ecr create-repository --repository-name bia-app --region us-east-1
   
   # Build e push da imagem
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
   docker build -t bia-app .
   docker tag bia-app:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/bia-app:latest
   docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/bia-app:latest
   ```
4. **Key Pair criado** na AWS para acesso SSH
5. **RDS PostgreSQL** funcionando

## Como usar

### 1. Configurar variáveis
```bash
# Copiar template
cp terraform.tfvars.template terraform.tfvars

# Editar com seus valores reais
nano terraform.tfvars
```

### 2. Executar Terraform
```bash
# Inicializar
terraform init

# Validar
terraform validate

# Planejar
terraform plan

# Aplicar
terraform apply
```

### 3. Verificar deployment
```bash
# Ver outputs
terraform output

# Verificar cluster
aws ecs describe-clusters --clusters bia-cluster --region us-east-1

# Verificar service
aws ecs describe-services --cluster bia-cluster --services bia-service --region us-east-1
```

### 4. Obter IP da aplicação
```bash
# Listar instâncias do projeto
aws ec2 describe-instances --filters "Name=tag:Project,Values=BIA" --query 'Reservations[*].Instances[*].[PublicIpAddress,State.Name]' --output table --region us-east-1

# Listar tasks para obter porta dinâmica
aws ecs list-tasks --cluster bia-cluster --service-name bia-service --region us-east-1
aws ecs describe-tasks --cluster bia-cluster --tasks <TASK_ARN> --region us-east-1
```

### 5. Testar aplicação
```bash
# Health check
curl http://<PUBLIC_IP>:<DYNAMIC_PORT>/api/versao

# Aplicação completa
curl http://<PUBLIC_IP>:<DYNAMIC_PORT>
```

## Recursos criados

### ECS
- **Cluster:** bia-cluster
- **Task Definition:** bia-tf
- **Service:** bia-service

### Security Groups
- **bia-web:** Para instâncias EC2 (portas 22, 3001, 32768-65535)
- **bia-db:** Para banco de dados (porta 5432)

### IAM
- **bia-ecs-instance-role:** Role para instâncias EC2
- **bia-ecs-task-execution-role:** Role para execução de tasks

### Auto Scaling
- **Launch Template:** bia-ecs-*
- **Auto Scaling Group:** bia-ecs-asg (1-2 instâncias t3.micro)

### Logs
- **CloudWatch Log Group:** /ecs/bia-tf (retenção 7 dias)

## Limpeza

Para destruir toda a infraestrutura:
```bash
terraform destroy
```

## Troubleshooting

### Task não inicia
1. Verificar logs no CloudWatch: `/ecs/bia-tf`
2. Verificar se a imagem existe no ECR
3. Verificar variáveis de ambiente do banco

### Não consegue acessar aplicação
1. Verificar Security Groups
2. Verificar se instância tem IP público
3. Verificar porta dinâmica da task

### Erro de permissões
1. Verificar AWS CLI configurado
2. Verificar IAM roles criadas
3. Verificar políticas anexadas

## Arquitetura

```
Internet
    ↓
[Security Group: bia-web]
    ↓
[EC2 Instance] ← [Auto Scaling Group]
    ↓
[ECS Task: bia-container]
    ↓
[Security Group: bia-db]
    ↓
[RDS PostgreSQL]
```

Esta configuração segue as regras do projeto BIA:
- Nomenclatura padrão (bia-*)
- Instâncias t3.micro
- Arquitetura simples sem ALB
- Foco educacional
