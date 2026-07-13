-- =====================================================
-- GDM Job Cars - Migracao Sprint 5 (idempotente)
-- Portaria: perfil VIGILANTE + registro de saida/entrada
-- =====================================================

-- Perfil de vigilante (portaria) - confere liberacao de saida dos veiculos
INSERT INTO perfis (nome, descricao)
VALUES ('VIGILANTE', 'Vigilante de portaria - confere liberacao de saida dos veiculos')
ON CONFLICT (nome) DO NOTHING;

-- Indice para busca de ativos por placa (normalizada, sem separadores)
CREATE INDEX IF NOT EXISTS idx_ativos_placa_normalizada
    ON ativos ((regexp_replace(upper(coalesce(placa, '')), '[^A-Z0-9]', '', 'g')));

-- =====================================================
-- TABELA: movimentacoes_portaria (log de saida/entrada)
-- =====================================================
CREATE TABLE IF NOT EXISTS movimentacoes_portaria (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ativo_id      UUID NOT NULL REFERENCES ativos(id),
    reserva_id    UUID REFERENCES reservas(id),
    vigilante_id  UUID REFERENCES usuarios(id),
    tipo          VARCHAR(10) NOT NULL
                   CHECK (tipo IN ('SAIDA', 'ENTRADA')),
    placa         VARCHAR(15),
    liberado      BOOLEAN NOT NULL DEFAULT TRUE,
    motivo        TEXT,
    observacoes   TEXT,
    criado_em     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mov_portaria_ativo
    ON movimentacoes_portaria (ativo_id, criado_em DESC);
CREATE INDEX IF NOT EXISTS idx_mov_portaria_reserva
    ON movimentacoes_portaria (reserva_id);
CREATE INDEX IF NOT EXISTS idx_mov_portaria_data
    ON movimentacoes_portaria (criado_em DESC);
