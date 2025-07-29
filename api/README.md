# API - Backend do Projeto BIA

## Visão Geral
Este diretório contém toda a lógica do backend da aplicação BIA, construída com Node.js e Express.js. A API segue uma arquitetura MVC (Model-View-Controller) para organização e manutenibilidade do código.

## Estrutura do Diretório

```
api/
├── controllers/    # Controladores da aplicação
├── models/        # Modelos do Sequelize (ORM)
├── routes/        # Definição das rotas da API
└── data/          # Dados auxiliares e configurações
```

## Tecnologias Utilizadas

- **Node.js**: Runtime JavaScript
- **Express.js 4.17.1**: Framework web
- **Sequelize 6.6.5**: ORM para PostgreSQL
- **PostgreSQL**: Banco de dados principal
- **AWS SDK**: Integração com serviços AWS
  - Secrets Manager para credenciais
  - STS para tokens temporários

## Funcionalidades Principais

### Controladores (`/controllers`)
- Lógica de negócio da aplicação
- Processamento de requisições HTTP
- Validação de dados de entrada
- Integração com modelos do banco de dados

### Modelos (`/models`)
- Definição das entidades do banco de dados
- Relacionamentos entre tabelas
- Validações de dados
- Configuração do Sequelize ORM

### Rotas (`/routes`)
- Definição dos endpoints da API
- Middleware de autenticação
- Configuração de CORS
- Roteamento das requisições

### Dados (`/data`)
- Dados de configuração
- Seeds para popular o banco
- Arquivos auxiliares

## Endpoints Principais

### Health Check
```
GET /api/versao
```
Retorna informações sobre a versão da aplicação e status do sistema.

### Configuração de Middleware

- **CORS**: Habilitado para requisições cross-origin
- **Morgan**: Logging de requisições HTTP
- **Express Session**: Gerenciamento de sessões
- **JSON Parser**: Processamento de requisições JSON

## Integração AWS

### Secrets Manager
- Gerenciamento seguro de credenciais do banco
- Rotação automática de senhas
- Configuração por variáveis de ambiente

### STS (Security Token Service)
- Tokens temporários para acesso aos recursos
- Assumir roles específicas
- Segurança aprimorada

## Configuração de Desenvolvimento

### Variáveis de Ambiente Necessárias
```bash
DB_HOST=localhost
DB_PORT=5432
DB_NAME=bia_db
DB_USER=postgres
DB_PASS=senha
AWS_REGION=us-east-1
```

### Executar Localmente
```bash
# Instalar dependências
npm install

# Executar migrations
npx sequelize db:migrate

# Iniciar servidor
npm start
```

## Estrutura de Resposta da API

### Sucesso
```json
{
  "success": true,
  "data": {},
  "message": "Operação realizada com sucesso"
}
```

### Erro
```json
{
  "success": false,
  "error": "Mensagem de erro",
  "code": "ERROR_CODE"
}
```

## Boas Práticas Implementadas

- **Separação de responsabilidades**: MVC pattern
- **Validação de entrada**: Sanitização de dados
- **Tratamento de erros**: Middleware centralizado
- **Logging**: Rastreamento de requisições
- **Segurança**: Integração com AWS para credenciais

## Próximos Passos

- Implementação de autenticação JWT
- Rate limiting para proteção contra spam
- Documentação automática com Swagger
- Testes unitários e de integração
- Monitoramento com CloudWatch

---

**Projeto BIA v4.2.0**  
*Imersão AWS & IA - 28/07 a 03/08/2025*
