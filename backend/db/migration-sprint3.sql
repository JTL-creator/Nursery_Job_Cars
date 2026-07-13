-- =====================================================
-- GDM Job Cars - Migracao Sprint 3 (idempotente)
-- Aprovacao de reservas + Responsaveis por ativo + Notificacoes
-- =====================================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Perfil de responsavel (aprovador de reservas)
INSERT INTO perfis (nome, descricao)
VALUES ('RESPONSAVEL', 'Responsavel por ativos - aprova reservas')
ON CONFLICT (nome) DO NOTHING;

-- Responsavel vinculado ao ativo
ALTER TABLE ativos
    ADD COLUMN IF NOT EXISTS responsavel_id UUID REFERENCES usuarios(id);

CREATE INDEX IF NOT EXISTS idx_ativos_responsavel
    ON ativos(responsavel_id);

-- Campos de aprovacao/rejeicao em reservas
ALTER TABLE reservas
    ADD COLUMN IF NOT EXISTS aprovado_por    UUID REFERENCES usuarios(id);
ALTER TABLE reservas
    ADD COLUMN IF NOT EXISTS aprovado_em     TIMESTAMPTZ;
ALTER TABLE reservas
    ADD COLUMN IF NOT EXISTS rejeitado_por   UUID REFERENCES usuarios(id);
ALTER TABLE reservas
    ADD COLUMN IF NOT EXISTS rejeitado_em    TIMESTAMPTZ;
ALTER TABLE reservas
    ADD COLUMN IF NOT EXISTS motivo_rejeicao TEXT;

-- Adiciona o status REJEITADA ao CHECK de status das reservas
ALTER TABLE reservas DROP CONSTRAINT IF EXISTS reservas_status_check;
ALTER TABLE reservas
    ADD CONSTRAINT reservas_status_check
    CHECK (status IN ('PENDENTE','CONFIRMADA','EM_USO','CONCLUIDA','CANCELADA','EXPIRADA','REJEITADA'));

-- =====================================================
-- TABELA: notificacoes (feed in-app / aprovacoes)
-- =====================================================
CREATE TABLE IF NOT EXISTS notificacoes (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id    UUID NOT NULL REFERENCES usuarios(id),
    tipo          VARCHAR(40) NOT NULL,
    titulo        VARCHAR(160) NOT NULL,
    mensagem      TEXT,
    entidade      VARCHAR(80),
    entidade_id   VARCHAR(80),
    lida          BOOLEAN NOT NULL DEFAULT FALSE,
    criado_em     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notificacoes_usuario
    ON notificacoes(usuario_id, lida, criado_em DESC);
