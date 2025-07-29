# Config - Configurações da Aplicação

## Visão Geral
Este diretório contém todas as configurações centralizadas da aplicação BIA, incluindo configurações de banco de dados, integração AWS, variáveis de ambiente e configurações específicas por ambiente.

## Estrutura do Diretório

```
config/
├── database.js     # Configurações do banco de dados
└── README.md       # Esta documentação
```

## Arquivos de Configuração

### database.js
Configurações do Sequelize ORM para diferentes ambientes (development, test, production).

## Configuração de Banco de Dados

### Estrutura Básica
```javascript
// config/database.js
const config = require('config');

module.exports = {
  development: {
    username: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASS || 'senha',
    database: process.env.DB_NAME || 'bia_dev',
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    dialect: 'postgres',
    logging: console.log,
    define: {
      timestamps: true,
      underscored: false,
      underscoredAll: false
    }
  },
  
  test: {
    username: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASS || 'senha',
    database: process.env.DB_NAME || 'bia_test',
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    dialect: 'postgres',
    logging: false
  },
  
  production: {
    username: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 5432,
    dialect: 'postgres',
    logging: false,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    dialectOptions: {
      ssl: {
        require: true,
        rejectUnauthorized: false
      }
    }
  }
};
```

## Variáveis de Ambiente

### Desenvolvimento Local
```bash
# .env (desenvolvimento)
NODE_ENV=development
PORT=8080

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=bia_dev
DB_USER=postgres
DB_PASS=senha123

# AWS (opcional para desenvolvimento)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
```

### Docker Compose
```yaml
# compose.yml
services:
  server:
    environment:
      - NODE_ENV=development
      - DB_HOST=db
      - DB_PORT=5432
      - DB_NAME=bia_db
      - DB_USER=postgres
      - DB_PASS=senha
      - AWS_REGION=us-east-1
```

### Produção (AWS)
```bash
# Variáveis de ambiente para ECS
NODE_ENV=production
PORT=8080

# Database (RDS)
DB_HOST=bia-db.cluster-xxxxx.us-east-1.rds.amazonaws.com
DB_PORT=5432
DB_NAME=bia_prod
DB_USER=postgres
DB_PASS=${SECRETS_MANAGER_PASSWORD}

# AWS
AWS_REGION=us-east-1
AWS_DEFAULT_REGION=us-east-1
```

## Integração com AWS

### Secrets Manager
```javascript
// config/aws-secrets.js
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

class SecretsManager {
  constructor() {
    this.client = new SecretsManagerClient({
      region: process.env.AWS_REGION || 'us-east-1'
    });
  }

  async getSecret(secretName) {
    try {
      const command = new GetSecretValueCommand({
        SecretId: secretName
      });
      
      const response = await this.client.send(command);
      return JSON.parse(response.SecretString);
    } catch (error) {
      console.error('Erro ao buscar secret:', error);
      throw error;
    }
  }

  async getDatabaseCredentials() {
    const secretName = `bia/${process.env.NODE_ENV}/database`;
    return await this.getSecret(secretName);
  }
}

module.exports = new SecretsManager();
```

### STS (Security Token Service)
```javascript
// config/aws-sts.js
const { STSClient, AssumeRoleCommand } = require('@aws-sdk/client-sts');

class STSManager {
  constructor() {
    this.client = new STSClient({
      region: process.env.AWS_REGION || 'us-east-1'
    });
  }

  async assumeRole(roleArn, sessionName) {
    try {
      const command = new AssumeRoleCommand({
        RoleArn: roleArn,
        RoleSessionName: sessionName,
        DurationSeconds: 3600 // 1 hora
      });

      const response = await this.client.send(command);
      return response.Credentials;
    } catch (error) {
      console.error('Erro ao assumir role:', error);
      throw error;
    }
  }
}

module.exports = new STSManager();
```

## Configurações por Ambiente

### Development
```javascript
// config/development.js
module.exports = {
  app: {
    name: 'BIA Development',
    port: process.env.PORT || 8080,
    host: 'localhost'
  },
  database: {
    logging: true,
    sync: false // Usar migrations
  },
  aws: {
    region: 'us-east-1',
    useLocalCredentials: true
  },
  cors: {
    origin: ['http://localhost:3000', 'http://localhost:5173'],
    credentials: true
  },
  session: {
    secret: 'dev-secret-key',
    resave: false,
    saveUninitialized: false
  }
};
```

### Production
```javascript
// config/production.js
module.exports = {
  app: {
    name: 'BIA Production',
    port: process.env.PORT || 8080,
    host: '0.0.0.0'
  },
  database: {
    logging: false,
    pool: {
      max: 10,
      min: 2,
      acquire: 30000,
      idle: 10000
    }
  },
  aws: {
    region: process.env.AWS_REGION,
    useIAMRoles: true
  },
  cors: {
    origin: process.env.FRONTEND_URL,
    credentials: true
  },
  session: {
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: true,
      httpOnly: true,
      maxAge: 24 * 60 * 60 * 1000 // 24 horas
    }
  }
};
```

## Configuração do Express

### Middleware Configuration
```javascript
// config/express.js
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const session = require('express-session');
const config = require('config');

module.exports = (app) => {
  // CORS
  app.use(cors(config.cors));

  // Logging
  if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev'));
  } else {
    app.use(morgan('combined'));
  }

  // Body parsing
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // Session
  app.use(session(config.session));

  // Static files
  app.use(express.static('public'));

  // Health check
  app.get('/api/versao', (req, res) => {
    res.json({
      name: config.app.name,
      version: process.env.npm_package_version || '4.2.0',
      environment: process.env.NODE_ENV,
      timestamp: new Date().toISOString()
    });
  });
};
```

## Validação de Configurações

### Environment Validator
```javascript
// config/validator.js
class ConfigValidator {
  static validateRequired() {
    const required = [
      'NODE_ENV',
      'DB_HOST',
      'DB_NAME',
      'DB_USER',
      'DB_PASS'
    ];

    const missing = required.filter(key => !process.env[key]);
    
    if (missing.length > 0) {
      throw new Error(`Variáveis de ambiente obrigatórias não definidas: ${missing.join(', ')}`);
    }
  }

  static validateDatabase() {
    const dbConfig = require('./database')[process.env.NODE_ENV];
    
    if (!dbConfig) {
      throw new Error(`Configuração de banco não encontrada para ambiente: ${process.env.NODE_ENV}`);
    }

    return dbConfig;
  }

  static validateAWS() {
    if (process.env.NODE_ENV === 'production') {
      const awsRequired = ['AWS_REGION'];
      const missing = awsRequired.filter(key => !process.env[key]);
      
      if (missing.length > 0) {
        throw new Error(`Configurações AWS obrigatórias não definidas: ${missing.join(', ')}`);
      }
    }
  }
}

module.exports = ConfigValidator;
```

## Configuração de Logs

### Winston Logger
```javascript
// config/logger.js
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { 
    service: 'bia-api',
    version: process.env.npm_package_version || '4.2.0'
  },
  transports: [
    new winston.transports.File({ 
      filename: 'logs/error.log', 
      level: 'error' 
    }),
    new winston.transports.File({ 
      filename: 'logs/combined.log' 
    })
  ]
});

// Console em desenvolvimento
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}

module.exports = logger;
```

## Configuração de Testes

### Test Configuration
```javascript
// config/test.js
module.exports = {
  database: {
    username: 'postgres',
    password: 'senha',
    database: 'bia_test',
    host: 'localhost',
    port: 5432,
    dialect: 'postgres',
    logging: false
  },
  app: {
    port: 3001
  },
  aws: {
    region: 'us-east-1',
    endpoint: 'http://localhost:4566' // LocalStack
  }
};
```

## Configuração Docker

### Multi-stage Configuration
```dockerfile
# Dockerfile
FROM node:18-slim

# Configurar diretório de trabalho
WORKDIR /usr/src/app

# Copiar arquivos de configuração
COPY package*.json ./
COPY config/ ./config/

# Instalar dependências
RUN npm ci --only=production

# Copiar código da aplicação
COPY . .

# Expor porta
EXPOSE 8080

# Comando de inicialização
CMD ["npm", "start"]
```

## Troubleshooting

### Problemas Comuns

#### Variáveis de Ambiente Não Carregadas
```bash
# Verificar variáveis
printenv | grep DB_

# Verificar no Node.js
console.log('DB_HOST:', process.env.DB_HOST);
```

#### Conexão com Banco Falha
```javascript
// Testar conexão
const { Sequelize } = require('sequelize');
const config = require('./config/database')[process.env.NODE_ENV];

const sequelize = new Sequelize(config);

sequelize.authenticate()
  .then(() => console.log('Conexão estabelecida'))
  .catch(err => console.error('Erro de conexão:', err));
```

#### AWS Credentials
```bash
# Verificar credenciais
aws sts get-caller-identity

# Verificar região
echo $AWS_REGION
```

## Boas Práticas

### Segurança
- **Nunca** commitar credenciais no código
- Usar **Secrets Manager** para produção
- Validar todas as configurações na inicialização
- Usar **HTTPS** em produção

### Performance
- **Pool de conexões** configurado adequadamente
- **Timeout** configurado para requests
- **Logging** otimizado por ambiente

### Manutenibilidade
- Configurações centralizadas
- Validação de configurações
- Documentação atualizada
- Versionamento de configurações

## Próximos Passos

### Melhorias Planejadas
- **Config Server**: Configurações centralizadas
- **Feature Flags**: Controle de funcionalidades
- **Health Checks**: Monitoramento de saúde
- **Metrics**: Coleta de métricas

### Integração AWS
- **Parameter Store**: Configurações centralizadas
- **CloudWatch**: Logs centralizados
- **X-Ray**: Tracing distribuído
- **Config Rules**: Compliance automático

---

**Projeto BIA v4.2.0**  
*Imersão AWS & IA - 28/07 a 03/08/2025*

> **Importante**: Sempre validar configurações antes de deploy em produção!
