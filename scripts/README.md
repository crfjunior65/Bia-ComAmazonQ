# Scripts - Automação e Utilitários

## Visão Geral
Este diretório contém scripts de automação, utilitários e ferramentas auxiliares para o desenvolvimento, deploy e manutenção do projeto BIA. Os scripts facilitam tarefas repetitivas e padronizam processos.

## Estrutura do Diretório

```
scripts/
├── deploy/         # Scripts de deploy
├── database/       # Scripts de banco de dados
├── aws/           # Scripts específicos da AWS
├── development/   # Scripts para desenvolvimento
├── monitoring/    # Scripts de monitoramento
└── README.md      # Esta documentação
```

## Scripts de Deploy

### deploy.sh
```bash
#!/bin/bash
# Script principal de deploy

set -e

echo "🚀 Iniciando deploy do projeto BIA..."

# Variáveis
ENVIRONMENT=${1:-development}
VERSION=$(git rev-parse --short HEAD)
ECR_REPOSITORY="bia-app"
AWS_REGION="us-east-1"

echo "📋 Configurações:"
echo "  Environment: $ENVIRONMENT"
echo "  Version: $VERSION"
echo "  ECR Repository: $ECR_REPOSITORY"

# Build da aplicação
echo "🔨 Building application..."
npm run build

# Build da imagem Docker
echo "🐳 Building Docker image..."
docker build -t $ECR_REPOSITORY:$VERSION .
docker tag $ECR_REPOSITORY:$VERSION $ECR_REPOSITORY:latest

# Login no ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com

# Push da imagem
echo "📤 Pushing image to ECR..."
ECR_URI=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY
docker tag $ECR_REPOSITORY:$VERSION $ECR_URI:$VERSION
docker tag $ECR_REPOSITORY:latest $ECR_URI:latest
docker push $ECR_URI:$VERSION
docker push $ECR_URI:latest

# Deploy no ECS
echo "🚢 Deploying to ECS..."
aws ecs update-service \
  --cluster bia-cluster-alb \
  --service bia-service \
  --force-new-deployment

echo "✅ Deploy completed successfully!"
```

### rollback.sh
```bash
#!/bin/bash
# Script de rollback

set -e

PREVIOUS_VERSION=${1}

if [ -z "$PREVIOUS_VERSION" ]; then
  echo "❌ Erro: Versão anterior não especificada"
  echo "Uso: ./rollback.sh <version>"
  exit 1
fi

echo "🔄 Iniciando rollback para versão: $PREVIOUS_VERSION"

# Rollback no ECS
aws ecs update-service \
  --cluster bia-cluster-alb \
  --service bia-service \
  --task-definition bia-tf:$PREVIOUS_VERSION \
  --force-new-deployment

echo "✅ Rollback completed!"
```

## Scripts de Banco de Dados

### db-migrate.sh
```bash
#!/bin/bash
# Script para executar migrations

set -e

ENVIRONMENT=${1:-development}

echo "🗄️  Executando migrations para ambiente: $ENVIRONMENT"

if [ "$ENVIRONMENT" = "production" ]; then
  echo "⚠️  ATENÇÃO: Executando em PRODUÇÃO!"
  read -p "Tem certeza? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operação cancelada"
    exit 1
  fi
fi

# Executar migrations
NODE_ENV=$ENVIRONMENT npx sequelize db:migrate

echo "✅ Migrations executadas com sucesso!"
```

### db-backup.sh
```bash
#!/bin/bash
# Script de backup do banco de dados

set -e

ENVIRONMENT=${1:-development}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups"

echo "💾 Criando backup do banco - Ambiente: $ENVIRONMENT"

# Criar diretório de backup
mkdir -p $BACKUP_DIR

# Configurar variáveis baseado no ambiente
if [ "$ENVIRONMENT" = "production" ]; then
  DB_HOST=$(aws rds describe-db-instances --db-instance-identifier bia-db --query 'DBInstances[0].Endpoint.Address' --output text)
  DB_NAME="bia_prod"
else
  DB_HOST="localhost"
  DB_NAME="bia_dev"
fi

# Executar backup
BACKUP_FILE="$BACKUP_DIR/bia_${ENVIRONMENT}_${TIMESTAMP}.sql"

pg_dump -h $DB_HOST -U postgres -d $DB_NAME > $BACKUP_FILE

# Comprimir backup
gzip $BACKUP_FILE

echo "✅ Backup criado: ${BACKUP_FILE}.gz"

# Upload para S3 (se produção)
if [ "$ENVIRONMENT" = "production" ]; then
  aws s3 cp ${BACKUP_FILE}.gz s3://bia-backups/database/
  echo "📤 Backup enviado para S3"
fi
```

### db-restore.sh
```bash
#!/bin/bash
# Script de restore do banco de dados

set -e

BACKUP_FILE=${1}
ENVIRONMENT=${2:-development}

if [ -z "$BACKUP_FILE" ]; then
  echo "❌ Erro: Arquivo de backup não especificado"
  echo "Uso: ./db-restore.sh <backup-file> [environment]"
  exit 1
fi

echo "🔄 Restaurando backup: $BACKUP_FILE"
echo "🎯 Ambiente: $ENVIRONMENT"

# Descomprimir se necessário
if [[ $BACKUP_FILE == *.gz ]]; then
  gunzip -c $BACKUP_FILE > temp_restore.sql
  BACKUP_FILE="temp_restore.sql"
fi

# Configurar variáveis
if [ "$ENVIRONMENT" = "production" ]; then
  DB_HOST=$(aws rds describe-db-instances --db-instance-identifier bia-db --query 'DBInstances[0].Endpoint.Address' --output text)
  DB_NAME="bia_prod"
else
  DB_HOST="localhost"
  DB_NAME="bia_dev"
fi

# Executar restore
psql -h $DB_HOST -U postgres -d $DB_NAME < $BACKUP_FILE

# Limpar arquivo temporário
if [ -f "temp_restore.sql" ]; then
  rm temp_restore.sql
fi

echo "✅ Restore concluído com sucesso!"
```

## Scripts AWS

### aws-setup.sh
```bash
#!/bin/bash
# Script de configuração inicial da AWS

set -e

echo "⚙️  Configurando ambiente AWS..."

# Verificar se AWS CLI está instalado
if ! command -v aws &> /dev/null; then
  echo "❌ AWS CLI não encontrado. Instalando..."
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  rm -rf aws awscliv2.zip
fi

# Verificar credenciais
if ! aws sts get-caller-identity &> /dev/null; then
  echo "🔐 Configurando credenciais AWS..."
  aws configure
fi

# Verificar região
CURRENT_REGION=$(aws configure get region)
if [ "$CURRENT_REGION" != "us-east-1" ]; then
  echo "🌎 Configurando região para us-east-1..."
  aws configure set region us-east-1
fi

echo "✅ AWS configurado com sucesso!"
aws sts get-caller-identity
```

### ecr-login.sh
```bash
#!/bin/bash
# Script para login no ECR

set -e

AWS_REGION=${1:-us-east-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "🔐 Fazendo login no ECR..."
echo "📍 Região: $AWS_REGION"
echo "🏢 Account ID: $ACCOUNT_ID"

aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo "✅ Login no ECR realizado com sucesso!"
```

### sts-token.sh
```bash
#!/bin/bash
# Script para gerar tokens STS temporários

set -e

ROLE_ARN=${1}
SESSION_NAME=${2:-bia-session}
DURATION=${3:-3600}

if [ -z "$ROLE_ARN" ]; then
  echo "❌ Erro: Role ARN não especificado"
  echo "Uso: ./sts-token.sh <role-arn> [session-name] [duration]"
  exit 1
fi

echo "🎫 Gerando token STS temporário..."
echo "🎭 Role: $ROLE_ARN"
echo "📝 Session: $SESSION_NAME"
echo "⏱️  Duration: ${DURATION}s"

# Assumir role
CREDENTIALS=$(aws sts assume-role \
  --role-arn $ROLE_ARN \
  --role-session-name $SESSION_NAME \
  --duration-seconds $DURATION \
  --output json)

# Extrair credenciais
ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.Credentials.AccessKeyId')
SECRET_KEY=$(echo $CREDENTIALS | jq -r '.Credentials.SecretAccessKey')
SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Credentials.SessionToken')

# Exportar variáveis
export AWS_ACCESS_KEY_ID=$ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$SECRET_KEY
export AWS_SESSION_TOKEN=$SESSION_TOKEN

echo "✅ Token gerado com sucesso!"
echo "🔑 Access Key: ${ACCESS_KEY:0:10}..."
echo "⏰ Expira em: $(echo $CREDENTIALS | jq -r '.Credentials.Expiration')"

# Salvar em arquivo para sourcing
cat > .aws-temp-credentials << EOF
export AWS_ACCESS_KEY_ID=$ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$SECRET_KEY
export AWS_SESSION_TOKEN=$SESSION_TOKEN
EOF

echo "💾 Credenciais salvas em .aws-temp-credentials"
echo "📋 Para usar: source .aws-temp-credentials"
```

## Scripts de Desenvolvimento

### dev-setup.sh
```bash
#!/bin/bash
# Script de configuração do ambiente de desenvolvimento

set -e

echo "🛠️  Configurando ambiente de desenvolvimento..."

# Verificar Node.js
if ! command -v node &> /dev/null; then
  echo "❌ Node.js não encontrado. Instale Node.js 18+"
  exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ $NODE_VERSION -lt 18 ]; then
  echo "❌ Node.js versão 18+ necessária. Versão atual: $(node -v)"
  exit 1
fi

# Verificar Docker
if ! command -v docker &> /dev/null; then
  echo "❌ Docker não encontrado. Instalando..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  rm get-docker.sh
fi

# Instalar dependências
echo "📦 Instalando dependências..."
npm install

# Configurar banco de desenvolvimento
echo "🗄️  Configurando banco de desenvolvimento..."
docker compose up -d db

# Aguardar banco ficar disponível
echo "⏳ Aguardando banco de dados..."
sleep 10

# Executar migrations
echo "🔄 Executando migrations..."
npm run db:migrate

# Executar seeds
echo "🌱 Executando seeds..."
npm run db:seed

echo "✅ Ambiente de desenvolvimento configurado!"
echo "🚀 Para iniciar: npm run dev"
```

### test-setup.sh
```bash
#!/bin/bash
# Script de configuração para testes

set -e

echo "🧪 Configurando ambiente de testes..."

# Configurar banco de teste
export NODE_ENV=test
export DB_NAME=bia_test

# Criar banco de teste
docker compose exec db createdb -U postgres bia_test || true

# Executar migrations de teste
npx sequelize db:migrate

echo "✅ Ambiente de testes configurado!"
echo "🧪 Para executar testes: npm test"
```

## Scripts de Monitoramento

### health-check.sh
```bash
#!/bin/bash
# Script de health check

set -e

API_URL=${1:-http://localhost:8080}
TIMEOUT=${2:-10}

echo "🏥 Verificando saúde da aplicação..."
echo "🌐 URL: $API_URL"

# Health check da API
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/health_response --max-time $TIMEOUT $API_URL/api/versao)

if [ "$RESPONSE" = "200" ]; then
  echo "✅ API está saudável!"
  cat /tmp/health_response | jq .
else
  echo "❌ API não está respondendo (HTTP $RESPONSE)"
  exit 1
fi

# Verificar banco de dados
echo "🗄️  Verificando banco de dados..."
if psql -h localhost -U postgres -d bia_dev -c "SELECT 1;" &> /dev/null; then
  echo "✅ Banco de dados está acessível!"
else
  echo "❌ Banco de dados não está acessível!"
  exit 1
fi

rm -f /tmp/health_response
echo "🎉 Todos os serviços estão saudáveis!"
```

### logs.sh
```bash
#!/bin/bash
# Script para visualizar logs

set -e

SERVICE=${1:-all}
LINES=${2:-100}

echo "📋 Visualizando logs - Serviço: $SERVICE"

case $SERVICE in
  "api"|"app")
    docker compose logs -f --tail=$LINES server
    ;;
  "db"|"database")
    docker compose logs -f --tail=$LINES db
    ;;
  "all")
    docker compose logs -f --tail=$LINES
    ;;
  "ecs")
    aws logs tail /ecs/bia-service --follow
    ;;
  *)
    echo "❌ Serviço não reconhecido: $SERVICE"
    echo "Serviços disponíveis: api, db, all, ecs"
    exit 1
    ;;
esac
```

## Scripts de Utilitários

### cleanup.sh
```bash
#!/bin/bash
# Script de limpeza

set -e

echo "🧹 Limpando ambiente..."

# Parar containers
echo "🛑 Parando containers..."
docker compose down

# Remover imagens não utilizadas
echo "🗑️  Removendo imagens não utilizadas..."
docker image prune -f

# Limpar node_modules
echo "📦 Limpando node_modules..."
rm -rf node_modules
rm -rf client/node_modules

# Limpar logs
echo "📋 Limpando logs..."
rm -rf logs/*.log

# Limpar cache
echo "💾 Limpando cache..."
npm cache clean --force

echo "✅ Limpeza concluída!"
```

### version.sh
```bash
#!/bin/bash
# Script para gerenciar versões

set -e

ACTION=${1:-show}
VERSION_TYPE=${2:-patch}

case $ACTION in
  "show")
    echo "📋 Informações de versão:"
    echo "  Package.json: $(jq -r .version package.json)"
    echo "  Git commit: $(git rev-parse --short HEAD)"
    echo "  Git tag: $(git describe --tags --abbrev=0 2>/dev/null || echo 'Nenhuma tag')"
    ;;
  "bump")
    echo "⬆️  Incrementando versão ($VERSION_TYPE)..."
    npm version $VERSION_TYPE
    echo "✅ Nova versão: $(jq -r .version package.json)"
    ;;
  "tag")
    VERSION=$(jq -r .version package.json)
    echo "🏷️  Criando tag v$VERSION..."
    git tag -a "v$VERSION" -m "Release v$VERSION"
    echo "✅ Tag criada: v$VERSION"
    ;;
  *)
    echo "❌ Ação não reconhecida: $ACTION"
    echo "Ações disponíveis: show, bump, tag"
    exit 1
    ;;
esac
```

## Configuração de Permissões

### Tornar Scripts Executáveis
```bash
# Tornar todos os scripts executáveis
find scripts/ -name "*.sh" -exec chmod +x {} \;

# Ou individualmente
chmod +x scripts/deploy/deploy.sh
chmod +x scripts/database/db-migrate.sh
# ... etc
```

## Uso dos Scripts

### Exemplos Práticos
```bash
# Deploy para produção
./scripts/deploy/deploy.sh production

# Backup do banco
./scripts/database/db-backup.sh production

# Configurar ambiente de desenvolvimento
./scripts/development/dev-setup.sh

# Health check
./scripts/monitoring/health-check.sh https://api.bia.com

# Visualizar logs do ECS
./scripts/monitoring/logs.sh ecs
```

## Boas Práticas

### Estrutura dos Scripts
- **Shebang**: Sempre usar `#!/bin/bash`
- **Set -e**: Parar em caso de erro
- **Validação**: Validar parâmetros de entrada
- **Logging**: Mensagens claras e informativas
- **Cleanup**: Limpar recursos temporários

### Segurança
- **Credenciais**: Nunca hardcode credenciais
- **Validação**: Validar entrada do usuário
- **Permissões**: Usar permissões mínimas necessárias
- **Logs**: Não logar informações sensíveis

### Manutenibilidade
- **Documentação**: Comentários explicativos
- **Modularidade**: Scripts pequenos e focados
- **Reutilização**: Funções comuns em bibliotecas
- **Versionamento**: Controlar versões dos scripts

## Próximos Passos

### Melhorias Planejadas
- **Makefile**: Simplificar execução de scripts
- **Docker Scripts**: Scripts containerizados
- **CI/CD Integration**: Integração com pipelines
- **Monitoring Scripts**: Scripts de monitoramento avançado

### Automação Adicional
- **Slack Notifications**: Notificações de deploy
- **Rollback Automático**: Rollback em caso de falha
- **Performance Testing**: Scripts de teste de carga
- **Security Scanning**: Scripts de análise de segurança

---

**Projeto BIA v4.2.0**  
*Imersão AWS & IA - 28/07 a 03/08/2025*

> **Dica**: Sempre teste scripts em ambiente de desenvolvimento antes de usar em produção!
