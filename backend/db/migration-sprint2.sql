-- =====================================================
-- GDM Job Cars - Migracao Sprint 2/3 (idempotente)
-- =====================================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE INDEX IF NOT EXISTS idx_reservas_status
    ON reservas(status);
CREATE INDEX IF NOT EXISTS idx_checklist_templates_lookup
    ON checklist_templates(tipo_ativo, etapa, ativo, versao DESC);
CREATE INDEX IF NOT EXISTS idx_checklists_usuario
    ON checklists(usuario_id);
