# MEDCLUES Healthcare Platform

**MEDCLUES** (formerly MediChain+) is a full-stack healthcare management ecosystem connecting **patients**, **doctors**, **hospital deans**, and **super administrators**. It supports appointment booking, medical records, real-time queue tracking, Razorpay payments, Agora video consultations, AI medical chat, emergency services, labs, blood banks, and multi-portal administration.

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Client Applications](#client-applications)
3. [Core Features by Client](#core-features-by-client)
4. [Technology Stack](#technology-stack)
5. [Project Structure](#project-structure)
6. [Getting Started](#getting-started)
7. [Environment Configuration](#environment-configuration)
8. [Portal Login Credentials](#portal-login-credentials)
9. [Backend API Overview](#backend-api-overview)
10. [Integrations](#integrations)
11. [Real-Time & Video](#real-time--video)
12. [Emergency Services](#emergency-services)
13. [Scripts & Auxiliary Folders](#scripts--auxiliary-folders)
14. [Development Notes](#development-notes)
15. [License & Security](#license--security)

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           CLIENT APPLICATIONS                            │
├──────────────┬──────────────┬─────────────────┬──────────────────────────┤
│  frontend/   │   admin/     │    mobile/      │    flutter_mobile/       │
│  React+Vite  │  React+Vite  │  Expo RN 54     │  Flutter (MEDCLUES) ★    │
│  Patient Web │ Admin/Dean/  │ Patient + Staff │  Primary mobile app      │
│              │ Doctor       │ mini-portals    │  + Emergency Module      │
└──────┬───────┴──────┬───────┴────────┬────────┴────────────┬─────────────┘
       │              │                │                     │
       └──────────────┴────────────────┴─────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │      fastapi_back/ :5000       │
                    │   FastAPI + PostgreSQL + JWT   │
                    │   Socket.IO + WebSocket        │
                    └───────────────┬───────────────┘
                                    │
       ┌────────────────────────────┼────────────────────────────┐
       ▼                            ▼                            ▼
  PostgreSQL                  Cloudinary                    Razorpay
  (Neon/local)                (documents)                   (payments)
       │                            │                            │
       ▼                            ▼                            ▼
  Agora RTC                   Brevo SMTP                   Telegram Bot
  (video)                     (OTP/email)                  (patient bot)
       │
       ▼
  AI (Mistral / Gemini / OpenAI)
```

★ **Recommended mobile client:** `flutter_mobile/` — full patient app with standalone emergency module.

---

## Client Applications

| Folder | Name | Stack | Users | Default Dev Port |
|--------|------|-------|-------|------------------|
| `frontend/` | Patient Web Portal | React 18, Vite 7, Tailwind, Framer Motion | Patients | `:5173` |
| `admin/` | Admin & Staff Portal | React 18, Vite 5, Tailwind, Chart.js | Super Admin, Dean, Doctor | `:5174` |
| `mobile/` | Expo Mobile (legacy) | Expo 54, React Native, Expo Router | Patient + Doctor/Dean/Admin | Expo dev server |
| `flutter_mobile/` | MEDCLUES Flutter App | Flutter, Riverpod, go_router, Dio | Patients | Device / Chrome |
| `fastapi_back/` | REST API | FastAPI, SQLAlchemy, asyncpg | All clients | `:5000` |

---

## Core Features by Client

### Patient Web (`frontend/`)

| Feature | Details |
|---------|---------|
| **Home & Discovery** | Specialities grid, top doctors, hospital tie-ups, symptoms-by-age/specialization, AI chatbot |
| **Doctor Search** | By speciality, hospital, text search; doctor profile with fees and hospital info |
| **Appointment Booking** | Slot selection, Razorpay payment, confirmation receipt with QR code and PDF |
| **My Appointments** | Upcoming/completed list, cancel, join video consult |
| **Video Consult** | Agora RTC web room (`/video-consult/:appointmentId`) |
| **Medical Records** | Upload and view lab reports, X-rays, prescriptions (Cloudinary) |
| **Labs & Blood Banks** | Lab directory, blood bank listings with availability |
| **Hospitals** | Collaborated hospitals list and hospital detail pages |
| **Emergency** | GPS, emergency contacts, nearby hospitals, backend alert (`/api/emergency/send-alert`) |
| **Queue Tracking** | Live token numbers and estimated wait times |
| **Auth** | Email/password + Google OAuth (Firebase) |
| **Profile** | Health info, records, personal details |
| **Static Pages** | About, Contact, Careers, Privacy Policy, Data Security |
| **Job Applications** | Career applications via `/api/job-applications` |

**Routes:** `/`, `/doctors`, `/doctor/:docId`, `/appointment/:docId`, `/appointment-confirmation`, `/my-appointments`, `/video-consult/:id`, `/my-profile`, `/my-labs`, `/labs`, `/hospitals`, `/hospital/:id`, `/emergency`, `/login`, `/forgot-password`, `/about`, `/contact`, `/careers`, and more.

---

### Admin & Doctor Portal (`admin/`)

Single login page with **three portal cards** (Super Admin / Dean / Doctor).

#### Super Admin

| Page | Features |
|------|----------|
| Dashboard | KPIs, live charts, doctors/hospitals overview, Socket.IO live data |
| Revenue Analytics | Revenue charts and analytics |
| All Appointments | System-wide appointments, cancel/reject, specialty helpline |
| Doctor List | Doctor CRUD, availability, bulk operations |
| Add Doctor | New doctor with Cloudinary image upload |
| Hospital Tie-ups | Hospital CRUD, embedded doctors |
| Manage Deans | Dean account management per hospital |
| Manage Labs | Diagnostic lab CRUD |
| Manage Blood Banks | Blood bank CRUD |
| Manage Users | Patient user management |
| System Settings | Platform settings UI |
| Data Export | Export tables via `/api/admin/export/{table}` |

#### Dean Portal (per-hospital scoped)

| Page | Features |
|------|----------|
| Dean Dashboard | Hospital-scoped analytics and charts |
| Dean Appointments | Hospital appointments |
| Dean Doctors | Doctor list, reset password, toggle status |
| Dean Patients | Patient list |
| Dean Add Doctor | Add doctor to own hospital |
| Dean Hospital | Hospital profile update |

#### Doctor Portal

| Page | Features |
|------|----------|
| Doctor Dashboard | Today's stats, appointments, complete/cancel |
| Doctor Appointments | Full appointment management |
| Doctor Video Calls | Video consult list |
| Doctor Video Room | Agora video room per appointment |
| Doctor Profile | Profile update |
| Queue Management | Real-time patient queue (Socket.IO) |

**Shared:** Real-time queue (`QueueManager` + Socket.IO), patient details modal, reports viewer, appointment email modal, PDF/Excel export, mobile-responsive sidebar.

---

### Expo Mobile (`mobile/`)

| Feature | Details |
|---------|---------|
| **Patient App** | Home, doctors, hospitals, labs, blood banks, booking, payments, records, profile, emergency |
| **Staff Mini-Portals** | Doctor, Dean, Admin tabs on mobile |
| **Auth** | Email/password, Google Sign-In, OTP verify, forgot/reset password |
| **Booking** | Full booking flow with Razorpay payment |
| **Receipts** | PDF receipt generation |
| **Real API** | No mock data — connects to `fastapi_back` |
| **Offline Banner** | Network connectivity indicator |
| **Dark Mode** | Theme toggle |

**Scripts:** `npm start`, `npm run android`, `npm run ios`, `npm run sync-api`

**Docs:** `mobile/README.md`, `mobile/GOOGLE_SIGNIN.md`, `mobile/AGENTS.md`

---

### Flutter Mobile — MEDCLUES (`flutter_mobile/`) ★

Full patient app with **standalone Emergency Module** (works without login).

| Category | Features |
|----------|----------|
| **Splash** | Opening video (`opening.mp4`), MEDCLUES logo fallback, floating SOS |
| **Auth** | Login, 4-step signup wizard, forgot password OTP, Google Sign-In |
| **Home** | Greeting, inline search, speciality grid, top doctors, quick-access tiles, drawer |
| **Doctors** | List (filter/sort), search, profile, in-person + online booking |
| **Booking** | Patient selector (For Me/Others), slot picker, symptoms, report upload, Razorpay (online), receipt PDF/share |
| **Appointments** | Tabbed (Upcoming/Completed/Cancelled), detail, cancel, join video |
| **Video Consult** | Agora RTC — mute, camera, timer, status polling |
| **Hospitals** | All + nearby (GPS), hospital detail with doctors |
| **Labs** | Searchable lab directory |
| **Blood Banks** | List + detail with blood-type availability |
| **Health Records** | Upload, list, view PDF/images |
| **Payments** | Razorpay checkout, payment history |
| **Profile** | Photo upload, personal info, address, payment methods/history, help, about, terms |
| **Notifications** | Appointment-derived feed with read state |
| **Settings** | Dark mode, emergency settings link |
| **Emergency Module** | Full SOS flow — see [Emergency Services](#emergency-services) |

**Full documentation:** [flutter_mobile/README.md](flutter_mobile/README.md)

---

## Technology Stack

| Layer | Technologies |
|-------|-------------|
| **Web Patient** | React 18, Vite 7, Tailwind CSS, Framer Motion, Axios, Firebase Auth, Agora Web SDK, Razorpay |
| **Web Admin** | React 18, Vite 5, Tailwind, Chart.js, Socket.IO client, Agora Web SDK, jsPDF, xlsx |
| **Expo Mobile** | Expo 54, React Native 0.81, Expo Router, NativeWind, Zustand, React Query, Reanimated, Lottie |
| **Flutter Mobile** | Flutter 3.3+, Dart 3.3+, Riverpod, go_router, Dio, geolocator, Firebase Auth, Agora RTC, video_player |
| **Backend** | FastAPI, Uvicorn, SQLAlchemy, asyncpg, PostgreSQL, python-jose (JWT), passlib |
| **Storage** | Cloudinary (documents), Secure Storage / SharedPreferences (mobile) |
| **Payments** | Razorpay (primary), PayU/Stripe env support |
| **Video** | Agora RTC (primary), Google Meet fallback |
| **Email** | Brevo SMTP (primary), Gmail SMTP fallback |
| **AI** | Mistral, Gemini, OpenAI (medical chat, slot suggestions) |
| **Real-time** | Socket.IO (queue), WebSocket (payment updates) |
| **Bot** | Telegram (aiogram) patient bot |

---

## Project Structure

```bash
PMS FNL 2/
├── frontend/                 # Patient web (React + Vite)
│   └── src/
│       ├── pages/            # Home, Doctors, Appointment, Emergency, VideoConsult, etc.
│       ├── components/       # Navbar, AIChatbot, QueueTracker, PaymentModal, etc.
│       └── context/          # AppContext (JWT, user, doctors)
│
├── admin/                    # Admin / Dean / Doctor dashboards
│   └── src/
│       ├── pages/Admin/      # Super admin pages
│       ├── pages/Dean/       # Dean portal pages
│       ├── pages/Doctor/     # Doctor portal pages
│       ├── components/       # QueueManager, VideoConsultRoom, charts
│       └── context/          # AdminContext, DeanContext, DoctorContext, SocketContext
│
├── mobile/                   # Expo React Native (legacy + staff portals)
│   ├── app/                  # Expo Router file-based routes
│   │   ├── (auth)/           # Login, register, OTP, forgot password
│   │   ├── (patient)/        # Patient home, profile, appointments, records
│   │   ├── (doctor)/         # Doctor tabs and screens
│   │   ├── (dean)/           # Dean tabs and screens
│   │   └── (admin)/          # Admin tabs and screens
│   └── services/             # API services per domain
│
├── flutter_mobile/           # ★ MEDCLUES Flutter patient app
│   └── lib/
│       ├── screens/          # 35+ UI screens
│       ├── features/emergency/  # Standalone emergency module
│       ├── services/         # Dio API layer (14 services)
│       ├── providers/        # Riverpod state
│       ├── routes/           # go_router
│       └── widgets/          # Animations, auth, cards, home, etc.
│
├── fastapi_back/             # FastAPI REST API
│   ├── main.py               # App entry, CORS, lifespan, Socket.IO mount
│   ├── app/
│   │   ├── routes/           # 19 API route modules
│   │   ├── controllers/      # 22 business logic controllers
│   │   ├── models/           # 18 SQLAlchemy models
│   │   ├── services/         # Email, Agora, Telegram, AI, queue, SMS
│   │   ├── middleware/       # JWT auth (user/admin/doctor/dean)
│   │   └── config/           # DB, settings
│   ├── scripts/              # Maintenance scripts
│   └── scratch/              # DB migration/debug utilities
│
├── scratch/                  # Root PPT generation, screenshots
├── ambulancia.gif/.lottie    # Splash animation assets
└── README.md
```

---

## Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Python | 3.10+ |
| Node.js | 18+ |
| Flutter SDK | 3.3+ (for `flutter_mobile/`) |
| PostgreSQL | Local or cloud (e.g. Neon) |

### 1. Backend (required for all clients)

```bash
cd fastapi_back
pip install -r requirements.txt
# Configure fastapi_back/.env (see Environment Configuration)
python -m uvicorn main:app --host 0.0.0.0 --port 5000 --reload
```

- API docs: `http://localhost:5000/docs`
- Integrations check: `GET /api/config/integrations`
- Use `--host 0.0.0.0` so phones/emulators on the same network can connect

### 2. Patient Web

```bash
cd frontend
npm install
# Configure frontend/.env (VITE_BACKEND_URL, Firebase, Razorpay)
npm run dev          # http://localhost:5173
```

### 3. Admin & Doctor Portal

```bash
cd admin
npm install
# Configure admin/.env (VITE_BACKEND_URL, VITE_ENABLE_SOCKET)
npm run dev          # http://localhost:5174
```

### 4. Expo Mobile (React Native)

```bash
cd mobile
npm install
# Set EXPO_PUBLIC_API_URL in mobile/.env to http://<YOUR_PC_LAN_IP>:5000
npm run sync-api
npx expo start -c
```

Phone and PC must be on the **same Wi‑Fi**.

### 5. Flutter Mobile — MEDCLUES (recommended)

```bash
cd flutter_mobile
flutter pub get
.\sync_env.ps1       # Copies API URL from mobile/.env
flutter run          # or: flutter run -d chrome
```

See **[flutter_mobile/README.md](flutter_mobile/README.md)** for complete setup.

### Quick Run All (typical dev session)

| Terminal | Command |
|----------|---------|
| 1 | `cd fastapi_back && python -m uvicorn main:app --host 0.0.0.0 --port 5000 --reload` |
| 2 | `cd frontend && npm run dev` |
| 3 | `cd admin && npm run dev` |
| 4 | `cd flutter_mobile && flutter run -d chrome` |

---

## Environment Configuration

### `fastapi_back/.env` (primary — all clients depend on this)

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_SECRET` | JWT token signing |
| `PORT` | Server port (default `5000`) |
| `DEBUG` | CORS localhost regex |
| `ADMIN_EMAIL`, `ADMIN_PASSWORD` | Super admin seed credentials |
| `CLOUDINARY_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | Medical document storage |
| `BREVO_API_KEY`, `BREVO_SENDER_EMAIL` | OTP and transactional email |
| `EMAIL_USER`, `EMAIL_APP_PASSWORD` | Gmail SMTP fallback |
| `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` | Payment gateway |
| `AGORA_APP_ID`, `AGORA_APP_CERTIFICATE` | Video consult tokens |
| `TELEGRAM_BOT_TOKEN`, `TELEGRAM_BOT_ENABLED` | Telegram patient bot |
| `GEMINI_API_KEY`, `MISTRAL_API_KEY`, `OPENAI_API_KEY` | AI medical chat |
| `FRONTEND_URL`, `BACKEND_URL` | URL references |
| `PLATFORM_FEE_PERCENTAGE`, `GST_PERCENTAGE` | Fee calculation |

### `frontend/.env`

| Variable | Purpose |
|----------|---------|
| `VITE_BACKEND_URL` | API base URL |
| `VITE_FIREBASE_*` | Google OAuth (6 Firebase keys) |
| `VITE_RAZORPAY_KEY_ID` | Razorpay checkout |

### `admin/.env`

| Variable | Purpose |
|----------|---------|
| `VITE_BACKEND_URL` | API base URL |
| `VITE_ENABLE_SOCKET` | Enable Socket.IO (`'true'`) |
| `VITE_CURRENCY` | Currency display |

### `mobile/.env`

| Variable | Purpose |
|----------|---------|
| `EXPO_PUBLIC_API_URL` | FastAPI base (LAN IP for physical devices) |
| `EXPO_PUBLIC_FIREBASE_*` | Firebase config |
| `EXPO_PUBLIC_GOOGLE_*_CLIENT_ID` | Google OAuth per platform |

### `flutter_mobile/.env`

| Variable | Purpose |
|----------|---------|
| `API_BASE_URL` | FastAPI URL (synced from Expo via `sync_env.ps1`) |
| `API_BASE_URL_WEB` | Web/Chrome API URL (default `http://localhost:5000`) |
| `AGORA_APP_ID` | Video consult |
| `GOOGLE_WEB_CLIENT_ID` | Google Sign-In |
| `FIREBASE_*` | Firebase platform keys |

---

## Portal Login Credentials

### Super Admin (full system control)

| Field | Value |
|-------|--------|
| Email | `medichain123@gmail.com` |
| Password | `MEDCLUES@123` |

### Dean Portal (one per hospital — hospital-scoped access)

| Hospital | Email | Password |
|----------|-------|----------|
| NovaCare Medical Center | `deannovacare@medclues.com` | `adminnova@medclues` |
| Zenith Multispecialty Hospital | `deanzenith@medclues.com` | `adminzenith@medclues` |
| Lifeline Advanced Hospitals | `deanlifeline@medclues.com` | `adminlifeline@medclues` |
| MediCore Health Institute | `deanmedicore@medclues.com` | `adminmedicore@medclues` |
| Apex Cure Hospitals | `deanapexcure@medclues.com` | `adminapex@medclues` |
| GreenLeaf Medical Center | `deangreenleaf@medclues.com` | `admingreen@medclues` |
| HealTrust Super Speciality Hospital | `deanhealtrust@medclues.com` | `adminhealthtrust@medclues` |
| UrbanCare Medical Institute | `deanurbancare@medclues.com` | `adminurbancare@medclues` |
| VitalEdge Hospitals | `deanvitaledge@medclues.com` | `adminvistaedge@medclues` |
| EverCare Health City | `deanevercare@medclues.com` | `adminevercare@medclues` |

### Doctor Portal (example)

| Field | Value |
|-------|--------|
| Email | `doc.arjith@medclues.com` |
| Password | `arjith@medclues` |

### Credential Reference Files (sensitive — do not commit publicly)

| File | Contents |
|------|----------|
| `fastapi_back/all_doctors_credentials.md` | All doctor emails/passwords by hospital |
| `fastapi_back/all_deans_credentials.md` | All dean portal credentials |

---

## Backend API Overview

Base URL: `http://localhost:5000` (or your LAN IP)

### Route Modules

| Prefix | Purpose |
|--------|---------|
| `/api/user` | Patient register/login, social-login, profile, appointments, Razorpay, health records, queue, emergency contacts, video consult |
| `/api/auth` | Forgot/verify/reset password (role-aware) |
| `/api/admin` | Super admin login, dashboard, doctors/deans/users CRUD, revenue, export |
| `/api/dean` | Dean login, hospital-scoped dashboard, doctors, appointments, patients |
| `/api/doctor` | Doctor login, appointments, queue, consultations, Agora tokens, slots |
| `/api/appointments` | Appointment lookup by booking ID |
| `/api/payments` | Razorpay order/create/verify, history, checkout |
| `/api/health-records` | Upload, list, delete patient records |
| `/api/hospital-tieup` | Hospital list, public, nearby, CRUD |
| `/api/lab` | Lab list, nearby, book, admin CRUD |
| `/api/blood-bank` | Blood bank list, nearby, admin CRUD |
| `/api/specialty` | Speciality helpline, public/all, CRUD |
| `/api/emergency` | `POST /send-alert` (SMS dev-mode) |
| `/api/ai` | Medical chat (stream), doctor-slots, appointment context |
| `/api/location` | Geocode, nearby hospitals |
| `/api/job-applications` | Career applications |
| `/api/charts` | Admin/dean/doctor chart data |
| `/api/otp` | Send/verify OTP |

### Auth Tokens

| Role | Token key | Login endpoint |
|------|-----------|----------------|
| Patient | JWT `token` | `POST /api/user/login` |
| Super Admin | `aToken` | `POST /api/admin/login` |
| Doctor | `dToken` | `POST /api/doctor/login` |
| Dean | `deanToken` | `POST /api/dean/login` |

Headers: `Authorization: Bearer <token>` and `token: <token>`

---

## Integrations

| Service | Used For | Config Keys |
|---------|----------|-------------|
| **PostgreSQL** | Primary database | `DATABASE_URL` |
| **Cloudinary** | Medical records, doctor images | `CLOUDINARY_*` |
| **Razorpay** | Online consultation payments | `RAZORPAY_KEY_ID/SECRET` |
| **Agora RTC** | Video consultations | `AGORA_APP_ID/CERTIFICATE` |
| **Brevo** | OTP emails, appointment confirmations | `BREVO_API_KEY` |
| **Firebase** | Google OAuth (all clients) | `FIREBASE_*` / `VITE_FIREBASE_*` |
| **Telegram Bot** | Patient notifications, appointments | `TELEGRAM_BOT_TOKEN` |
| **Mistral/Gemini/OpenAI** | AI medical chatbot | `MISTRAL_API_KEY`, `GEMINI_API_KEY` |
| **Google Maps** | Nearby hospitals, emergency location | Client-side geolocation + Maps links |

---

## Real-Time & Video

| Channel | Endpoint | Purpose |
|---------|----------|---------|
| Socket.IO | `/socket.io` | Admin/doctor live queue updates |
| WebSocket | `/payment-updates?appointmentId=...` | Payment status polling |
| Agora RTC | Token via `/api/doctor/agora-token` | Video consult rooms (web + mobile) |
| Google Meet | Fallback in `consultation_controller` | When Agora not configured |

---

## Emergency Services

Emergency is implemented at **three levels**:

| Client | Implementation |
|--------|----------------|
| **Flutter (`flutter_mobile/`)** | Full standalone module — login-independent, local storage, GPS, WhatsApp alerts, auto-SOS timer |
| **Web (`frontend/`)** | `/emergency` page with GPS, contacts, nearby hospitals, backend alert |
| **API** | `POST /api/emergency/send-alert` (SMS service, dev-log mode) |

### Flutter Emergency Module (full feature set)

- Emergency Help on splash, login, register, home, profile, settings
- Routes: `/emergency`, `/emergency/settings`, `/emergency/active` (no login required)
- Auto-SOS countdown (configurable, stops on any user action)
- Flows: Critical / Can Respond (symptoms) / Help Someone Else
- GPS live location (Google Maps link)
- Up to 2 relative contacts (SharedPreferences)
- WhatsApp message + live location (not WhatsApp calls)
- Regular phone calls to relatives
- Nearby hospitals, ambulance/police/fire (testing mode available)
- Local case history (last 50 cases)

Details: [flutter_mobile/README.md — Emergency Module](flutter_mobile/README.md#emergency-module)

---

## Scripts & Auxiliary Folders

| Path | Purpose |
|------|---------|
| `fastapi_back/start.ps1` | Quick backend start |
| `fastapi_back/scripts/` | Schema sync, credential docs, image uploads |
| `fastapi_back/scratch/` | DB debug/migration/populate utilities |
| `flutter_mobile/sync_env.ps1` | Sync API URL from Expo `.env` |
| `flutter_mobile/run_chrome.ps1` | Sync env + run on Chrome |
| `flutter_mobile/run_android_phone.ps1` | Auto LAN IP + run on USB phone |
| `mobile/scripts/sync-api-url.ps1` | Sync API URL for Expo |
| `scratch/` (root) | PPT generation, screenshots |
| `fastapi_back/AGORA_VIDEO.md` | Agora setup guide |
| `fastapi_back/TELEGRAM_BOT.md` | Telegram bot setup |
| `fastapi_back/README_PHONE.md` | Phone testing guide |

---

## Development Notes

- **Branding:** Flutter app is **MEDCLUES** with opening video splash (`assets/videos/opening.mp4`)
- **Primary mobile:** Use `flutter_mobile/` for new patient mobile development
- **API URL on devices:** Never use `localhost` on physical phones — use your PC's LAN IP
- **Emergency testing mode:** `EmergencyConstants.testingMode = true` in Flutter blocks ambulance/police/fire calls
- **JWT expiry:** ~7 days; no separate refresh endpoint — re-login on 401
- **Hot reload:** Flutter `r`/`R`; Vite HMR for web clients

---

## License & Security

- Keep all `.env` files and credential markdown files **out of public repositories**
- Healthcare data handled per MEDCLUES protocol standards
- Role-based access: patients, doctors, deans, and admins have isolated data scopes
- Dean accounts are restricted to their own hospital's doctors and patients
