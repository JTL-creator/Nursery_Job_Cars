# 🚜 GDM Job Cars & Máquinas Agrícolas — Plataforma

Plataforma para **gerenciamento operacional de veículos Job Cars e máquinas agrícolas**, com suporte a reservas, check-lists, histórico rastreável e área analítica restrita.

> **Sprint 1 — Fundação (Backend + Autenticação + Cadastro)**
> Entrega inicial do backend pronto para evoluir para os módulos de Reservas, Check-lists, App Mobile e Analytics.

---

## 🎨 Identidade Visual GDM
- **Azul escuro:** `#092A3B`
- **Verde lima:** `#B4BD00`

---

## 🧱 Stack Técnica

| Camada | Tecnologia |
|---|---|
| Backend | Node.js + Express + TypeScript-ready (CommonJS) |
| Banco | PostgreSQL (Neon) |
| Auth | JWT (access + refresh) com `bcryptjs` |
| Validação | Joi |
| Segurança | Helmet, CORS, Rate Limit |
| Logs | JSON estruturado |
| Mobile (Sprint 4) | Flutter |

---

## 📁 Estrutura do Projeto

```
gdm-job-cars-platform/
├── backend/
│   ├── apply-schema.js          # Aplica o schema no Neon
│   ├── seed.js                  # Cria perfis e admin padrão
│   ├── db/
│   │   └── schema.sql           # Schema PostgreSQL completo
│   └── src/
│       ├── server.js
│       ├── config/              # database, jwt
│       ├── controllers/         # auth, cadastro, usuario
│       ├── services/            # regras de negócio
│       ├── middlewares/         # auth, rbac, errors, audit
│       ├── routes/              # rotas v1
│       ├── validators/          # schemas Joi
│       └── utils/               # errorCodes, logger
├── README.md
└── DOCUMENTACAO_TECNICA.md
```

---

## ⚙️ Como rodar localmente

```bash
cd backend
npm install
cp .env.example .env
# edite o .env com sua DATABASE_URL do Neon

# 1. Cria todas as tabelas
npm run schema

# 2. Insere perfis padrão e usuário admin
npm run seed

# 3. Inicia a API
npm run dev
```

### Acessos padrão
- **Admin:** `admin@gdm.com` / `Admin@123`
- **Health check:** `GET http://localhost:5000/api/v1/health`

---

## 📡 Endpoints implementados (Sprint 1)

### Autenticação
| Método | Rota | Acesso |
|---|---|---|
| POST | `/api/v1/auth/login` | Público |
| POST | `/api/v1/auth/refresh` | Público |
| POST | `/api/v1/auth/logout` | Autenticado |

### Solicitação de cadastro
| Método | Rota | Acesso |
|---|---|---|
| POST | `/api/v1/cadastros/solicitacoes` | Público |
| GET | `/api/v1/cadastros/solicitacoes` | ADMINISTRADOR |
| PATCH | `/api/v1/cadastros/solicitacoes/:id/aprovar` | ADMINISTRADOR |
| PATCH | `/api/v1/cadastros/solicitacoes/:id/rejeitar` | ADMINISTRADOR |

### Usuário
| Método | Rota | Acesso |
|---|---|---|
| GET | `/api/v1/usuarios/me` | Autenticado |

---

## 🗺️ Roadmap

| Sprint | Foco | Status |
|---|---|---|
| 1 | Fundação: schema, auth, cadastro, auditoria | ✅ Entregue |
| 2 | Ativos + Reservas com validação transacional | 🔜 Próximo |
| 3 | Check-lists dinâmicos com templates | ⏳ |
| 4 | App Mobile Flutter | ⏳ |
| 5 | Analytics + Admin + Deploy | ⏳ |

---

## 🔐 Códigos de Erro Padronizados

`AUTH_001` `AUTH_002` `AUTH_003` `PERM_001` `RES_001` `RES_002` `RES_003`
`CHK_001` `CHK_002` `VAL_001` `VAL_002` `SRV_500`

Detalhes completos em `DOCUMENTACAO_TECNICA.md`.

---

**Autor:** Jhean Torres Leite — BR Nursery Supervisor
**Localização:** Porto Nacional, Tocantins
