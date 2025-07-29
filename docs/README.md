# Docs - Documentação do Projeto

## Visão Geral
Este diretório contém toda a documentação técnica e educacional do projeto BIA, incluindo guias de instalação, arquitetura, APIs, tutoriais e materiais de apoio para o bootcamp.

## Estrutura do Diretório

```
docs/
├── architecture/       # Documentação de arquitetura
├── api/               # Documentação da API
├── deployment/        # Guias de deploy
├── development/       # Guias de desenvolvimento
├── tutorials/         # Tutoriais passo-a-passo
├── troubleshooting/   # Guias de resolução de problemas
├── aws/              # Documentação específica da AWS
├── images/           # Imagens e diagramas
└── README.md         # Esta documentação
```

## Documentação de Arquitetura

### Visão Geral da Arquitetura
```markdown
# architecture/overview.md

## Arquitetura do Sistema BIA

### Componentes Principais

#### Frontend (React)
- **Tecnologia**: React 18 + Vite
- **Porta**: 5173 (desenvolvimento) / 80 (produção)
- **Responsabilidades**: Interface do usuário, experiência interativa

#### Backend (Node.js)
- **Tecnologia**: Express.js + Sequelize
- **Porta**: 8080
- **Responsabilidades**: API REST, lógica de negócio, integração com banco

#### Banco de Dados (PostgreSQL)
- **Versão**: 16.1
- **Porta**: 5432
- **Responsabilidades**: Persistência de dados, integridade referencial

#### Infraestrutura (AWS)
- **ECS**: Orquestração de containers
- **RDS**: Banco de dados gerenciado
- **ECR**: Registry de imagens Docker
- **ALB**: Load balancer (evolução)

### Fluxo de Dados
```
Cliente → ALB → ECS (Container) → RDS
                ↓
              ECR (Imagens)
```
```

### Diagramas de Arquitetura
```markdown
# architecture/diagrams.md

## Diagramas do Sistema

### Arquitetura Atual (Fase 1)
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Cliente   │───▶│  EC2/ECS    │───▶│     RDS     │
│  (Browser)  │    │  (Node.js)  │    │(PostgreSQL) │
└─────────────┘    └─────────────┘    └─────────────┘
```

### Arquitetura Futura (Fase 2)
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Cliente   │───▶│     ALB     │───▶│  EC2/ECS    │───▶│     RDS     │
│  (Browser)  │    │(Load Balancer)│   │  (Node.js)  │    │(PostgreSQL) │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### Componentes de Segurança
```
Security Groups:
├── bia-alb (80/443 from 0.0.0.0/0)
├── bia-ec2 (All TCP from bia-alb)
└── bia-db (5432 from bia-ec2)
```
```

## Documentação da API

### Especificação da API
```markdown
# api/specification.md

## API REST - Projeto BIA

### Base URL
- **Desenvolvimento**: http://localhost:8080/api
- **Produção**: https://api.bia.com/api

### Autenticação
Atualmente não implementada. Planejado para versões futuras.

### Endpoints

#### Health Check
```http
GET /api/versao
```

**Resposta:**
```json
{
  "name": "BIA",
  "version": "4.2.0",
  "environment": "development",
  "timestamp": "2025-07-29T15:00:00.000Z"
}
```

#### Usuários
```http
GET /api/users
POST /api/users
GET /api/users/:id
PUT /api/users/:id
DELETE /api/users/:id
```

### Códigos de Status
- **200**: Sucesso
- **201**: Criado com sucesso
- **400**: Erro de validação
- **404**: Recurso não encontrado
- **500**: Erro interno do servidor

### Formato de Resposta
```json
{
  "success": true,
  "data": {},
  "message": "Operação realizada com sucesso"
}
```
```

### Coleção Postman
```json
{
  "info": {
    "name": "BIA API",
    "description": "Coleção de endpoints da API BIA"
  },
  "item": [
    {
      "name": "Health Check",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{base_url}}/api/versao",
          "host": ["{{base_url}}"],
          "path": ["api", "versao"]
        }
      }
    }
  ],
  "variable": [
    {
      "key": "base_url",
      "value": "http://localhost:8080"
    }
  ]
}
```

## Guias de Desenvolvimento

### Configuração do Ambiente
```markdown
# development/setup.md

## Configuração do Ambiente de Desenvolvimento

### Pré-requisitos
- Node.js 18+
- Docker & Docker Compose
- Git
- AWS CLI (opcional)

### Instalação

#### 1. Clonar o Repositório
```bash
git clone https://github.com/henrylle/bia.git
cd bia
```

#### 2. Instalar Dependências
```bash
# Backend
npm install

# Frontend
cd client
npm install
cd ..
```

#### 3. Configurar Variáveis de Ambiente
```bash
# Copiar arquivo de exemplo
cp .env.example .env

# Editar variáveis
nano .env
```

#### 4. Iniciar Banco de Dados
```bash
docker compose up -d db
```

#### 5. Executar Migrations
```bash
npm run db:migrate
```

#### 6. Iniciar Aplicação
```bash
# Terminal 1 - Backend
npm run dev

# Terminal 2 - Frontend
cd client
npm run dev
```

### URLs de Desenvolvimento
- **Frontend**: http://localhost:5173
- **Backend**: http://localhost:8080
- **Banco**: localhost:5432
```

### Padrões de Código
```markdown
# development/coding-standards.md

## Padrões de Código

### JavaScript/Node.js

#### Formatação
- **Indentação**: 2 espaços
- **Aspas**: Simples para strings
- **Semicolons**: Obrigatórios
- **Line Length**: Máximo 100 caracteres

#### Nomenclatura
- **Variáveis**: camelCase
- **Constantes**: UPPER_SNAKE_CASE
- **Funções**: camelCase
- **Classes**: PascalCase
- **Arquivos**: kebab-case

#### Estrutura de Arquivos
```
api/
├── controllers/
│   └── user-controller.js
├── models/
│   └── user.js
├── routes/
│   └── user-routes.js
└── services/
    └── user-service.js
```

### React

#### Componentes
```jsx
// Componente funcional
const UserCard = ({ user, onEdit, onDelete }) => {
  return (
    <div className="user-card">
      <h3>{user.name}</h3>
      <p>{user.email}</p>
      <button onClick={() => onEdit(user.id)}>Editar</button>
      <button onClick={() => onDelete(user.id)}>Excluir</button>
    </div>
  );
};

export default UserCard;
```

#### Hooks
```jsx
// Custom hook
const useUsers = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const response = await api.get('/users');
      setUsers(response.data);
    } catch (error) {
      console.error('Erro ao buscar usuários:', error);
    } finally {
      setLoading(false);
    }
  };

  return { users, loading, fetchUsers };
};
```
```

## Guias de Deploy

### Deploy Local
```markdown
# deployment/local.md

## Deploy Local com Docker

### Build da Aplicação
```bash
# Build da imagem
docker build -t bia-app .

# Executar container
docker run -p 8080:8080 bia-app
```

### Docker Compose
```bash
# Iniciar todos os serviços
docker compose up -d

# Verificar status
docker compose ps

# Ver logs
docker compose logs -f

# Parar serviços
docker compose down
```

### Verificação
```bash
# Health check
curl http://localhost:8080/api/versao

# Teste da aplicação
curl http://localhost:8080
```
```

### Deploy AWS
```markdown
# deployment/aws.md

## Deploy na AWS

### Pré-requisitos
- AWS CLI configurado
- Terraform instalado
- Docker instalado

### 1. Provisionar Infraestrutura
```bash
cd IaaC/Terraform
./UP.sh
```

### 2. Build e Push da Imagem
```bash
# Login no ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com

# Build e push
docker build -t bia-app .
docker tag bia-app:latest $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/bia-app:latest
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/bia-app:latest
```

### 3. Deploy no ECS
```bash
# Atualizar serviço
aws ecs update-service \
  --cluster bia-cluster-alb \
  --service bia-service \
  --force-new-deployment
```

### 4. Verificação
```bash
# Verificar status do serviço
aws ecs describe-services \
  --cluster bia-cluster-alb \
  --services bia-service

# Verificar tasks
aws ecs list-tasks \
  --cluster bia-cluster-alb \
  --service-name bia-service
```
```

## Tutoriais

### Tutorial Completo
```markdown
# tutorials/complete-walkthrough.md

## Tutorial Completo - Do Zero ao Deploy

### Objetivo
Aprender a desenvolver e fazer deploy de uma aplicação completa na AWS.

### Módulo 1: Configuração Inicial
1. **Configurar ambiente de desenvolvimento**
2. **Entender a arquitetura do projeto**
3. **Executar aplicação localmente**

### Módulo 2: Desenvolvimento
1. **Criar novos endpoints na API**
2. **Desenvolver componentes React**
3. **Implementar testes**

### Módulo 3: Containerização
1. **Entender Docker e containers**
2. **Criar Dockerfile otimizado**
3. **Usar Docker Compose**

### Módulo 4: Infraestrutura
1. **Introdução ao Terraform**
2. **Provisionar recursos AWS**
3. **Configurar networking e segurança**

### Módulo 5: Deploy
1. **Configurar ECR**
2. **Deploy no ECS**
3. **Configurar monitoramento**

### Módulo 6: CI/CD
1. **Configurar pipeline**
2. **Automatizar deploy**
3. **Implementar rollback**
```

### Tutorial AWS Específico
```markdown
# tutorials/aws-services.md

## Tutorial: Serviços AWS Utilizados

### ECS (Elastic Container Service)
**O que é**: Serviço de orquestração de containers

**Como usar no projeto**:
1. Criar cluster ECS
2. Definir task definition
3. Configurar service
4. Fazer deploy da aplicação

### RDS (Relational Database Service)
**O que é**: Banco de dados gerenciado

**Como usar no projeto**:
1. Criar instância PostgreSQL
2. Configurar security groups
3. Conectar aplicação ao banco
4. Configurar backups

### ECR (Elastic Container Registry)
**O que é**: Registry para imagens Docker

**Como usar no projeto**:
1. Criar repositório
2. Fazer push das imagens
3. Configurar políticas de acesso
4. Integrar com ECS
```

## Troubleshooting

### Problemas Comuns
```markdown
# troubleshooting/common-issues.md

## Problemas Comuns e Soluções

### Erro de Conexão com Banco
**Sintoma**: `ECONNREFUSED` ou timeout de conexão

**Possíveis Causas**:
1. Banco não está rodando
2. Credenciais incorretas
3. Security group bloqueando conexão
4. Variáveis de ambiente não configuradas

**Soluções**:
```bash
# Verificar se banco está rodando
docker compose ps

# Testar conexão
psql -h localhost -U postgres -d bia_dev

# Verificar variáveis
echo $DB_HOST $DB_USER $DB_NAME

# Verificar security groups (AWS)
aws ec2 describe-security-groups --group-names bia-db
```

### Erro de Build Docker
**Sintoma**: Build falha com erro de dependências

**Soluções**:
```bash
# Limpar cache do Docker
docker system prune -a

# Rebuild sem cache
docker build --no-cache -t bia-app .

# Verificar Dockerfile
docker run --rm -it node:18-slim bash
```

### Erro de Deploy ECS
**Sintoma**: Tasks param mas não ficam running

**Soluções**:
```bash
# Verificar logs da task
aws logs tail /ecs/bia-service --follow

# Verificar definição da task
aws ecs describe-task-definition --task-definition bia-tf

# Verificar recursos do cluster
aws ecs describe-clusters --clusters bia-cluster-alb
```
```

## Materiais de Apoio

### Glossário
```markdown
# glossary.md

## Glossário de Termos

### AWS
- **ECS**: Elastic Container Service - Orquestração de containers
- **RDS**: Relational Database Service - Banco de dados gerenciado
- **ECR**: Elastic Container Registry - Registry de imagens Docker
- **ALB**: Application Load Balancer - Balanceador de carga
- **VPC**: Virtual Private Cloud - Rede privada virtual

### Docker
- **Container**: Ambiente isolado para executar aplicações
- **Image**: Template para criar containers
- **Dockerfile**: Arquivo de instruções para build de imagem
- **Compose**: Ferramenta para definir aplicações multi-container

### Desenvolvimento
- **API**: Application Programming Interface
- **REST**: Representational State Transfer
- **ORM**: Object-Relational Mapping
- **MVC**: Model-View-Controller
- **SPA**: Single Page Application
```

### Links Úteis
```markdown
# useful-links.md

## Links Úteis

### Documentação Oficial
- [Node.js](https://nodejs.org/docs/)
- [React](https://react.dev/)
- [Express.js](https://expressjs.com/)
- [Sequelize](https://sequelize.org/)
- [PostgreSQL](https://www.postgresql.org/docs/)

### AWS
- [AWS Documentation](https://docs.aws.amazon.com/)
- [ECS User Guide](https://docs.aws.amazon.com/ecs/)
- [RDS User Guide](https://docs.aws.amazon.com/rds/)
- [ECR User Guide](https://docs.aws.amazon.com/ecr/)

### Ferramentas
- [Docker Documentation](https://docs.docker.com/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [Jest Documentation](https://jestjs.io/docs/)
- [Postman](https://www.postman.com/)

### Tutoriais e Cursos
- [AWS Free Tier](https://aws.amazon.com/free/)
- [Docker Tutorial](https://www.docker.com/101-tutorial)
- [React Tutorial](https://react.dev/learn)
- [Node.js Tutorial](https://nodejs.dev/learn)
```

## Estrutura de Documentação

### Padrões de Escrita
- **Linguagem**: Português brasileiro
- **Tom**: Educacional e acessível
- **Formato**: Markdown
- **Estrutura**: Hierárquica com índices

### Organização
- **Por tópico**: Cada assunto em arquivo separado
- **Por nível**: Básico → Intermediário → Avançado
- **Por público**: Desenvolvedor, DevOps, Estudante

### Manutenção
- **Versionamento**: Acompanhar versões do projeto
- **Atualização**: Revisar a cada release
- **Feedback**: Incorporar sugestões dos usuários

## Próximos Passos

### Melhorias Planejadas
- **Documentação interativa**: GitBook ou similar
- **Vídeos tutoriais**: Complementar documentação escrita
- **Exemplos práticos**: Mais casos de uso
- **FAQ**: Perguntas frequentes

### Ferramentas Adicionais
- **Swagger/OpenAPI**: Documentação automática da API
- **Storybook**: Documentação de componentes
- **ADRs**: Architecture Decision Records
- **Runbooks**: Guias operacionais

---

**Projeto BIA v4.2.0**  
*Imersão AWS & IA - 28/07 a 03/08/2025*

> **Nota**: Esta documentação é um recurso vivo e deve ser atualizada conforme o projeto evolui!
