# 🎨 GDM Job Cars — Frontend (Sprint 1)

Frontend **React + TypeScript + Vite** para a plataforma de gestão de Job Cars e máquinas agrícolas da GDM.

> Conectado ao **backend Sprint 1** (Node + Express + PostgreSQL/Neon).

---

## 🎨 Identidade Visual GDM
- Azul escuro: `#092A3B`
- Verde lima: `#B4BD00`

---

## 🧱 Stack

| Camada | Tecnologia |
|---|---|
| Framework | React 18 + TypeScript |
| Build | Vite 5 |
| Estilo | Tailwind CSS (com cores GDM customizadas) |
| Roteamento | React Router DOM v6 |
| HTTP | Axios (com interceptors de auth + refresh automático) |
| Ícones | lucide-react |
| Toasts | react-hot-toast |

---

## 🚀 Como rodar

```bash
cd frontend
npm install
cp .env.example .env

npm run dev
# Abre em http://localhost:5173
```

> O Vite já está configurado com proxy `/api` → `http://localhost:5000`. Certifique-se de que o **backend Sprint 1** está rodando.

### Credenciais padrão (dev)
- 📧 `admin@gdm.com`
- 🔑 `Admin@123`

---

## ✨ Funcionalidades já entregues (Sprint 1)

- 🔐 **Login** com JWT + refresh automático
- 📝 **Solicitação de cadastro** pública
- 🛡️ **RBAC** no frontend (rotas e menus por perfil)
- 👤 **Aprovação/rejeição** de cadastros (admin) com modal e auditoria
- 🌙 **Dark/light mode** com persistência
- 📱 **Mobile-first responsivo** com sidebar colapsável (desktop) e bottom nav (mobile)
- 🎨 **Identidade GDM** consistente
- 🍞 **Toasts** padronizados para feedback

---

## 📁 Estrutura

```
frontend/
├── public/
├── src/
│   ├── components/
│   │   ├── Layout/        (MainLayout, Sidebar, Navbar, BottomNav, ProtectedRoute)
│   │   └── UI/            (Button, Input, Card, Spinner, Badge, EmptyState)
│   ├── contexts/          (AuthContext, ThemeContext)
│   ├── hooks/             (useAuth, useTheme)
│   ├── pages/             (Login, Solicitar, Home, Disponibilidade, Reservas, Checklists, Ativos, Solicitações, Analytics, 404)
│   ├── services/          (api, authService, cadastroService)
│   ├── types/             (TypeScript types)
│   ├── App.tsx
│   ├── main.tsx
│   └── index.css
├── index.html
├── vite.config.ts
├── tailwind.config.js
├── tsconfig.json
└── package.json
```

---

## 🗺️ Roadmap

| Sprint | Foco | Status |
|---|---|---|
| 1 | Fundação + Auth + Cadastro | ✅ Entregue |
| 2 | Ativos + Reservas | 🔜 Próximo |
| 3 | Check-lists dinâmicos | ⏳ |
| 4 | App Flutter mobile | ⏳ |
| 5 | Analytics + Deploy | ⏳ |

---

**Autor:** Jhean Torres Leite — BR Nursery Supervisor
**Localização:** Porto Nacional, Tocantins
