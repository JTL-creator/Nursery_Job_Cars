# 📱 GDM Job Cars — App Mobile (Sprint 1)

App **Flutter** para gestão operacional de Job Cars e máquinas agrícolas da GDM.

> Roda em **Android (USB)**, **Android Emulator** e **Chrome Web**.

---

## 🎨 Identidade Visual GDM
- Azul escuro: `#092A3B`
- Verde lima: `#B4BD00`

---

## 🧱 Stack

| Camada | Tecnologia |
|---|---|
| Framework | Flutter 3.24+ / Dart 3.x |
| State | Provider |
| Navegação | go_router |
| HTTP | Dio (com refresh token automático) |
| Storage seguro | flutter_secure_storage |
| Offline cache | Hive |
| QR Code | mobile_scanner |
| Câmera/foto | image_picker |
| GPS | geolocator |
| Notificações | flutter_local_notifications |
| Conectividade | connectivity_plus |

---

## 🚀 Como rodar

### 1. Instalar dependências
```bash
cd mobile
flutter pub get
```

### 2. Subir o backend
Em outro terminal:
```bash
cd ../backend
npm run dev
```
Backend roda em `http://localhost:5000`.

### 3. Rodar no Android via USB
- Conecte o celular com **depuração USB ativada**
- Liste dispositivos:
  ```bash
  flutter devices
  ```
- Rode:
  ```bash
  flutter run -d <device-id>
  ```

⚠️ **Atenção:** quando rodando em celular físico via USB, o `localhost` do PC NÃO é acessível pelo celular. Edite `lib/core/constants/app_constants.dart` e troque a URL para o **IP da sua máquina na rede local** (ex: `http://192.168.1.10:5000/api/v1`).

Descobrir o IP no Windows:
```powershell
ipconfig | findstr IPv4
```

### 4. Rodar no Chrome (mais rápido para testar)
```bash
flutter run -d chrome
```
> O proxy do Vite (frontend React) não vale aqui — o app Flutter vai direto na API.

---

## 🔑 Credenciais padrão (dev)
- 📧 `admin@gdm.com`
- 🔑 `Admin@123`

---

## ✨ Funcionalidades — Sprint 1

- ✅ Login com JWT + **refresh automático**
- ✅ Solicitação de cadastro
- ✅ Home com KPIs e atalhos
- ✅ Dark / Light mode persistido
- ✅ **Bottom Navigation** nativa (5 abas)
- ✅ **QR Code Scanner** (mobile_scanner)
- ✅ Estrutura preparada para câmera (image_picker)
- ✅ Estrutura preparada para GPS (geolocator)
- ✅ Estrutura preparada para notificações
- ✅ Indicador de conectividade (online/offline)
- ✅ Cache offline (Hive) preparado
- ✅ Identidade visual GDM

---

## 🗺️ Roadmap

| Sprint | Foco | Status |
|---|---|---|
| 1 | Fundação + Auth + QR Scanner | ✅ Entregue |
| 2 | Disponibilidade + Reservas | 🔜 Próximo |
| 3 | Check-lists com câmera + GPS | ⏳ |
| 4 | Modo offline robusto + Sync | ⏳ |
| 5 | Push notifications + Analytics | ⏳ |

---

## 🔐 Permissões necessárias

### Android
Já configuradas no `AndroidManifest.xml`:
- `INTERNET`
- `CAMERA` (QR scan e fotos de check-list)
- `ACCESS_FINE_LOCATION` (GPS para check-list)
- `POST_NOTIFICATIONS` (lembretes)
- `VIBRATE`

O app pede as permissões em runtime quando o recurso for usado.

### Web
- Câmera e localização funcionam via HTTPS (ou localhost). O navegador pede permissão automaticamente.

---

**Autor:** Jhean Torres Leite — BR Nursery Supervisor
**Localização:** Porto Nacional, Tocantins
