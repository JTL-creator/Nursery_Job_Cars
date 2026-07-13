-- =====================================================
-- GDM Job Cars & Máquinas Agrícolas
-- Schema PostgreSQL Completo (Sprint 1)
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- TABELA: perfis
-- =====================================================
CREATE TABLE IF NOT EXISTS perfis (
    id          SERIAL PRIMARY KEY,
    nome        VARCHAR(50) UNIQUE NOT NULL,
    descricao   TEXT,
    ativo       BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABELA: usuarios
-- =====================================================
CREATE TABLE IF NOT EXISTS usuarios (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome_completo     VARCHAR(200) NOT NULL,
    matricula         VARCHAR(50) UNIQUE NOT NULL,
    email             VARCHAR(200) UNIQUE NOT NULL,
    telefone          VARCHAR(30),
    unidade_lotacao   VARCHAR(120),
    senha_hash        VARCHAR(255) NOT NULL,
    perfil_id         INT NOT NULL REFERENCES perfis(id),
    status            VARCHAR(20) NOT NULL DEFAULT 'ATIVO'
                       CHECK (status IN ('ATIVO','INATIVO','BLOQUEADO')),
    criado_em         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ultimo_login_em   TIMESTAMPTZ
);

-- =====================================================
-- TABELA: solicitacoes_cadastro
-- =====================================================
CREATE TABLE IF NOT EXISTS solicitacoes_cadastro (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome_completo       VARCHAR(200) NOT NULL,
    matricula           VARCHAR(50) NOT NULL,
    email               VARCHAR(200) NOT NULL,
    telefone            VARCHAR(30),
    unidade_lotacao     VARCHAR(120),
    justificativa       TEXT,
    status              VARCHAR(20) NOT NULL DEFAULT 'PENDENTE'
                         CHECK (status IN ('PENDENTE','APROVADA','REJEITADA')),
    analisado_por       UUID REFERENCES usuarios(id),
    analisado_em        TIMESTAMPTZ,
    observacao_rejeicao TEXT,
    criado_em           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABELA: ativos (veículos, máquinas, implementos)
-- =====================================================
CREATE TABLE IF NOT EXISTS ativos (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo_interno  VARCHAR(50) UNIQUE NOT NULL,
    descricao       VARCHAR(255) NOT NULL,
    tipo_ativo      VARCHAR(30) NOT NULL
                     CHECK (tipo_ativo IN ('VEICULO','MAQUINA_AGRICOLA','IMPLEMENTO')),
    sub_tipo        VARCHAR(60),
    placa           VARCHAR(15),
    patrimonio      VARCHAR(50),
    unidade         VARCHAR(120),
    status          VARCHAR(20) NOT NULL DEFAULT 'DISPONIVEL'
                     CHECK (status IN ('DISPONIVEL','RESERVADO','INDISPONIVEL','MANUTENCAO')),
    observacoes     TEXT,
    criado_em       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABELA: reservas
-- =====================================================
CREATE TABLE IF NOT EXISTS reservas (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id        UUID NOT NULL REFERENCES usuarios(id),
    ativo_id          UUID NOT NULL REFERENCES ativos(id),
    data_hora_inicio  TIMESTAMPTZ NOT NULL,
    data_hora_fim     TIMESTAMPTZ NOT NULL,
    status            VARCHAR(20) NOT NULL DEFAULT 'PENDENTE'
                       CHECK (status IN ('PENDENTE','CONFIRMADA','EM_USO','CONCLUIDA','CANCELADA','EXPIRADA')),
    motivo            VARCHAR(255),
    observacoes       TEXT,
    criado_em         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    confirmado_em     TIMESTAMPTZ,
    cancelado_em      TIMESTAMPTZ,
    CONSTRAINT chk_reserva_periodo CHECK (data_hora_fim > data_hora_inicio)
);

-- =====================================================
-- TABELA: checklist_templates
-- =====================================================
CREATE TABLE IF NOT EXISTS checklist_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_ativo      VARCHAR(30) NOT NULL
                     CHECK (tipo_ativo IN ('VEICULO','MAQUINA_AGRICOLA','IMPLEMENTO')),
    etapa           VARCHAR(20) NOT NULL
                     CHECK (etapa IN ('RETIRADA','DEVOLUCAO')),
    nome            VARCHAR(120) NOT NULL,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    versao          INT NOT NULL DEFAULT 1,
    criado_em       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABELA: checklist_template_itens
-- =====================================================
CREATE TABLE IF NOT EXISTS checklist_template_itens (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id   UUID NOT NULL REFERENCES checklist_templates(id) ON DELETE CASCADE,
    chave_item    VARCHAR(80) NOT NULL,
    descricao     VARCHAR(255) NOT NULL,
    tipo_campo    VARCHAR(20) NOT NULL
                   CHECK (tipo_campo IN ('texto','numero','booleano','selecao','data','observacao')),
    obrigatorio   BOOLEAN NOT NULL DEFAULT FALSE,
    ordem         INT NOT NULL DEFAULT 0,
    opcoes_json   JSONB,
    criado_em     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABELA: checklists
-- =====================================================
CREATE TABLE IF NOT EXISTS checklists (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reserva_id        UUID NOT NULL REFERENCES reservas(id),
    ativo_id          UUID NOT NULL REFERENCES ativos(id),
    usuario_id        UUID NOT NULL REFERENCES usuarios(id),
    tipo_checklist    VARCHAR(30) NOT NULL,
    etapa             VARCHAR(20) NOT NULL
                       CHECK (etapa IN ('RETIRADA','DEVOLUCAO')),
    data_hora_evento  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    local             VARCHAR(120),
    responsavel       VARCHAR(200),
    observacoes       TEXT,
    criado_em         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABELA: checklist_itens
-- =====================================================
CREATE TABLE IF NOT EXISTS checklist_itens (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    checklist_id    UUID NOT NULL REFERENCES checklists(id) ON DELETE CASCADE,
    chave_item      VARCHAR(80) NOT NULL,
    descricao_item  VARCHAR(255),
    valor_texto     TEXT,
    valor_numero    NUMERIC(18,4),
    valor_booleano  BOOLEAN,
    obrigatorio     BOOLEAN NOT NULL DEFAULT FALSE,
    ordem           INT NOT NULL DEFAULT 0,
    criado_em       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABELA: auditoria_eventos (imutável)
-- =====================================================
CREATE TABLE IF NOT EXISTS auditoria_eventos (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id    UUID REFERENCES usuarios(id),
    entidade      VARCHAR(80) NOT NULL,
    entidade_id   VARCHAR(80),
    acao          VARCHAR(80) NOT NULL,
    antes_json    JSONB,
    depois_json   JSONB,
    ip_origem     VARCHAR(60),
    user_agent    VARCHAR(255),
    criado_em     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- TABELA: indicadores_agregados
-- =====================================================
CREATE TABLE IF NOT EXISTS indicadores_agregados (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_indicador    VARCHAR(80) NOT NULL,
    periodo_inicio    DATE NOT NULL,
    periodo_fim       DATE NOT NULL,
    chave_dimensao    VARCHAR(160),
    valor             NUMERIC(18,4),
    atualizado_em     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- ÍNDICES (performance e integridade)
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_reservas_ativo_periodo
    ON reservas(ativo_id, status, data_hora_inicio, data_hora_fim);
CREATE INDEX IF NOT EXISTS idx_reservas_usuario
    ON reservas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_ativos_tipo_status
    ON ativos(tipo_ativo, status);
CREATE INDEX IF NOT EXISTS idx_auditoria_entidade
    ON auditoria_eventos(entidade, entidade_id);
CREATE INDEX IF NOT EXISTS idx_checklists_reserva
    ON checklists(reserva_id);
CREATE INDEX IF NOT EXISTS idx_solicitacoes_status
    ON solicitacoes_cadastro(status);
CREATE INDEX IF NOT EXISTS idx_usuarios_perfil
    ON usuarios(perfil_id);

-- =====================================================
-- FIM DO SCHEMA
-- =====================================================
