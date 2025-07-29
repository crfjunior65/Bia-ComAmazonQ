# Client - Frontend do Projeto BIA

## Visão Geral
Este diretório contém a aplicação frontend do projeto BIA, construída com React 18 e Vite como bundler. A interface oferece uma experiência moderna e responsiva para interação com a API backend.

## Estrutura do Diretório

```
client/
├── src/           # Código fonte da aplicação React
├── public/        # Arquivos estáticos públicos
├── package.json   # Dependências e scripts do frontend
├── vite.config.js # Configuração do Vite
├── index.html     # Template HTML principal
├── db.json        # Mock data para desenvolvimento
└── .env           # Variáveis de ambiente
```

## Tecnologias Utilizadas

### Core
- **React 18.3.1**: Biblioteca para interfaces de usuário
- **React DOM 18.3.1**: Renderização do React no browser
- **React Router DOM 6.28.0**: Roteamento client-side

### Build & Development
- **Vite 5.4.19**: Build tool e dev server
- **@vitejs/plugin-react 4.5.2**: Plugin React para Vite

### UI & Icons
- **React Icons 5.3.0**: Biblioteca de ícones
- **CSS Modules**: Estilização modular

### Testing
- **@testing-library/react 16.0.1**: Testes de componentes
- **@testing-library/jest-dom 6.5.0**: Matchers customizados
- **@testing-library/user-event 14.5.2**: Simulação de eventos

### Development Tools
- **JSON Server 1.0.0-beta.3**: Mock API para desenvolvimento
- **Web Vitals 4.2.4**: Métricas de performance

## Scripts Disponíveis

### Desenvolvimento
```bash
# Iniciar servidor de desenvolvimento
npm run dev

# Servidor mock da API (porta 5000)
npm run server
```

### Build & Deploy
```bash
# Build para produção
npm run build

# Preview do build de produção
npm run preview
```

## Configuração do Vite

### Características Principais
- **Hot Module Replacement (HMR)**: Atualizações instantâneas
- **Build otimizado**: Bundling eficiente para produção
- **Dev server rápido**: Inicialização instantânea
- **ES Modules**: Suporte nativo a módulos ES6+

### Configuração de Proxy
```javascript
// vite.config.js
export default {
  server: {
    proxy: {
      '/api': 'http://localhost:8080'
    }
  }
}
```

## Variáveis de Ambiente

### Desenvolvimento (.env)
```bash
VITE_API_URL=http://localhost:8080/api
```

### Produção
```bash
VITE_API_URL=https://api.bia.com/api
```

## Estrutura de Componentes

### Organização Sugerida
```
src/
├── components/     # Componentes reutilizáveis
├── pages/         # Páginas da aplicação
├── hooks/         # Custom hooks
├── services/      # Serviços de API
├── utils/         # Utilitários
├── styles/        # Estilos globais
└── App.jsx        # Componente principal
```

## Integração com Backend

### Configuração da API
```javascript
const API_BASE_URL = import.meta.env.VITE_API_URL;

const api = {
  get: (endpoint) => fetch(`${API_BASE_URL}${endpoint}`),
  post: (endpoint, data) => fetch(`${API_BASE_URL}${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
};
```

### Health Check
```javascript
// Verificar status da API
const checkApiHealth = async () => {
  try {
    const response = await api.get('/versao');
    return response.ok;
  } catch (error) {
    console.error('API não disponível:', error);
    return false;
  }
};
```

## Desenvolvimento Local

### Pré-requisitos
- Node.js 18+
- npm ou yarn

### Configuração Inicial
```bash
# Instalar dependências
npm install

# Iniciar desenvolvimento
npm run dev

# Em outro terminal, iniciar mock server
npm run server
```

### URLs de Desenvolvimento
- **Frontend**: http://localhost:5173
- **Mock API**: http://localhost:5000
- **Backend API**: http://localhost:8080

## Build para Produção

### Processo de Build
```bash
# Gerar build otimizado
npm run build

# Arquivos gerados em /dist
ls dist/
```

### Otimizações Incluídas
- **Code splitting**: Divisão automática do código
- **Tree shaking**: Remoção de código não utilizado
- **Minificação**: Compressão de JS/CSS
- **Asset optimization**: Otimização de imagens e fontes

## Configuração Docker

### Dockerfile para Produção
```dockerfile
FROM nginx:alpine
COPY dist/ /usr/share/nginx/html/
EXPOSE 80
```

### Build da Imagem
```bash
# Build da aplicação
npm run build

# Build da imagem Docker
docker build -t bia-frontend .
```

## Performance & SEO

### Web Vitals Monitorados
- **LCP**: Largest Contentful Paint
- **FID**: First Input Delay
- **CLS**: Cumulative Layout Shift

### Boas Práticas Implementadas
- Lazy loading de componentes
- Otimização de imagens
- Caching de recursos estáticos
- Compressão gzip/brotli

## Testes

### Executar Testes
```bash
# Testes unitários
npm test

# Testes com coverage
npm test -- --coverage
```

### Estrutura de Testes
```
src/
├── __tests__/          # Testes unitários
├── components/
│   └── Button.test.jsx # Teste do componente
└── utils/
    └── helpers.test.js # Teste de utilitários
```

## Próximos Passos

- Implementação de PWA (Progressive Web App)
- Integração com AWS Amplify
- Implementação de testes E2E com Cypress
- Configuração de CI/CD para frontend
- Otimização de bundle size

---

**Projeto BIA v4.2.0**  
*Imersão AWS & IA - 28/07 a 03/08/2025*
