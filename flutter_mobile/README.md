# MEDCLUES — Flutter Mobile App

**Package:** `medichain_mobile` · **Version:** `1.0.0+1`  
**Brand:** MEDCLUES · **Tagline:** EMERGENCY | BOOKING

Flutter patient application for the MEDCLUES healthcare platform. Ported from the React Native Expo app (`mobile/`) with full API parity against `fastapi_back/`. Includes a **standalone Emergency Module** that operates without login.

**Platform overview:** [../README.md](../README.md)

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Environment & API Configuration](#environment--api-configuration)
4. [Run & Build](#run--build)
5. [Project Structure](#project-structure)
6. [Navigation & Routes](#navigation--routes)
7. [Authentication](#authentication)
8. [All Screens](#all-screens)
9. [Booking Flow](#booking-flow)
10. [Video Consultation](#video-consultation)
11. [Payments](#payments)
12. [Health Records](#health-records)
13. [Hospitals, Labs & Blood Banks](#hospitals-labs--blood-banks)
14. [Emergency Module](#emergency-module)
15. [State Management](#state-management)
16. [Services & API Layer](#services--api-layer)
17. [Widgets & UI System](#widgets--ui-system)
18. [Branding, Themes & Animations](#branding-themes--animations)
19. [Assets](#assets)
20. [Platform Support](#platform-support)
21. [Scripts & Tooling](#scripts--tooling)
22. [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| Flutter SDK | **3.3+** (Dart `>=3.3.0 <4.0.0`) |
| IDE | VS Code or Android Studio with Flutter extension |
| Backend | FastAPI on port **5000** (`fastapi_back/`) |
| Device | Android emulator, physical device, iOS simulator, or Chrome |

```bash
flutter doctor
```

---

## Quick Start

```bash
# 1. Dependencies
cd flutter_mobile
flutter pub get

# 2. Sync API URL from Expo mobile config
.\sync_env.ps1

# 3. Start backend (separate terminal)
cd ../fastapi_back
python -m uvicorn main:app --host 0.0.0.0 --port 5000 --reload

# 4. Run app
cd ../flutter_mobile
flutter run                  # default device
flutter run -d chrome        # web browser
flutter run -d <device_id>   # specific device
```

---

## Environment & API Configuration

### Config files

| File | Role |
|------|------|
| `sync_env.ps1` | Copies `EXPO_PUBLIC_API_URL` from `../mobile/.env` → `flutter_mobile/.env` as `API_BASE_URL` |
| `.env` | Local dev overrides (not bundled) |
| `.env.example` | Template |
| `assets/config.env` | Bundled fallback — **required for web** (dotfiles 404 in browser) |

### Load order (`main.dart`)

1. `assets/config.env`
2. `.env`
3. `--dart-define` overrides

### Environment keys

| Key | Purpose |
|-----|---------|
| `API_BASE_URL` | FastAPI URL for Android/iOS (from Expo sync) |
| `API_BASE_URL_WEB` | API URL for Chrome/web (default `http://localhost:5000`) |
| `EXPO_PUBLIC_API_URL` | Fallback alias read by `ApiConfig` |
| `AGORA_APP_ID` | Agora video consult app ID |
| `GOOGLE_WEB_CLIENT_ID` | Google OAuth server client ID |
| `FIREBASE_API_KEY_WEB` | Firebase web API key |
| `FIREBASE_APP_ID_WEB` | Firebase web app ID |
| `FIREBASE_API_KEY_IOS` | Firebase iOS API key |
| `FIREBASE_APP_ID_IOS` | Firebase iOS app ID (required for iOS Google Sign-In) |
| `FIREBASE_MESSAGING_SENDER_ID` | Firebase sender ID |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_STORAGE_BUCKET` | Firebase storage bucket |
| `FIREBASE_AUTH_DOMAIN` | Firebase auth domain (web) |
| `FIREBASE_MEASUREMENT_ID` | Firebase analytics (web) |
| `TELEGRAM_BOT_TOKEN` | Telegram integration check (prefer backend-only) |

### Platform API defaults

| Target | `API_BASE_URL` |
|--------|----------------|
| Android emulator | `http://10.0.2.2:5000` |
| iOS simulator | `http://localhost:5000` |
| Physical phone (same Wi‑Fi) | `http://<YOUR_PC_LAN_IP>:5000` |
| Chrome (web) | `http://localhost:5000` (via `API_BASE_URL_WEB`) |

**Never use `localhost` on a physical phone** — use your PC's LAN IP.

---

## Run & Build

### Development

```bash
flutter run
flutter run -d chrome
.\run_chrome.ps1          # sync env + chrome
.\run_android_phone.ps1   # auto LAN IP + USB phone
```

### Release builds

```bash
# Android APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Android App Bundle (Play Store)
flutter build appbundle --release

# Web
flutter build web
```

### Analyze

```bash
flutter analyze
```

---

## Project Structure

```
flutter_mobile/
├── lib/
│   ├── main.dart                    # Entry: env load, Firebase init, MedcluesApp
│   ├── firebase_options.dart        # Platform Firebase config
│   │
│   ├── config/                      # AppConfig, ApiConfig
│   ├── constants/                   # Colors, typography, strings, icons, dimensions
│   ├── brand/                       # MEDCLUES palette, typography, logo painter, login transition
│   ├── themes/                      # Light/dark Material 3, form styles
│   │
│   ├── models/                      # 14 data models (doctor, appointment, patient, etc.)
│   ├── helpers/                     # StorageHelper, TokenHelper, PermissionHelper
│   ├── utils/                       # Validators, formatters, JSON parser, file openers
│   │
│   ├── services/                    # 14 Dio API services
│   ├── repositories/                # 5 data repositories
│   ├── providers/                   # 12 Riverpod provider files
│   │
│   ├── routes/
│   │   ├── route_names.dart         # Named route constants
│   │   ├── app_router.dart          # go_router + auth redirect + DashboardShell
│   │   └── router_refresh.dart      # Auth-driven router refresh
│   │
│   ├── screens/                     # 35 routed UI screens (see All Screens)
│   │
│   ├── features/
│   │   └── emergency/               # Standalone emergency module (see Emergency Module)
│   │       ├── models/              # Contact, case, settings models
│   │       ├── services/            # Storage, GPS, SOS timer, WhatsApp notify
│   │       ├── providers/           # Emergency Riverpod state
│   │       ├── screens/             # Access, active, settings
│   │       ├── widgets/             # Help button, action buttons, WhatsApp panel
│   │       ├── utils/               # Navigation, symptom classification
│   │       └── emergency_constants.dart
│   │
│   └── widgets/                     # Shared UI components (see Widgets section)
│
├── assets/
│   ├── images/                      # Logos, speciality icons (12 PNGs)
│   ├── images/specialities/web/     # SVG/PNG web variants
│   ├── videos/opening.mp4           # Splash opening video
│   ├── animations/                  # Lottie (success, ambulancia)
│   ├── icons/                       # logo.svg
│   └── config.env                   # Bundled env for web
│
├── android/                         # google-services.json, MainActivity
├── ios/                             # GoogleService-Info.plist
├── web/                             # index.html, manifest.json, PWA icons
├── windows/ / macos/ / linux/       # Desktop scaffolding (secondary)
│
├── sync_env.ps1
├── run_chrome.ps1
├── run_android_phone.ps1
├── pubspec.yaml
└── README.md
```

---

## Navigation & Routes

### Bottom navigation shell (`DashboardShell`)

| Tab | Route | Screen |
|-----|-------|--------|
| Home | `/dashboard` | `DashboardScreen` |
| Appointments | `/appointments` | `UpcomingAppointmentsScreen` |
| Records | `/records` | `RecordsScreen` |
| Profile | `/profile` | `ProfileScreen` |

### All routes

| Route | Screen | Auth required |
|-------|--------|---------------|
| `/` | Splash (opening video) | No |
| `/login` | Login | No |
| `/signup` | Signup wizard | No |
| `/forgot-password` | Forgot password OTP | No |
| `/dashboard` | Patient home | Yes |
| `/specialities` | Specialities list | Yes |
| `/search` | Home search | Yes |
| `/doctors` | Doctors list (`?speciality=`) | Yes |
| `/doctors/search` | Doctor search | Yes |
| `/doctors/:id` | Doctor profile | Yes |
| `/booking/patient/:doctorId` | Patient selector (For Me/Others) | Yes |
| `/booking/:doctorId` | Booking wizard (`?visit=online`) | Yes |
| `/booking/confirmation` | Booking confirmation + receipt | Yes |
| `/booking/success` | Booking success celebration | Yes |
| `/booking/receipt/:id` | Standalone receipt | Yes |
| `/appointments` | Appointments tabs | Yes |
| `/appointments/:id` | Appointment detail | Yes |
| `/video-consult/:appointmentId` | Agora video room | Yes |
| `/hospitals` | Hospitals list | Yes |
| `/hospitals/:id` | Hospital detail | Yes |
| `/labs` | Labs list | Yes |
| `/blood-banks` | Blood banks list | Yes |
| `/blood-banks/:id` | Blood bank detail | Yes |
| `/records` | Health records | Yes |
| `/notifications` | Notifications feed | Yes |
| `/profile` | Profile hub | Yes |
| `/personal-info` | Edit personal info | Yes |
| `/address` | Patient address | Yes |
| `/payment-history` | Payment history | Yes |
| `/payment-methods` | Payment methods info | Yes |
| `/help` | Help & support | Yes |
| `/about` | About app | Yes |
| `/terms` | Terms & conditions | Yes |
| `/settings` | App settings (dark mode) | Yes |
| `/emergency` | Emergency access | **No** |
| `/emergency/settings` | Emergency settings | **No** |
| `/emergency/active` | Emergency active SOS | **No** |

### Auth redirect rules

- Emergency routes (`/emergency*`) **always bypass** login redirect
- Authenticated users on splash/login/signup → redirect to `/dashboard`
- Unauthenticated users on protected routes → redirect to `/login`
- 401 API response → clear token → redirect to login

---

## Authentication

### Flow

```
Splash (/) → checkAuth() → authenticated? → /dashboard
                          → not authenticated → /login
```

### Methods

| Method | Endpoint / Flow |
|--------|----------------|
| Email/password login | `POST /api/user/login` |
| Registration | `POST /api/user/register` → auto-login |
| Google Sign-In | Firebase Auth → `POST /api/user/social-login` |
| Forgot password | `POST /api/auth/forgot-password` → verify OTP → reset |
| Session restore | Read JWT from secure storage → validate expiry → fetch profile |
| Logout | Clear secure storage + Google sign-out |

### Google Sign-In platform behavior

| Platform | Method |
|----------|--------|
| Web | Firebase `signInWithPopup(GoogleAuthProvider)` |
| Android/iOS | `google_sign_in` → Firebase credential → backend social-login |

### Token handling

- **Storage:** `flutter_secure_storage` via `StorageHelper`
- **Headers:** `Authorization: Bearer <token>` + `token: <token>`
- **Expiry:** JWT `exp` claim (~7 days); cleared on 401
- **No refresh endpoint** — re-login required after expiry

### Firebase files

| File | Platform |
|------|----------|
| `lib/firebase_options.dart` | All platforms |
| `android/app/google-services.json` | Android |
| `ios/Runner/GoogleService-Info.plist` | iOS |

---

## All Screens

### Splash & Auth

| Screen | File | Features |
|--------|------|----------|
| Splash | `splash/splash_screen.dart` | Opening video (`opening.mp4`), logo fallback, floating SOS, auth handoff |
| Login | `auth/login_screen.dart` | Email/password, Google Sign-In, forgot password sheet, emergency help |
| Signup | `auth/signup_screen.dart` | 4-step wizard, Google Sign-In, validation shake, success celebration |
| Forgot Password | `auth/forgot_password_screen.dart` | Email → OTP → new password |

### Home & Discovery

| Screen | File | Features |
|--------|------|----------|
| Dashboard | `dashboard/dashboard_screen.dart` | Greeting, inline search, speciality grid, top doctors, quick-access, drawer, emergency help |
| Home Search | `search/home_search_screen.dart` | Full-screen search (doctors, specialities, services) |
| Specialities | `specialities/specialities_screen.dart` | All medical specialities from API |

### Doctors

| Screen | File | Features |
|--------|------|----------|
| Doctors List | `doctors/doctors_list_screen.dart` | Filter (all/available/rating/experience), speciality query param |
| Search Doctors | `doctors/search_doctors_screen.dart` | Text search |
| Doctor Profile | `doctors/doctor_profile_screen.dart` | Fees, hospital, in-person + online booking, video consult card |

### Booking

| Screen | File | Features |
|--------|------|----------|
| Patient Selector | `booking/booking_patient_selector_screen.dart` | "For Me" / "For Others" |
| Booking | `booking/booking_screen.dart` | Week/day slots, visit type, symptoms, report upload, Razorpay |
| Booking Success | `booking/booking_success_screen.dart` | Celebration animation + booking ID |
| Booking Confirmation | `booking/booking_confirmation_screen.dart` | Receipt card, PDF/share, join video call |
| Booking Receipt | `booking/booking_receipt_screen.dart` | Standalone receipt by appointment ID |

### Appointments & Consultation

| Screen | File | Features |
|--------|------|----------|
| Appointments | `appointments/upcoming_appointments_screen.dart` | Tabs: Upcoming / Completed / Cancelled |
| Appointment Detail | `appointments/appointment_detail_screen.dart` | Detail, cancel, join video |
| Video Consult | `consultation/video_consult_screen.dart` | Agora RTC, mute/camera, timer, end call |

### Hospitals, Labs, Blood Banks

| Screen | File | Features |
|--------|------|----------|
| Hospitals List | `hospitals/hospitals_list_screen.dart` | All + nearby (GPS) toggle, search |
| Hospital Detail | `hospitals/hospital_details_screen.dart` | Profile + affiliated doctors |
| Labs List | `labs/labs_list_screen.dart` | Searchable diagnostic labs |
| Blood Banks List | `labs/blood_banks_list_screen.dart` | Searchable blood bank directory |
| Blood Bank Detail | `labs/blood_bank_detail_screen.dart` | Blood-type availability circles |

### Records, Notifications, Profile

| Screen | File | Features |
|--------|------|----------|
| Records | `records/records_screen.dart` | Upload (file picker), list, view PDF/images |
| Notifications | `notifications/notifications_screen.dart` | Appointment-derived feed, read state |
| Profile | `profile/profile_screen.dart` | Photo upload, menu hub, emergency help, logout |
| Personal Info | `profile/personal_info_screen.dart` | Name, phone, gender, DOB, photo |
| Address | `profile/address_screen.dart` | Patient address fields |
| Payment History | `profile/payment_history_screen.dart` | Razorpay payment cards |
| Payment Methods | `profile/payment_methods_screen.dart` | Online (Razorpay) vs in-clinic info |
| Help | `profile/help_screen.dart` | FAQ content |
| About | `profile/about_screen.dart` | App information |
| Terms | `profile/terms_screen.dart` | Terms sections |
| Settings | `settings/settings_screen.dart` | Dark mode, emergency settings, emergency help |

### Emergency (feature module)

| Screen | File | Features |
|--------|------|----------|
| Emergency Access | `features/emergency/screens/emergency_access_screen.dart` | Auto-SOS timer, critical/respond/helper flows |
| Emergency Settings | `features/emergency/screens/emergency_settings_screen.dart` | Contacts, medical info, SOS prefs |
| Emergency Active | `features/emergency/screens/emergency_active_screen.dart` | Post-SOS actions, WhatsApp, calls, maps |

### Legacy (not routed)

| Screen | File | Note |
|--------|------|------|
| Emergency (old) | `screens/emergency/emergency_screen.dart` | Superseded by `features/emergency/` |
| Placeholder | `screens/common/placeholder_screen.dart` | "Coming soon" scaffold |

---

## Booking Flow

```
Doctor Profile (/doctors/:id)
    │
    ▼
Patient Selector (/booking/patient/:doctorId)
    "For Me" or "For Others"
    │
    ▼
Booking Screen (/booking/:doctorId[?visit=online])
    ├── Load doctor + week/day slots
    ├── Select visit type (In-Person / Online)
    ├── Optional symptoms + report file upload
    ├── Payment: Razorpay for online visits
    │             Direct book for in-clinic
    └── POST /api/user/book-appointment
    │
    ▼
Booking Success (/booking/success)
    Celebration + booking ID
    │
    ▼
Booking Confirmation (/booking/confirmation)
    or Receipt (/booking/receipt/:id)
    ├── Receipt card with QR
    ├── PDF generate + share
    └── "Join Video Call" → /video-consult/:id (if online)
```

**State providers:** `bookingPatientProvider`, `bookingDraftProvider`, `bookingInProgressProvider`

---

## Video Consultation

| Item | Detail |
|------|--------|
| Screen | `consultation/video_consult_screen.dart` |
| Route | `/video-consult/:appointmentId` |
| SDK | `agora_rtc_engine` |
| Token | `POST /api/doctor/agora-token` (via `consultation_service.dart`) |
| Features | Connecting overlay, mute/camera toggles, call duration, remote presence, end call |
| Config | `AGORA_APP_ID` in env |
| Entry points | Appointment detail, booking confirmation, doctor profile (online path) |

---

## Payments

| Item | Detail |
|------|--------|
| Gateway | Razorpay |
| Service | `payment_service.dart` |
| Endpoints | create-order, verify, confirm-order, failed, status, checkout, razorpay-key |
| Booking | Online visits trigger Razorpay checkout in `booking_screen.dart` |
| History | `payment_history_screen.dart` via `paymentHistoryProvider` |
| Methods info | `payment_methods_screen.dart` (informational) |

---

## Health Records

| Item | Detail |
|------|--------|
| Screen | `records/records_screen.dart` (bottom-nav tab) |
| Service | `health_record_service.dart` |
| Endpoints | List, upload, view URL, file download |
| Provider | `healthRecordsProvider` |
| File handling | `report_file_opener.dart` (IO + web implementations) |
| PDF receipts | `appointment_receipt_pdf.dart` |

---

## Hospitals, Labs & Blood Banks

### Hospitals

| Item | Detail |
|------|--------|
| Service | `hospital_service.dart` |
| Endpoints | List, details, nearby via `/api/location/nearby-hospitals` |
| Screens | `hospitals_list_screen.dart`, `hospital_details_screen.dart` |
| Providers | `hospitalsListProvider`, `hospitalDetailProvider` |
| Features | All hospitals + nearby GPS toggle |

### Labs

| Item | Detail |
|------|--------|
| Service | `lab_service.dart` |
| Endpoint | `GET /api/lab/list` |
| Screen | `labs_list_screen.dart` with search |

### Blood Banks

| Item | Detail |
|------|--------|
| Service | `blood_bank_service.dart` |
| Endpoint | `GET /api/blood-bank/list` |
| Screens | `blood_banks_list_screen.dart`, `blood_bank_detail_screen.dart` |
| Widgets | `blood_bank_card.dart`, `blood_drop_icon.dart`, `blood_type_circle_tile.dart` |
| Navigation | Detail requires `BloodBankModel` passed via `extra` |

---

## Emergency Module

**Location:** `lib/features/emergency/`  
**Works without login** — all `/emergency*` routes bypass auth redirect.

### Access points

Emergency Help button (`EmergencyHelpButton`) on:
- Opening splash (floating SOS, `replaceRoute: true`)
- Login screen
- Register screen
- Patient Home (dashboard)
- Profile screen
- Settings screen

Dashboard quick-access tile also links to `/emergency`.

### Routes

| Route | Screen | Purpose |
|-------|--------|---------|
| `/emergency` | Emergency Access | Countdown + response options |
| `/emergency/settings` | Emergency Settings | Contacts, medical info, SOS prefs |
| `/emergency/active` | Emergency Active | Post-SOS actions |

### SOS flow

```
Emergency Access
    │
    ├── Auto-SOS timer (default 30s, configurable)
    │   └── Timer STOPS on any user action
    │   └── If no action → auto critical SOS
    │
    ├── "I Am Critical"
    │   └── Immediate SOS → Emergency Active
    │
    ├── "I Can Respond"
    │   └── Symptom picker → severity classification
    │       ├── Critical → ambulance, WhatsApp, hospitals
    │       ├── Moderate → video doctor, hospitals, WhatsApp
    │       └── Minor → book normal consultation
    │
    └── "Help Someone Else"
        └── Helper severity (Critical / Moderate / Minor)
```

### Symptom classification

| Severity | Symptoms |
|----------|----------|
| **Critical** | Chest Pain, Breathing Difficulty, Heavy Bleeding, Accident, Stroke Symptoms |
| **Moderate** | Severe Pain, Fever |
| **Minor** | Other |

### Emergency Settings (local storage)

| Field | Required |
|-------|----------|
| Relative Contact 1 — Name | Yes (with phone) |
| Relative Contact 1 — Phone | Yes (with name) |
| Relative Contact 2 — Name | Yes (with phone) |
| Relative Contact 2 — Phone | Yes (with name) |
| Blood Group | Optional |
| Allergies | Optional |
| Existing Diseases | Optional |
| Current Medications | Optional |
| Auto SOS Timer | 10–120 seconds (slider) |
| Voice SOS | Toggle (preference stored) |
| Triple Tap SOS | Toggle (preference stored) |
| Shake SOS | Toggle (preference stored) |
| Auto Location Sharing | Toggle (default on) |

**Storage:** SharedPreferences keys `emergency_settings_v1`, `emergency_cases_v1`

### Notify relatives

| Action | Method |
|--------|--------|
| WhatsApp message + live location | `wa.me` with pre-filled alert + Google Maps link |
| Phone call to relative | System dialer (`tel:`) |
| No contacts saved | System share sheet fallback |

**WhatsApp is for messages and location links only — not WhatsApp voice calls.**

### Emergency Active screen actions

| Action | Notes |
|--------|-------|
| WhatsApp Location Alert | Send to first saved relative |
| Notify Relatives panel | Per-contact WhatsApp message + phone call buttons |
| Call Ambulance (108) | Disabled in testing mode |
| Call Police (100/112) | Disabled in testing mode |
| Call Fire (101) | Disabled in testing mode |
| Nearby Hospitals | Google Maps search with GPS |
| Open My Location | Google Maps link |
| Emergency Video Doctor | Links to `/doctors?visit=online` (moderate severity) |
| Book Normal Consultation | Links to `/doctors` (minor severity) |
| Home button | Dashboard (logged in) or Login (guest) |

### Default emergency numbers

| Service | Number |
|---------|--------|
| Ambulance | 108 |
| Police | 100 / 112 |
| Fire | 101 |

### Testing mode

In `lib/features/emergency/emergency_constants.dart`:

```dart
static const testingMode = true;  // set false for production
```

When `true`: ambulance/police/fire `tel:` calls blocked with toast message. WhatsApp, GPS, relative calls, hospitals, and booking still work.

### Emergency architecture files

| Type | Files |
|------|-------|
| Models | `emergency_contact_model.dart`, `emergency_case_model.dart`, `emergency_settings_model.dart` |
| Services | `emergency_storage_service.dart`, `emergency_location_service.dart`, `emergency_notification_service.dart`, `emergency_sos_timer_service.dart` |
| Providers | `emergency_provider.dart` |
| Screens | `emergency_access_screen.dart`, `emergency_settings_screen.dart`, `emergency_active_screen.dart` |
| Widgets | `emergency_help_button.dart`, `emergency_action_button.dart`, `emergency_home_button.dart`, `emergency_whatsapp_contacts_panel.dart` |
| Utils | `emergency_navigation.dart`, `emergency_symptom_utils.dart` |

---

## State Management

### Riverpod providers

| Provider file | Key providers |
|---------------|---------------|
| `auth_provider.dart` | `authProvider` (loading/authenticated/unauthenticated/error) |
| `theme_provider.dart` | `themeModeProvider` (light/dark, persisted) |
| `booking_state_provider.dart` | `bookingDraftProvider`, `bookingPatientProvider` |
| `appointment_provider.dart` | Upcoming/past/cancelled/detail, slots, tab state |
| `doctor_provider.dart` | All doctors, top doctors, list, detail, speciality filter |
| `speciality_provider.dart` | `specialitiesProvider` |
| `patient_provider.dart` | `patientProfileProvider` |
| `hospital_provider.dart` | Hospitals list, detail |
| `payment_provider.dart` | `paymentHistoryProvider` |
| `health_record_provider.dart` | `healthRecordsProvider` |
| `notification_provider.dart` | Notifications + read state |
| `service_providers.dart` | All service/repository instances |
| `emergency_provider.dart` | Settings, session, storage, location, notification |

---

## Services & API Layer

### Services (`lib/services/`)

| Service | Purpose |
|---------|---------|
| `api_service.dart` | Dio HTTP client, JWT headers, 401 handling, debug logging |
| `auth_service.dart` | Login, signup, forgot/reset password, social login, profile |
| `google_auth_service.dart` | Firebase + Google Sign-In (web popup, mobile SDK) |
| `appointment_service.dart` | Book, cancel, list appointments, fetch slots |
| `consultation_service.dart` | Agora token, video status/timer, end call |
| `doctor_service.dart` | Doctor list, search, by ID |
| `speciality_service.dart` | Public specialities |
| `patient_service.dart` | Patient profile CRUD + photo upload |
| `payment_service.dart` | Razorpay order/verify/history/checkout |
| `health_record_service.dart` | List/upload/view health records |
| `hospital_service.dart` | Hospital list, details, nearby |
| `lab_service.dart` | Lab list |
| `blood_bank_service.dart` | Blood bank list |
| `notification_service.dart` | Derives notifications from appointments |
| `integration_service.dart` | Checks Agora/Telegram config availability |

### Repositories (`lib/repositories/`)

| Repository | Wraps |
|------------|-------|
| `auth_repository.dart` | Login, signup, Google, token storage, session, logout |
| `appointment_repository.dart` | Appointments, slots, book, cancel |
| `doctor_repository.dart` | Doctor data |
| `speciality_repository.dart` | Speciality data |
| `patient_repository.dart` | Patient profile + photo |

### Key API endpoints

| Action | Method & Path |
|--------|---------------|
| Login | `POST /api/user/login` |
| Register | `POST /api/user/register` |
| Google login | `POST /api/user/social-login` |
| Profile | `GET /api/user/get-profile`, `PATCH /api/user/profile` |
| Doctors | `GET /api/doctor/list`, `GET /api/doctor/{id}` |
| Public doctors | `GET /api/hospital-tieup/public/doctors` |
| Specialities | `GET /api/specialty/public/all` |
| Slots | `GET /api/ai/doctor-slots/{docId}` |
| Book | `POST /api/user/book-appointment` |
| Appointments | `GET /api/user/appointments` |
| Cancel | `POST /api/user/cancel-appointment` |
| Health records | `/api/health-records/*` |
| Hospitals | `/api/hospital-tieup/*`, `/api/location/nearby-hospitals` |
| Labs | `GET /api/lab/list` |
| Blood banks | `GET /api/blood-bank/list` |
| Payments | `/api/payments/*` |
| Forgot password | `POST /api/auth/forgot-password`, verify, reset |
| Agora token | Via consultation service |
| Config | `GET /api/config/integrations` |

Emergency data is **local only** — no backend required for SOS.

---

## Widgets & UI System

### By category (`lib/widgets/`)

| Folder | Widgets | Purpose |
|--------|---------|---------|
| `animations/` | 14 widgets | Morphing buttons, wizard progress, receipt unroll, success celebration, healthcare motion, validation shake |
| `auth/` | 8 widgets | Auth input, brand logo, login shell, Google button, forgot password sheet |
| `blood/` | 2 widgets | Blood drop icon, blood type circle tile |
| `booking/` | 1 widget | Appointment receipt card |
| `brand/` | 1 widget | MEDCLUES logo image (auth/large/compact sizes) |
| `cards/` | 4 widgets | Appointment, blood bank, doctor, speciality cards |
| `common/` | 8 widgets | Button, loader, snackbar, text field, avatar, empty/error states |
| `home/` | 5 widgets | Search bar, search results, speciality grid, top doctor cards |
| `layout/` | 1 widget | Patient drawer |
| `skeleton/` | 2 widgets | Appointment and doctor card shimmer loaders |
| `splash/` | 2 widgets | Fullscreen splash video, mobile fit video |

### Data models (`lib/models/`)

`api_response_model`, `appointment_model`, `blood_bank_model`, `doctor_model`, `hospital_detail_model`, `hospital_model`, `lab_model`, `notification_model`, `patient_booking_info`, `patient_model`, `payment_history_item`, `slot_model`, `speciality_model`, `user_model`

---

## Branding, Themes & Animations

### Brand identity

| Item | Value |
|------|-------|
| App name | MEDCLUES |
| Tagline | EMERGENCY \| BOOKING |
| Logo | `assets/images/medclues_logo.png` |
| Opening video | `assets/videos/opening.mp4` (1080×1920 portrait, H.264) |
| Splash background | `#F5F5F5` |
| Primary font | Poppins (Google Fonts, runtime) |

### Brand files (`lib/brand/`)

- `medclues_palette.dart` — Navy, teal, emergency reds, splash canvas
- `medclues_brand_typography.dart` — Brand text styles
- `medclues_logo_widget.dart` / `medclues_logo_painter.dart` — Programmatic logo
- `medclues_login_transition.dart` — Shared-axis login page transition

### Themes (`lib/themes/`)

- `light_theme.dart` — Material 3 light
- `dark_theme.dart` — Material 3 dark
- `theme_form_styles.dart` — Shared form field styling
- Toggle: Settings screen → `themeModeProvider` (persisted)

### Animation packages

| Package | Usage |
|---------|-------|
| `flutter_animate` | Premium toast, UI micro-animations |
| `lottie` | Success checkmark, ambulancia |
| `rive` | Advanced animations |
| `animations` | Shared-axis page transitions (signup wizard) |

### UI motion highlights

- Signup 4-step wizard with horizontal slide transitions
- Booking receipt unroll animation
- Success celebration (Lottie checkmark)
- Connecting doctor overlay (video consult)
- Heartbeat logo, signal pulse painter
- Healthcare motion backgrounds on auth screens
- Morphing login button (idle → loading → success)

---

## Assets

| Asset | Path |
|-------|------|
| App logo | `assets/images/medclues_logo.png` |
| App icons | `assets/images/icon.png`, `adaptive-icon.png`, `splash-icon.png`, `favicon.png` |
| Opening video | `assets/videos/opening.mp4` |
| Speciality icons (12) | `assets/images/specialities/` — cardiology, orthopedics, psychiatry, ophthalmology, ENT, dentistry, general medicine, gynecology, dermatology, pediatrics, neurology, gastroenterology |
| Web speciality variants | `assets/images/specialities/web/` |
| Lottie animations | `assets/animations/success_checkmark.lottie`, `ambulancia.lottie` |
| SVG logo | `assets/icons/logo.svg` |
| Bundled env | `assets/config.env` |

---

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| **Android** | Primary | `google-services.json`, release APK/AAB |
| **iOS** | Primary | `GoogleService-Info.plist`, needs `FIREBASE_APP_ID_IOS` |
| **Web (Chrome)** | Supported | `assets/config.env` required; `WebSafeMediaQuery` wrapper |
| Windows | Scaffolded | Desktop build possible |
| macOS | Scaffolded | Desktop build possible |
| Linux | Scaffolded | Desktop build possible |

### Platform-specific code

- `utils/report_file_opener_io.dart` / `report_file_opener_web.dart`
- `utils/web_safe_media_query.dart`
- Firebase: always on Android; conditional on web/iOS via env

### Permissions

- **Location:** `ACCESS_FINE_LOCATION` (Android), `NSLocationWhenInUseUsageDescription` (iOS) — emergency GPS
- **Camera/Mic:** Video consult via `permission_helper.dart`

---

## Scripts & Tooling

| Script | Command | Purpose |
|--------|---------|---------|
| `sync_env.ps1` | `.\sync_env.ps1` | Sync `API_BASE_URL` from `mobile/.env` |
| `run_chrome.ps1` | `.\run_chrome.ps1` | Sync env + `flutter run -d chrome` |
| `run_android_phone.ps1` | `.\run_android_phone.ps1` | Auto-detect LAN IP → update `assets/config.env` → run on USB phone |
| `flutter analyze` | — | Static analysis |
| `flutter test` | — | Widget tests (`test/widget_test.dart`) |

### Firebase / Google config files

| File | Platform |
|------|----------|
| `lib/firebase_options.dart` | Generated Firebase options |
| `android/app/google-services.json` | Android Firebase |
| `ios/Runner/GoogleService-Info.plist` | iOS Firebase |

---

## Troubleshooting

### Cannot reach API from phone

- Backend: `python -m uvicorn main:app --host 0.0.0.0 --port 5000 --reload`
- Phone and PC on same Wi‑Fi
- Use LAN IP in `.env`, not `localhost`
- Re-run `.\sync_env.ps1` after changing `mobile/.env`
- For USB phone: run `.\run_android_phone.ps1`

### Emergency contacts not saving

- Both **name and phone** required per contact
- Tap **Save Settings** — confirm toast: `Settings saved — N relative contact(s) stored`
- Data persists in SharedPreferences across restarts

### Auto-SOS timer issues

- Timer stops on any button tap, settings open, back, or home
- Banner shows **"Timer stopped"** when cancelled
- From splash, emergency uses `replaceRoute` so video won't redirect you away

### Google Sign-In fails

- Check Firebase config files exist for your platform
- Web: `FIREBASE_API_KEY_WEB`, `GOOGLE_WEB_CLIENT_ID`
- iOS: `FIREBASE_APP_ID_IOS` required
- Android: `google-services.json` + SHA-1 in Firebase console

### Video consult won't connect

- Verify `AGORA_APP_ID` in env
- Check `GET /api/config/integrations` returns Agora as available
- Grant camera/microphone permissions

### RenderFlex overflow

- Reduce system font scale or use taller device
- Symptom/helper lists use scrollable `ListView`

### Web limitations

- GPS requires browser permission (HTTPS or localhost)
- WhatsApp opens `wa.me` in new tab
- Some native features (tel:, file picker) behave differently

---

## Related Documentation

| Document | Location |
|----------|----------|
| Platform overview | [../README.md](../README.md) |
| Expo mobile app | [../mobile/README.md](../mobile/README.md) |
| Google Sign-In (Expo) | [../mobile/GOOGLE_SIGNIN.md](../mobile/GOOGLE_SIGNIN.md) |
| Backend API docs | `http://localhost:5000/docs` |
| Agora setup | [../fastapi_back/AGORA_VIDEO.md](../fastapi_back/AGORA_VIDEO.md) |
| Telegram bot | [../fastapi_back/TELEGRAM_BOT.md](../fastapi_back/TELEGRAM_BOT.md) |
| Phone testing | [../fastapi_back/README_PHONE.md](../fastapi_back/README_PHONE.md) |

---

## License

Part of the MEDCLUES / PMS FNL 2 healthcare platform. Keep API keys, `.env` files, and credential documents private.
