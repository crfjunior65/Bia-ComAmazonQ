# IaaC - Infrastructure as Code

## Visão Geral
Este diretório contém toda a infraestrutura como código (Infrastructure as Code) do projeto BIA, implementada com Terraform. A infraestrutura segue as melhores práticas da AWS e é projetada para ser educacional, priorizando simplicidade e compreensão.

## Filosofia do Projeto

### Público-Alvo
- **Alunos em aprendizado**: Estrutura didática e progressiva
- **Iniciantes em AWS**: Conceitos fundamentais bem explicados
- **Desenvolvedores**: Transição para DevOps e Cloud

### Princípios
- **Simplicidade acima de complexidade**: Código claro e direto
- **Evolução gradual**: Arquitetura que cresce com o conhecimento
- **Boas práticas**: Implementação de padrões da indústria
- **Custo otimizado**: Uso de recursos t3.micro para aprendizado

## Estrutura da Infraestrutura

```
IaaC/
└── Terraform/
    ├── 0-TerraformState/    # Backend remoto do Terraform
    ├── 1-VPC/               # Virtual Private Cloud
    ├── 1a-SegGroup/         # Security Groups
    ├── 1b-IAM/              # Roles e Policies IAM
    ├── 3-RDS/               # Banco de dados PostgreSQL
    ├── 3a-Orquestrador/     # ECS Cluster
    ├── 3b-EC2/              # Instâncias EC2
    ├── 4-Bucket/            # S3 Buckets
    ├── 5-ECR/               # Elastic Container Registry
    ├── 6-ECS/               # ECS Services e Tasks
    ├── UP.sh                # Script de deploy
    ├── DWN.sh               # Script de destroy
    └── README.md            # Documentação específica
```

## Arquitetura AWS

### Componentes Principais

#### Rede (VPC)
- **VPC**: Rede privada virtual isolada
- **Subnets**: Públicas e privadas em múltiplas AZs
- **Internet Gateway**: Acesso à internet
- **Route Tables**: Roteamento de tráfego

#### Segurança
- **Security Groups**: Firewall a nível de instância
- **IAM Roles**: Permissões granulares
- **Secrets Manager**: Gerenciamento de credenciais (futuro)

#### Compute
- **ECS Cluster**: Orquestração de containers
- **EC2 Instances**: t3.micro para cluster ECS
- **Application Load Balancer**: Distribuição de carga (evolução)

#### Storage & Database
- **RDS PostgreSQL**: t3.micro para banco de dados
- **S3 Buckets**: Armazenamento de objetos
- **ECR**: Registry para imagens Docker

## Evolução da Arquitetura

### Fase 1: Básica (Sem ALB)
```
Internet → EC2 (ECS) → RDS
```

**Security Groups:**
- `bia-web`: EC2 com acesso público (porta 8080)
- `bia-db`: RDS com acesso do bia-web

### Fase 2: Avançada (Com ALB)
```
Internet → ALB → EC2 (ECS) → RDS
```

**Security Groups:**
- `bia-alb`: Load Balancer com acesso público
- `bia-ec2`: EC2 com acesso do ALB
- `bia-db`: RDS com acesso do bia-ec2

## Nomenclatura Padronizada

### Prefixo Global
- **Padrão**: `bia-*` para todos os recursos

### Security Groups
- **Database**: `bia-db`
- **Web (sem ALB)**: `bia-web`
- **EC2 (com ALB)**: `bia-ec2`
- **Load Balancer**: `bia-alb`

### ECS Resources
- **Cluster**: `bia-cluster-alb`
- **Task Definition**: `bia-tf`
- **Service**: `bia-service`

## Scripts de Automação

### Deploy Completo (UP.sh)
```bash
# Executar deploy de toda infraestrutura
./UP.sh
```

**Ordem de execução:**
1. Terraform State (S3 + DynamoDB)
2. VPC e Networking
3. Security Groups
4. IAM Roles
5. RDS Database
6. ECS Cluster
7. ECR Repository
8. ECS Services

### Destroy Completo (DWN.sh)
```bash
# Destruir toda infraestrutura
./DWN.sh
```

**Ordem reversa de destruição** para evitar dependências.

## Configuração de Cada Módulo

### 0-TerraformState
- **S3 Bucket**: Backend remoto do Terraform
- **DynamoDB**: Lock de estado
- **Versionamento**: Controle de versões do estado

### 1-VPC
- **CIDR**: 10.0.0.0/16
- **Subnets Públicas**: 10.0.1.0/24, 10.0.2.0/24
- **Subnets Privadas**: 10.0.3.0/24, 10.0.4.0/24
- **Multi-AZ**: us-east-1a, us-east-1b

### 1a-SegGroup
- **Inbound Rules**: Seguem padrão de descrição
- **Referências**: Security Groups referenciam outros SGs
- **Princípio**: Menor privilégio

### 3-RDS
- **Engine**: PostgreSQL 16.1
- **Instance**: t3.micro
- **Storage**: 20GB gp2
- **Backup**: 7 dias de retenção

### 6-ECS
- **Cluster Type**: EC2 (não Fargate)
- **Task CPU**: 256
- **Task Memory**: 512MB
- **Service**: Rolling update

## Variáveis de Ambiente

### Terraform Variables
```hcl
# terraform.tfvars
region = "us-east-1"
project_name = "bia"
environment = "dev"
db_instance_class = "db.t3.micro"
ec2_instance_type = "t3.micro"
```

### AWS Credentials
```bash
# ~/.aws/credentials
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
region = us-east-1
```

## Custos Estimados (Mensais)

### Recursos Principais
- **EC2 t3.micro**: ~$8.50
- **RDS t3.micro**: ~$12.00
- **ALB**: ~$16.00
- **S3 + ECR**: ~$1.00
- **Data Transfer**: ~$2.00

**Total Estimado**: ~$40/mês

> Use a [AWS Pricing Calculator](https://calculator.aws) para estimativas precisas.

## Pré-requisitos

### Ferramentas Necessárias
- **Terraform**: v1.0+
- **AWS CLI**: v2.0+
- **Docker**: Para build de imagens
- **Git**: Para versionamento

### Configuração Inicial
```bash
# Instalar Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Configurar AWS CLI
aws configure
```

## Deploy Step-by-Step

### 1. Preparação
```bash
cd IaaC/Terraform
chmod +x UP.sh DWN.sh
```

### 2. Validação
```bash
# Verificar configuração AWS
aws sts get-caller-identity

# Validar sintaxe Terraform
terraform fmt -recursive
terraform validate
```

### 3. Deploy
```bash
# Deploy completo
./UP.sh

# Ou deploy individual
cd 1-VPC && terraform apply
```

### 4. Verificação
```bash
# Verificar recursos criados
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=bia-vpc"
aws rds describe-db-instances --db-instance-identifier bia-db
```

## Troubleshooting

### Problemas Comuns

#### Erro de Permissões IAM
```bash
# Verificar permissões
aws iam get-user
aws sts get-caller-identity
```

#### Estado do Terraform Corrompido
```bash
# Importar recurso existente
terraform import aws_vpc.main vpc-xxxxxxxxx
```

#### Dependências Circulares
- Verificar ordem de criação nos scripts
- Usar `terraform graph` para visualizar dependências

## Monitoramento

### CloudWatch Metrics
- CPU e Memory utilization
- Database connections
- Load Balancer metrics

### Logs
- ECS Task logs
- Application logs
- VPC Flow logs (opcional)

## Próximos Passos

### Melhorias Planejadas
- **Auto Scaling**: Configuração automática
- **CloudFormation**: Templates alternativos
- **CDK**: Infrastructure as Code com Python/TypeScript
- **Monitoring**: CloudWatch Dashboards
- **Backup**: Estratégias automatizadas

### Recursos Avançados (Futuro)
- **Secrets Manager**: Rotação automática de credenciais
- **WAF**: Web Application Firewall
- **CloudFront**: CDN para assets estáticos
- **Route53**: DNS gerenciado

---

**Projeto BIA v4.2.0**  
*Imersão AWS & IA - 28/07 a 03/08/2025*

> **Nota Educacional**: Esta infraestrutura foi projetada para fins de aprendizado. Para ambientes de produção, considere implementar recursos adicionais de segurança, monitoramento e alta disponibilidade.
