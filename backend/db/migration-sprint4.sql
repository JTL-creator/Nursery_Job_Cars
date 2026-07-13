-- =====================================================
-- GDM Job Cars - Migracao Sprint 4 (idempotente)
-- Time/equipe e foto nos ativos
-- =====================================================

-- Equipe / Time do veiculo (ex.: Milho, Soja, Agronomia)
ALTER TABLE ativos
    ADD COLUMN IF NOT EXISTS equipe VARCHAR(80);

-- URL da foto do ativo (upload)
ALTER TABLE ativos
    ADD COLUMN IF NOT EXISTS foto_url TEXT;

CREATE INDEX IF NOT EXISTS idx_ativos_equipe
    ON ativos(equipe);
