# Database - Gerenciamento do Banco de Dados

## Visão Geral
Este diretório contém toda a estrutura de gerenciamento do banco de dados do projeto BIA, incluindo migrations, seeds e configurações do Sequelize ORM. O banco utilizado é PostgreSQL 16.1.

## Estrutura do Diretório

```
database/
├── migrations/     # Arquivos de migração do banco
└── README.md      # Esta documentação
```

## Tecnologias Utilizadas

### Database Engine
- **PostgreSQL 16.1**: Banco de dados relacional principal
- **pg 8.7.1**: Driver PostgreSQL para Node.js
- **pg-hstore 2.3.4**: Suporte a tipos hstore

### ORM & CLI
- **Sequelize 6.6.5**: Object-Relational Mapping
- **sequelize-cli 6.2.0**: Interface de linha de comando

## Configuração do Sequelize

### Arquivo de Configuração (.sequelizerc)
```javascript
const path = require('path');

module.exports = {
  'config': path.resolve('config', 'database.js'),
  'models-path': path.resolve('api', 'models'),
  'seeders-path': path.resolve('database', 'seeders'),
  'migrations-path': path.resolve('database', 'migrations')
};
```

### Configuração de Conexão
```javascript
// config/database.js
module.exports = {
  development: {
    username: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASS || 'senha',
    database: process.env.DB_NAME || 'bia_db',
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    dialect: 'postgres',
    logging: console.log
  },
  production: {
    username: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    dialect: 'postgres',
    logging: false,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  }
};
```

## Migrations

### Conceito
Migrations são scripts que permitem versionar e evoluir a estrutura do banco de dados de forma controlada e reversível.

### Comandos Principais

#### Criar Nova Migration
```bash
# Criar migration para nova tabela
npx sequelize migration:generate --name create-users-table

# Criar migration para alterar tabela
npx sequelize migration:generate --name add-email-to-users
```

#### Executar Migrations
```bash
# Executar todas as migrations pendentes
npx sequelize db:migrate

# Executar migrations em container Docker
docker compose exec server bash -c 'npx sequelize db:migrate'

# Verificar status das migrations
npx sequelize db:migrate:status
```

#### Reverter Migrations
```bash
# Reverter última migration
npx sequelize db:migrate:undo

# Reverter todas as migrations
npx sequelize db:migrate:undo:all

# Reverter até migration específica
npx sequelize db:migrate:undo --to XXXXXXXXXXXXXX-migration-name.js
```

### Estrutura de uma Migration

```javascript
// migrations/XXXXXXXXXXXXXX-create-users-table.js
'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('Users', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      name: {
        type: Sequelize.STRING,
        allowNull: false
      },
      email: {
        type: Sequelize.STRING,
        allowNull: false,
        unique: true
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      }
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('Users');
  }
};
```

## Seeds (Dados Iniciais)

### Conceito
Seeds são scripts para popular o banco com dados iniciais ou de teste.

### Comandos de Seeds

#### Criar Seed
```bash
# Criar novo seed
npx sequelize seed:generate --name demo-users
```

#### Executar Seeds
```bash
# Executar todos os seeds
npx sequelize db:seed:all

# Executar seed específico
npx sequelize db:seed --seed XXXXXXXXXXXXXX-demo-users.js
```

#### Reverter Seeds
```bash
# Reverter todos os seeds
npx sequelize db:seed:undo:all

# Reverter seed específico
npx sequelize db:seed:undo --seed XXXXXXXXXXXXXX-demo-users.js
```

### Estrutura de um Seed

```javascript
// seeders/XXXXXXXXXXXXXX-demo-users.js
'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.bulkInsert('Users', [
      {
        name: 'Admin User',
        email: 'admin@bia.com',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        name: 'Test User',
        email: 'test@bia.com',
        createdAt: new Date(),
        updatedAt: new Date()
      }
    ], {});
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.bulkDelete('Users', null, {});
  }
};
```

## Modelos (Models)

### Localização
Os modelos ficam em `/api/models/` e são referenciados pelas migrations.

### Exemplo de Modelo
```javascript
// api/models/user.js
'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class User extends Model {
    static associate(models) {
      // Definir associações aqui
      // User.hasMany(models.Post, { foreignKey: 'userId' });
    }
  }
  
  User.init({
    name: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [2, 100]
      }
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      validate: {
        isEmail: true
      }
    }
  }, {
    sequelize,
    modelName: 'User',
    tableName: 'Users',
    timestamps: true
  });
  
  return User;
};
```

## Configuração em Diferentes Ambientes

### Desenvolvimento Local
```bash
# Variáveis de ambiente
DB_HOST=localhost
DB_PORT=5432
DB_NAME=bia_dev
DB_USER=postgres
DB_PASS=senha123
```

### Docker Compose
```yaml
# compose.yml
services:
  db:
    image: postgres:16.1
    environment:
      POSTGRES_DB: bia_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: senha
    ports:
      - "5432:5432"
```

### AWS RDS (Produção)
```bash
# Variáveis de ambiente para produção
DB_HOST=bia-db.cluster-xxxxx.us-east-1.rds.amazonaws.com
DB_PORT=5432
DB_NAME=bia_prod
DB_USER=postgres
DB_PASS=${SECRETS_MANAGER_PASSWORD}
```

## Backup e Restore

### Backup Manual
```bash
# Backup completo
pg_dump -h localhost -U postgres -d bia_db > backup.sql

# Backup apenas estrutura
pg_dump -h localhost -U postgres -d bia_db --schema-only > schema.sql

# Backup apenas dados
pg_dump -h localhost -U postgres -d bia_db --data-only > data.sql
```

### Restore
```bash
# Restore completo
psql -h localhost -U postgres -d bia_db < backup.sql

# Restore via Docker
docker compose exec db psql -U postgres -d bia_db < backup.sql
```

### Backup Automatizado (AWS RDS)
- **Automated Backups**: 7 dias de retenção
- **Manual Snapshots**: Backup antes de deploys
- **Point-in-time Recovery**: Recuperação até 5 minutos

## Monitoramento

### Métricas Importantes
- **Connections**: Número de conexões ativas
- **CPU Utilization**: Uso de CPU do banco
- **Database Size**: Crescimento do banco
- **Query Performance**: Queries lentas

### Logs
```bash
# Logs do PostgreSQL no Docker
docker compose logs db

# Logs de queries lentas
# postgresql.conf: log_min_duration_statement = 1000
```

## Troubleshooting

### Problemas Comuns

#### Migration Falha
```bash
# Verificar status
npx sequelize db:migrate:status

# Forçar estado da migration
npx sequelize db:migrate:undo --to XXXXXXXXXXXXXX-migration-name.js
```

#### Conexão Recusada
```bash
# Verificar se PostgreSQL está rodando
docker compose ps

# Verificar logs do banco
docker compose logs db

# Testar conexão
psql -h localhost -U postgres -d bia_db
```

#### Dados Corrompidos
```bash
# Recriar banco do zero
npx sequelize db:drop
npx sequelize db:create
npx sequelize db:migrate
npx sequelize db:seed:all
```

## Boas Práticas

### Migrations
- **Sempre reversíveis**: Implementar método `down`
- **Atômicas**: Uma alteração por migration
- **Testadas**: Testar up e down antes do deploy
- **Documentadas**: Comentários explicativos

### Performance
- **Índices**: Criar índices para queries frequentes
- **Constraints**: Usar constraints de banco
- **Normalization**: Normalizar dados adequadamente
- **Connection Pool**: Configurar pool de conexões

### Segurança
- **Credentials**: Nunca hardcode senhas
- **SSL**: Usar SSL em produção
- **Least Privilege**: Usuários com permissões mínimas
- **Backup Encryption**: Criptografar backups

## Próximos Passos

### Melhorias Planejadas
- **Seeders**: Dados iniciais para desenvolvimento
- **Indexes**: Otimização de performance
- **Views**: Views para queries complexas
- **Stored Procedures**: Lógica no banco quando necessário

### Integração AWS
- **RDS Proxy**: Pool de conexões gerenciado
- **Parameter Store**: Configurações centralizadas
- **CloudWatch**: Monitoramento avançado
- **Lambda**: Triggers para eventos do banco

---

**Projeto BIA v4.2.0**  
*Imersão AWS & IA - 28/07 a 03/08/2025*

> **Nota**: Sempre faça backup antes de executar migrations em produção!
