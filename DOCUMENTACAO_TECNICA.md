# 📘 Documentação Técnica — GDM Job Cars

## 1. Visão Arquitetural

Arquitetura em **camadas** com modular monolítica, separando:

- **Apresentação:** app Flutter (Sprint 4)
- **Aplicação:** controllers + services Express
- **Domínio:** regras de reserva, check-list, RBAC
- **Infraestrutura:** PostgreSQL (Neon), JWT, logs

Toda regra crítica é validada no **backend** — o frontend apenas reflete permissões.

---

## 2. Modelo de Dados

| Entidade | Função |
|---|---|
| `perfis` | USUARIO, ADMINISTRADOR, GERENTE |
| `usuarios` | Colaboradores autenticáveis |
| `solicitacoes_cadastro` | Workflow de aprovação |
| `ativos` | Veículos, máquinas, implementos |
| `reservas` | Agendamento com prevenção de conflito |
| `checklist_templates` | Templates versionados por tipo |
| `checklist_template_itens` | Campos dinâmicos |
| `checklists` | Registro de retirada/devolução |
| `checklist_itens` | Respostas individuais |
| `auditoria_eventos` | Trilha imutável |
| `indicadores_agregados` | Camada analítica |

### Índice crítico de concorrência

```sql
CREATE INDEX idx_reservas_ativo_periodo
  ON reservas(ativo_id, status, data_hora_inicio, data_hora_fim);
```

Esse índice é usado no **Sprint 2** para a validação transacional de sobreposição (regra `RES_001`).

---

## 3. Fluxo de Autenticação (JWT)

1. App envia `email` + `senha`.
2. API valida com `bcrypt` e checa `status = ATIVO`.
3. Gera **access token** (15min) e **refresh token** (7 dias).
4. App armazena tokens em `flutter_secure_storage`.
5. Refresh feito via `POST /auth/refresh`.

---

## 4. Matriz RBAC

| Recurso | USUARIO | ADMINISTRADOR | GERENTE |
|---|:-:|:-:|:-:|
| Login | ✅ | ✅ | ✅ |
| Solicitar cadastro | ✅ | ✅ | ✅ |
| Aprovar/rejeitar cadastros | ❌ | ✅ | ❌ |
| Gerenciar ativos | ❌ | ✅ | ❌ |
| Criar reserva | ✅ | ✅ | ✅ |
| Ver reservas de terceiros | ❌ | ✅ | ✅ |
| Área analítica | ❌ | ✅ | ✅ |
| Auditoria | ❌ | ✅ | ❌ |

---

## 5. Códigos de Erro

| Código | HTTP | Significado |
|---|:-:|---|
| `AUTH_001` | 401 | Credenciais inválidas |
| `AUTH_002` | 403 | Usuário inativo |
| `AUTH_003` | 401 | Token expirado/ausente |
| `PERM_001` | 403 | Acesso negado |
| `RES_001` | 409 | Conflito de reserva |
| `RES_002` | 400 | Período inválido |
| `RES_003` | 404 | Reserva inexistente |
| `CHK_001` | 400 | Check-list sem reserva válida |
| `CHK_002` | 404 | Template não encontrado |
| `VAL_001` | 400 | Campo obrigatório ausente |
| `VAL_002` | 400 | Formato inválido |
| `SRV_500` | 500 | Erro interno |

---

## 6. Auditoria

Eventos gravados automaticamente em `auditoria_eventos`:

- LOGIN / LOGOUT
- CRIAR_SOLICITACAO
- APROVAR_SOLICITACAO / REJEITAR_SOLICITACAO
- (Sprint 2) CRIAR_RESERVA / CONFIRMAR_RESERVA / CANCELAR_RESERVA
- (Sprint 3) CRIAR_CHECKLIST / FINALIZAR_CHECKLIST

Cada registro contém `antes_json`, `depois_json`, IP e user-agent.

---

## 7. Próximos Passos por Sprint

### Sprint 2 — Reservas
- CRUD de ativos
- `GET /reservas/disponibilidade`
- `POST /reservas` com **transação + bloqueio pessimista**
- Validação de sobreposição:
  ```sql
  SELECT 1 FROM reservas
   WHERE ativo_id = $1
     AND status IN ('CONFIRMADA','EM_USO','PENDENTE')
     AND tstzrange(data_hora_inicio, data_hora_fim) &&
         tstzrange($2::timestamptz, $3::timestamptz)
   FOR UPDATE;
  ```

### Sprint 3 — Check-lists
- CRUD de templates
- Renderização dinâmica de campos
- Validação de vínculo `reserva → checklist`

### Sprint 4 — App Flutter
- Login, Solicitar Cadastro, Home, Disponibilidade, Reserva, Check-list
- Identidade GDM (`#092A3B` / `#B4BD00`)

### Sprint 5 — Analytics + Deploy
- Endpoints `/analytics/*`
- Dashboards inspirados no padrão Power BI (como em Crossing Manager)
- Docker + CI/CD

---

**Versão:** 0.1.0 — Sprint 1
**Autor:** Jhean Torres Leite
