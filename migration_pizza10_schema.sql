-- ==============================================================================
-- SCHEMA DE MIGRAÇÃO: PIZZA10 (SUPABASE POSTGRESQL)
-- Execute este script no SQL Editor do Supabase (Dashboard -> SQL Editor -> New Query)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. TABELA: categorias_pizza10
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.categorias_pizza10 (
    id INTEGER PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    inativa BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 2. TABELA: produtos_pizza10
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.produtos_pizza10 (
    id INTEGER PRIMARY KEY,
    categoria_id INTEGER REFERENCES public.categorias_pizza10(id) ON DELETE SET NULL,
    categoria_nome VARCHAR(255),
    nome VARCHAR(255) NOT NULL,
    descricao TEXT,
    preco NUMERIC(10, 2) DEFAULT 0.00,
    preco_custo NUMERIC(10, 2) DEFAULT 0.00,
    unidade VARCHAR(50) DEFAULT 'UN',
    codigo_barras VARCHAR(100),
    ativo BOOLEAN DEFAULT true,
    delivery BOOLEAN DEFAULT true,
    balcao BOOLEAN DEFAULT true,
    mesa BOOLEAN DEFAULT true,
    imagem_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 3. TABELA: clientes_pizza10
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.clientes_pizza10 (
    id INTEGER PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    razao_social VARCHAR(255),
    nome_fantasia VARCHAR(255),
    documento VARCHAR(50), -- CPF ou CNPJ
    rg_ie VARCHAR(50),
    telefone_principal VARCHAR(50),
    telefones JSONB DEFAULT '[]'::jsonb, -- Array com todos os telefones associados
    email VARCHAR(255),
    cep VARCHAR(20),
    endereco VARCHAR(255),
    numero VARCHAR(50),
    complemento VARCHAR(255),
    bairro VARCHAR(100),
    cidade VARCHAR(100),
    estado VARCHAR(10),
    observacao TEXT,
    limite_credito NUMERIC(12, 2) DEFAULT 0.00,
    consumo_total NUMERIC(14, 2) DEFAULT 0.00,
    qtd_pedidos INTEGER DEFAULT 0,
    data_ultimo_pedido TIMESTAMPTZ,
    inativo BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 4. TABELA: pedidos_pizza10
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pedidos_pizza10 (
    id INTEGER PRIMARY KEY,
    cliente_id INTEGER REFERENCES public.clientes_pizza10(id) ON DELETE SET NULL,
    cliente_nome VARCHAR(255),
    cliente_telefone VARCHAR(50),
    data_pedido TIMESTAMPTZ NOT NULL,
    tipo_pedido INTEGER DEFAULT 1, -- 1=Delivery, 2=Balcão, 3=Mesa, etc.
    status VARCHAR(50) DEFAULT 'entregue', -- novo, preparando, entrega, entregue, cancelado
    total_produtos NUMERIC(12, 2) DEFAULT 0.00,
    total_desconto NUMERIC(12, 2) DEFAULT 0.00,
    taxa_entrega NUMERIC(12, 2) DEFAULT 0.00,
    total_pedido NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    forma_pagamento_id INTEGER,
    forma_pagamento_nome VARCHAR(100),
    pgto_dinheiro NUMERIC(12, 2) DEFAULT 0.00,
    pgto_cartao NUMERIC(12, 2) DEFAULT 0.00,
    pgto_cheque NUMERIC(12, 2) DEFAULT 0.00,
    pgto_outros NUMERIC(12, 2) DEFAULT 0.00,
    pgto_troco NUMERIC(12, 2) DEFAULT 0.00,
    mesa INTEGER,
    atendente VARCHAR(100),
    entregador VARCHAR(100),
    observacao TEXT,
    endereco_entrega TEXT,
    itens_resumo TEXT, -- Resumo textual dos itens para listagens rápidas
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 5. TABELA: pedidos_itens_pizza10
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pedidos_itens_pizza10 (
    id BIGINT PRIMARY KEY,
    pedido_id INTEGER NOT NULL REFERENCES public.pedidos_pizza10(id) ON DELETE CASCADE,
    produto_id INTEGER REFERENCES public.produtos_pizza10(id) ON DELETE SET NULL,
    descricao VARCHAR(255) NOT NULL,
    quantidade NUMERIC(10, 3) NOT NULL DEFAULT 1,
    preco_unitario NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    preco_total NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    desconto NUMERIC(10, 2) DEFAULT 0.00,
    observacao TEXT,
    cancelado BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- ÍNDICES PARA CONSULTAS DE ALTA PERFORMANCE
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_clientes_pizza10_doc ON public.clientes_pizza10(documento);
CREATE INDEX IF NOT EXISTS idx_clientes_pizza10_tel ON public.clientes_pizza10(telefone_principal);
CREATE INDEX IF NOT EXISTS idx_clientes_pizza10_nome ON public.clientes_pizza10(nome);
CREATE INDEX IF NOT EXISTS idx_clientes_pizza10_cidade ON public.clientes_pizza10(cidade);
CREATE INDEX IF NOT EXISTS idx_clientes_pizza10_bairro ON public.clientes_pizza10(bairro);

CREATE INDEX IF NOT EXISTS idx_pedidos_pizza10_cliente ON public.pedidos_pizza10(cliente_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_pizza10_data ON public.pedidos_pizza10(data_pedido DESC);
CREATE INDEX IF NOT EXISTS idx_pedidos_pizza10_status ON public.pedidos_pizza10(status);

CREATE INDEX IF NOT EXISTS idx_pedidos_itens_pizza10_pedido ON public.pedidos_itens_pizza10(pedido_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_itens_pizza10_produto ON public.pedidos_itens_pizza10(produto_id);

CREATE INDEX IF NOT EXISTS idx_produtos_pizza10_cat ON public.produtos_pizza10(categoria_id);
CREATE INDEX IF NOT EXISTS idx_produtos_pizza10_nome ON public.produtos_pizza10(nome);

-- ------------------------------------------------------------------------------
-- POLÍTICAS DE SEGURANÇA (ROW LEVEL SECURITY - RLS)
-- ------------------------------------------------------------------------------
ALTER TABLE public.categorias_pizza10 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos_pizza10 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes_pizza10 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_pizza10 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_itens_pizza10 ENABLE ROW LEVEL SECURITY;

-- Leitura pública para cardápio (produtos e categorias)
DROP POLICY IF EXISTS "Permitir leitura publica de categorias_pizza10" ON public.categorias_pizza10;
CREATE POLICY "Permitir leitura publica de categorias_pizza10" ON public.categorias_pizza10 FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Permitir leitura publica de produtos_pizza10" ON public.produtos_pizza10;
CREATE POLICY "Permitir leitura publica de produtos_pizza10" ON public.produtos_pizza10 FOR SELECT TO public USING (true);

-- Acesso total (leitura/escrita) para anon/public e authenticated no sistema
DROP POLICY IF EXISTS "Permitir acesso total em categorias_pizza10" ON public.categorias_pizza10;
CREATE POLICY "Permitir acesso total em categorias_pizza10" ON public.categorias_pizza10 FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir acesso total em produtos_pizza10" ON public.produtos_pizza10;
CREATE POLICY "Permitir acesso total em produtos_pizza10" ON public.produtos_pizza10 FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir acesso total em clientes_pizza10" ON public.clientes_pizza10;
CREATE POLICY "Permitir acesso total em clientes_pizza10" ON public.clientes_pizza10 FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir acesso total em pedidos_pizza10" ON public.pedidos_pizza10;
CREATE POLICY "Permitir acesso total em pedidos_pizza10" ON public.pedidos_pizza10 FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir acesso total em pedidos_itens_pizza10" ON public.pedidos_itens_pizza10;
CREATE POLICY "Permitir acesso total em pedidos_itens_pizza10" ON public.pedidos_itens_pizza10 FOR ALL TO public USING (true) WITH CHECK (true);
