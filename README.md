# 🍕 Pizza10

Sistema completo de gestão para pizzaria com cardápio digital, delivery online, gestão de pedidos e controle de clientes com histórico de 24 anos.

## Funcionalidades

- **Login seguro** — Autenticação integrada via Supabase Auth
- **Dashboard** — Resumo de pedidos de hoje, faturamento e status em tempo real
- **Cardápio digital** — Página pública com categorias, preços, imagens e pedido via WhatsApp
- **Gestão de pedidos** — Fluxo operacional (*Novo ➜ Preparando ➜ Em Entrega ➜ Entregue / Cancelado*)
- **Gestão de clientes** — Ficha completa dos 47.361 clientes históricos com múltiplos telefones, busca instantânea e filtros por cidade
- **Migração fiel de dados** — Pipeline automatizado de extração e ingestão do banco legado SQL Server (`DB_SVR_Dados.mdf`) para o Supabase

## Tecnologias

- HTML5, CSS3 (Design System exclusivo em Dark Mode), JavaScript vanilla
- [Supabase](https://supabase.com/) (PostgreSQL + Auth + Storage)
- SQL Server Express / LocalDB (Fonte de dados legada)

## Estrutura do Projeto

```
Pizza10/
├── index.html                  # Página de Login
├── dashboard.html              # Painel Administrativo com métricas
├── cardapio.html               # Cardápio Digital Público
├── pedidos.html                # Gerenciador de Pedidos
├── admin-clientes.html         # Painel de Clientes e Histórico
├── migration_pizza10_schema.sql # Script DDL completo para o Supabase
├── migrar-pizza10.ps1          # Script de extração e ingestão em lotes
├── css/style.css               # Design System temático
└── js/                         # Módulos JavaScript
    ├── supabase-config.js
    ├── auth.js
    ├── dashboard.js
    ├── cardapio.js
    └── pedidos.js
```

## Banco de Dados no Supabase

Tabelas isoladas com prefixo `_pizza10`:
1. `categorias_pizza10` — 22 categorias de cardápio
2. `produtos_pizza10` — 541 produtos cadastrados
3. `clientes_pizza10` — 47.361 clientes com múltiplos telefones
4. `pedidos_pizza10` — 313.985 pedidos históricos
5. `pedidos_itens_pizza10` — 1.016.756 itens detalhados

## Como Executar a Migração

1. Abra o **SQL Editor** no painel do Supabase.
2. Cole e execute o conteúdo de [`migration_pizza10_schema.sql`](migration_pizza10_schema.sql).
3. Execute o script de migração no PowerShell:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File migrar-pizza10.ps1
   ```

## Licença

Projeto privado — Pizza10 © 2026
