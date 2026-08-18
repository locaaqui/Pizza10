# 🍕 Pizza10

Sistema de gestão de pizzaria com cardápio digital, pedidos online e painel administrativo.

## Funcionalidades

- **Login seguro** — Autenticação via Supabase Auth
- **Dashboard** — Resumo de pedidos, faturamento e status em tempo real
- **Cardápio digital** — Página pública com categorias, preços e pedido via WhatsApp
- **Gestão de pedidos** — CRUD completo com workflow de status (Novo → Preparando → Entrega → Entregue)

## Tecnologias

- HTML5, CSS3, JavaScript vanilla
- [Supabase](https://supabase.com/) — Banco de dados e autenticação
- Design responsivo mobile-first

## Estrutura

```
Pizza10/
├── index.html          # Página de login
├── dashboard.html      # Painel administrativo
├── cardapio.html       # Cardápio público
├── pedidos.html        # Gestão de pedidos
├── css/style.css       # Design system
└── js/                 # Módulos JavaScript
    ├── supabase-config.js
    ├── auth.js
    ├── dashboard.js
    ├── cardapio.js
    └── pedidos.js
```

## Como Usar

1. Abra `index.html` no navegador
2. Faça login com suas credenciais
3. Acesse o dashboard para gerenciar pedidos

## Licença

Projeto privado — Pizza10 © 2026
