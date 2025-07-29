# Tests - Testes Automatizados

## Visão Geral
Este diretório contém toda a estrutura de testes automatizados do projeto BIA, incluindo testes unitários, de integração e end-to-end. O framework principal utilizado é o Jest.

## Estrutura do Diretório

```
tests/
├── unit/           # Testes unitários
├── integration/    # Testes de integração
├── e2e/           # Testes end-to-end
├── fixtures/      # Dados de teste
├── helpers/       # Utilitários para testes
└── README.md      # Esta documentação
```

## Tecnologias Utilizadas

### Framework de Testes
- **Jest 27.5.1**: Framework principal de testes
- **@testing-library/jest-dom 5.11.4**: Matchers customizados para DOM
- **@testing-library/react 11.1.0**: Testes de componentes React
- **@testing-library/user-event 12.1.10**: Simulação de eventos de usuário

### Ferramentas Auxiliares
- **Supertest**: Testes de API HTTP
- **Sinon**: Mocks e stubs
- **Faker**: Geração de dados fake
- **Nock**: Mock de requisições HTTP

## Configuração do Jest

### jest.config.js
```javascript
module.exports = {
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  testMatch: [
    '**/__tests__/**/*.js',
    '**/?(*.)+(spec|test).js'
  ],
  collectCoverageFrom: [
    'api/**/*.js',
    'config/**/*.js',
    '!**/node_modules/**',
    '!**/coverage/**'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],
  testTimeout: 10000
};
```

### Setup de Testes
```javascript
// tests/setup.js
const { Sequelize } = require('sequelize');

// Configuração global para testes
global.testDb = new Sequelize({
  dialect: 'sqlite',
  storage: ':memory:',
  logging: false
});

// Hooks globais
beforeAll(async () => {
  // Configuração inicial dos testes
  await global.testDb.authenticate();
});

afterAll(async () => {
  // Limpeza após todos os testes
  await global.testDb.close();
});

beforeEach(() => {
  // Reset antes de cada teste
  jest.clearAllMocks();
});
```

## Testes Unitários

### Estrutura
```
tests/unit/
├── api/
│   ├── controllers/
│   ├── models/
│   └── routes/
├── config/
└── utils/
```

### Exemplo de Teste de Controller
```javascript
// tests/unit/api/controllers/user.test.js
const UserController = require('../../../../api/controllers/user');
const User = require('../../../../api/models/user');

// Mock do modelo
jest.mock('../../../../api/models/user');

describe('UserController', () => {
  let req, res;

  beforeEach(() => {
    req = {
      body: {},
      params: {},
      query: {}
    };
    res = {
      json: jest.fn(),
      status: jest.fn().mockReturnThis(),
      send: jest.fn()
    };
  });

  describe('getUsers', () => {
    it('deve retornar lista de usuários', async () => {
      // Arrange
      const mockUsers = [
        { id: 1, name: 'User 1', email: 'user1@test.com' },
        { id: 2, name: 'User 2', email: 'user2@test.com' }
      ];
      User.findAll.mockResolvedValue(mockUsers);

      // Act
      await UserController.getUsers(req, res);

      // Assert
      expect(User.findAll).toHaveBeenCalled();
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        data: mockUsers
      });
    });

    it('deve tratar erro ao buscar usuários', async () => {
      // Arrange
      const error = new Error('Database error');
      User.findAll.mockRejectedValue(error);

      // Act
      await UserController.getUsers(req, res);

      // Assert
      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        error: 'Erro interno do servidor'
      });
    });
  });
});
```

### Exemplo de Teste de Modelo
```javascript
// tests/unit/api/models/user.test.js
const { Sequelize, DataTypes } = require('sequelize');
const UserModel = require('../../../../api/models/user');

describe('User Model', () => {
  let sequelize, User;

  beforeAll(async () => {
    sequelize = new Sequelize('sqlite::memory:', { logging: false });
    User = UserModel(sequelize, DataTypes);
    await sequelize.sync();
  });

  afterAll(async () => {
    await sequelize.close();
  });

  beforeEach(async () => {
    await User.destroy({ where: {}, truncate: true });
  });

  describe('Validações', () => {
    it('deve criar usuário válido', async () => {
      const userData = {
        name: 'Test User',
        email: 'test@example.com'
      };

      const user = await User.create(userData);

      expect(user.name).toBe(userData.name);
      expect(user.email).toBe(userData.email);
      expect(user.id).toBeDefined();
    });

    it('deve falhar com email inválido', async () => {
      const userData = {
        name: 'Test User',
        email: 'invalid-email'
      };

      await expect(User.create(userData))
        .rejects
        .toThrow('Validation error');
    });

    it('deve falhar com nome vazio', async () => {
      const userData = {
        name: '',
        email: 'test@example.com'
      };

      await expect(User.create(userData))
        .rejects
        .toThrow('Validation error');
    });
  });
});
```

## Testes de Integração

### Estrutura
```
tests/integration/
├── api/
│   ├── routes/
│   └── database/
└── services/
```

### Exemplo de Teste de Rota
```javascript
// tests/integration/api/routes/users.test.js
const request = require('supertest');
const app = require('../../../../index');
const { User } = require('../../../../api/models');

describe('Users API', () => {
  beforeEach(async () => {
    // Limpar dados de teste
    await User.destroy({ where: {}, truncate: true });
  });

  describe('GET /api/users', () => {
    it('deve retornar lista vazia inicialmente', async () => {
      const response = await request(app)
        .get('/api/users')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual([]);
    });

    it('deve retornar usuários existentes', async () => {
      // Criar usuários de teste
      await User.bulkCreate([
        { name: 'User 1', email: 'user1@test.com' },
        { name: 'User 2', email: 'user2@test.com' }
      ]);

      const response = await request(app)
        .get('/api/users')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(2);
    });
  });

  describe('POST /api/users', () => {
    it('deve criar novo usuário', async () => {
      const userData = {
        name: 'New User',
        email: 'newuser@test.com'
      };

      const response = await request(app)
        .post('/api/users')
        .send(userData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe(userData.name);
      expect(response.body.data.email).toBe(userData.email);
    });

    it('deve falhar com dados inválidos', async () => {
      const userData = {
        name: '',
        email: 'invalid-email'
      };

      const response = await request(app)
        .post('/api/users')
        .send(userData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBeDefined();
    });
  });
});
```

## Testes End-to-End

### Estrutura
```
tests/e2e/
├── user-flows/
├── api-workflows/
└── integration-scenarios/
```

### Exemplo de Teste E2E
```javascript
// tests/e2e/user-flows/user-management.test.js
const request = require('supertest');
const app = require('../../../index');
const { User } = require('../../../api/models');

describe('User Management Flow', () => {
  beforeEach(async () => {
    await User.destroy({ where: {}, truncate: true });
  });

  it('deve completar fluxo completo de usuário', async () => {
    // 1. Criar usuário
    const createResponse = await request(app)
      .post('/api/users')
      .send({
        name: 'Test User',
        email: 'test@example.com'
      })
      .expect(201);

    const userId = createResponse.body.data.id;

    // 2. Buscar usuário criado
    const getResponse = await request(app)
      .get(`/api/users/${userId}`)
      .expect(200);

    expect(getResponse.body.data.name).toBe('Test User');

    // 3. Atualizar usuário
    const updateResponse = await request(app)
      .put(`/api/users/${userId}`)
      .send({
        name: 'Updated User'
      })
      .expect(200);

    expect(updateResponse.body.data.name).toBe('Updated User');

    // 4. Listar usuários
    const listResponse = await request(app)
      .get('/api/users')
      .expect(200);

    expect(listResponse.body.data).toHaveLength(1);
    expect(listResponse.body.data[0].name).toBe('Updated User');

    // 5. Deletar usuário
    await request(app)
      .delete(`/api/users/${userId}`)
      .expect(204);

    // 6. Verificar que usuário foi deletado
    await request(app)
      .get(`/api/users/${userId}`)
      .expect(404);
  });
});
```

## Fixtures e Helpers

### Fixtures
```javascript
// tests/fixtures/users.js
module.exports = {
  validUser: {
    name: 'Test User',
    email: 'test@example.com'
  },
  
  invalidUser: {
    name: '',
    email: 'invalid-email'
  },
  
  userList: [
    { name: 'User 1', email: 'user1@test.com' },
    { name: 'User 2', email: 'user2@test.com' },
    { name: 'User 3', email: 'user3@test.com' }
  ]
};
```

### Helpers
```javascript
// tests/helpers/database.js
const { Sequelize } = require('sequelize');

class TestDatabase {
  constructor() {
    this.sequelize = new Sequelize('sqlite::memory:', {
      logging: false
    });
  }

  async setup() {
    await this.sequelize.authenticate();
    await this.sequelize.sync({ force: true });
  }

  async cleanup() {
    await this.sequelize.close();
  }

  async clearAll() {
    const models = Object.values(this.sequelize.models);
    for (const model of models) {
      await model.destroy({ where: {}, truncate: true });
    }
  }
}

module.exports = TestDatabase;
```

## Scripts de Teste

### package.json
```json
{
  "scripts": {
    "test": "jest tests/unit",
    "test:integration": "jest tests/integration",
    "test:e2e": "jest tests/e2e",
    "test:all": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:ci": "jest --ci --coverage --watchAll=false"
  }
}
```

### Comandos de Execução
```bash
# Testes unitários
npm test

# Testes de integração
npm run test:integration

# Testes end-to-end
npm run test:e2e

# Todos os testes
npm run test:all

# Testes com coverage
npm run test:coverage

# Modo watch (desenvolvimento)
npm run test:watch
```

## Coverage e Relatórios

### Configuração de Coverage
```javascript
// jest.config.js
module.exports = {
  collectCoverageFrom: [
    'api/**/*.js',
    'config/**/*.js',
    '!**/node_modules/**',
    '!**/tests/**',
    '!**/coverage/**'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  }
};
```

### Relatórios
```bash
# Gerar relatório HTML
npm run test:coverage

# Visualizar relatório
open coverage/lcov-report/index.html
```

## CI/CD Integration

### GitHub Actions
```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:16.1
        env:
          POSTGRES_PASSWORD: senha
          POSTGRES_DB: bia_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run tests
        run: npm run test:ci
        env:
          DB_HOST: localhost
          DB_USER: postgres
          DB_PASS: senha
          DB_NAME: bia_test
```

## Mocks e Stubs

### AWS Services Mock
```javascript
// tests/helpers/aws-mock.js
const AWS = require('aws-sdk-mock');

class AWSMock {
  static mockSecretsManager() {
    AWS.mock('SecretsManager', 'getSecretValue', (params, callback) => {
      const secrets = {
        'bia/dev/database': {
          username: 'postgres',
          password: 'senha',
          host: 'localhost'
        }
      };
      
      callback(null, {
        SecretString: JSON.stringify(secrets[params.SecretId])
      });
    });
  }

  static restore() {
    AWS.restore();
  }
}

module.exports = AWSMock;
```

## Boas Práticas

### Organização
- **Estrutura espelhada**: Testes seguem estrutura do código
- **Nomenclatura clara**: Nomes descritivos para testes
- **Isolamento**: Cada teste é independente
- **Setup/Teardown**: Limpeza adequada entre testes

### Performance
- **Testes rápidos**: Unitários devem ser muito rápidos
- **Paralelização**: Executar testes em paralelo
- **Mocks apropriados**: Mock de dependências externas
- **Dados mínimos**: Usar apenas dados necessários

### Manutenibilidade
- **DRY**: Reutilizar helpers e fixtures
- **Legibilidade**: Testes como documentação
- **Cobertura**: Manter cobertura adequada
- **Refatoração**: Manter testes atualizados

## Troubleshooting

### Problemas Comuns

#### Testes Lentos
```bash
# Identificar testes lentos
npm test -- --verbose

# Executar com timeout maior
npm test -- --testTimeout=30000
```

#### Falhas Intermitentes
```bash
# Executar teste específico múltiplas vezes
npm test -- --testNamePattern="nome do teste" --verbose
```

#### Problemas de Memória
```bash
# Aumentar heap size
node --max-old-space-size=4096 node_modules/.bin/jest
```

## Próximos Passos

### Melhorias Planejadas
- **Visual Regression Testing**: Testes de interface
- **Performance Testing**: Testes de carga
- **Security Testing**: Testes de segurança
- **Contract Testing**: Testes de contrato de API

### Ferramentas Adicionais
- **Cypress**: Testes E2E mais robustos
- **Storybook**: Testes de componentes isolados
- **Artillery**: Testes de performance
- **SonarQube**: Análise de qualidade de código

---

**Projeto BIA v4.2.0**  
*Imersão AWS & IA - 28/07 a 03/08/2025*

> **Lembre-se**: Testes são investimento em qualidade e confiança no código!
