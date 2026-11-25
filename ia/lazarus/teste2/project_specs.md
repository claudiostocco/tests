# Relatório de Análise do Projeto Lazarus/Horse

## 1. Visão Geral
O projeto é um servidor de API REST desenvolvido em **Pascal (Lazarus/Free Pascal)** utilizando o framework web **Horse**. A aplicação serve como backend para um sistema de gestão (SGT), expondo endpoints para autenticação, controle de empresas, usuários, produtos e movimentações.

### Estrutura do Projeto
O código segue uma arquitetura em camadas (Service Layer):
- **Controllers** (`src/controllers`): Responsáveis por definir as rotas HTTP e processar requisições/respostas.
- **Services** (`src/services`): Contêm as regras de negócio e acionam a camada de dados.
- **Connectors/Adapters** (`src/connectors`, `src/db`): Gerenciam a conexão com o banco de dados e abstração de queries.

## 2. Tecnologias Identificadas
- **Linguagem**: Object Pascal (Free Pascal / Lazarus).
- **Framework Web**: **Horse** (com middlewares: Jhonson, HandleException, CORS, JWT).
- **Acesso a Dados**: **UniDAC** (Universal Data Access Components) da Devart, com suporte aparente a múltiplos bancos (Firebird, PostgreSQL).
- **Autenticação**: JWT (JSON Web Tokens) com implementação customizada de middleware.
