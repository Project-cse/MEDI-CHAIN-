# MEDCLUES — Admin / Staff Web Panel

React + Vite single-page app for all **staff-facing** roles of the MEDCLUES platform: **Super Admin**, **Dean**, **Doctor**, and **Receptionist**. The patient-facing client is the separate Flutter app ([../flutter_mobile/README.md](../flutter_mobile/README.md)); this panel talks to the same FastAPI backend ([../fastapi_back](../fastapi_back)).

| Resource | URL |
|----------|-----|
| Production API | `https://medclues.onrender.com` |
| Local API | `http://localhost:5000` (docs at `/docs`) |
| Monorepo overview | [../README.md](../README.md) |
| Mobile app | [../flutter_mobile/README.md](../flutter_mobile/README.md) |

---

## What's New

- **Receptionist panel** — a complete, hospital-scoped reception desk under `admin/src/pages/Reception/` (dedicated `receptionist` role). Covers dashboard, online bookings, walk-in registration, QR check-in, queue, follow-ups, payments, refund requests, no-shows, consultation summary, patients, reports and settings.
- **One receptionist per hospital** — Deans (and Super Admin) create/manage receptionists; every reception API call is scoped to the receptionist's `hospital_id`, so each desk only ever sees its own hospital's data.
- **Unified queue tokens** — online (app) and walk-in (desk) appointments for the same doctor/day now share **one continuous token sequence** (`MAX(token_number)+1`).
- **Patients page (records view)** — lists every patient of the hospital with:
  - **Type** = strictly **Online** (booked from the app) or **Walk-in** (booked at the reception desk), driven by the new `appointment_source` column — independent of payment method.
  - **Payment Type** (Online / Cash / Card / UPI / Pay at desk) and **Paid / Unpaid** status.
  - **Cancelled** bookings get a red badge and are pushed to the bottom of the list.
  - A **calendar date filter** — pick a date to see only that day's patients; clear to see everyone.
- **Flattened navigation** — dropdown menus removed across Doctor, Dean and Super Admin sidebars.
- **Redesigns** — Dean Doctors directory, Add Doctor form (Admin + Dean), Dean Hospital tie-ups with banner upload, Doctor Dashboard (with availability status buttons), Doctor Profile, Doctor Appointments, and the Doctor video consult room (in-call chat + booking symptoms/reports).

---

## Tech Stack

| Area | Choice |
|------|--------|
| Framework | React 18 + Vite 5 |
| Routing | `react-router-dom` v6 |
| Styling | Tailwind CSS 3 (custom `reception` brand color) |
| HTTP | Axios (role-aware auth interceptor) |
| State | React Context API (`AdminContext`, `DeanContext`, `ReceptionContext`, Doctor context) |
| Charts | `chart.js` + `react-chartjs-2` |
| Exports | `jspdf`, `jspdf-autotable`, `xlsx` |
| Realtime / video | `socket.io-client`, `agora-rtc-sdk-ng` |
| Notifications | `react-toastify` |

---

## Quick Start

```bash
cd admin
npm install
npm run dev          # Vite dev server (default http://localhost:5173/5174)
```

Build & preview:

```bash
npm run build        # production build → dist/
npm run preview      # serve the production build locally
npm run lint         # eslint
```

### Backend URL

The panel reads the API base from the app config / context (`backendUrl`). For local development run the FastAPI backend on `http://localhost:5000`; for production it points to `https://medclues.onrender.com`. CORS on the backend allows the `token`, `dean-token`, `doctor-token`, `rectoken` / `reception-token` and `Authorization` headers.

---

## Roles & Login

All staff log in from a single screen (`src/pages/Login.jsx`) and select their role. Tokens are stored per-role and attached by `src/services/authInterceptor.js`.

| Role | Scope | Entry pages |
|------|-------|-------------|
| **Super Admin** | Entire platform | `src/pages/Admin/*` |
| **Dean** | One hospital | `src/pages/Dean/*` |
| **Doctor** | Own patients/queue | `src/pages/Doctor/*` |
| **Receptionist** | One hospital (desk) | `src/pages/Reception/*` |

> Live staff credentials (including one receptionist per hospital) are documented in the monorepo [../README.md](../README.md). Do not commit real secrets.

---

## Receptionist Panel

Folder: `src/pages/Reception/` · Context: `src/context/ReceptionContext.jsx` · API prefix: `/api/reception`.

| Screen | File | Purpose |
|--------|------|---------|
| Dashboard | `ReceptionDashboard.jsx` | Today's KPIs — online vs walk-in split, queue snapshot |
| Online Bookings | `OnlineBookings.jsx` | App bookings awaiting verification / token |
| Walk-In Registration | `WalkInRegistration.jsx` | Multi-step offline patient registration + booking |
| QR Check-In | `QRCheckIn.jsx` | Scan patient QR to mark arrival |
| Queue Management | `QueueManagement.jsx` | Unified per-doctor/day token queue |
| Patients | `Patients.jsx` | All hospital patients — type, payment, paid, cancelled, date filter |
| Follow-Ups | `FollowUps.jsx` | Eligible follow-up visits |
| Payments | `Payments.jsx` | Collect / record payments |
| Refund Requests | `RefundRequests.jsx` | Raise/track refunds |
| No-Shows | `NoShows.jsx` | Mark and review no-shows |
| Consultation Summary | `ConsultationSummary.jsx` | Post-visit summary prep |
| Reports / Settings | `Reports.jsx`, `Settings.jsx` | Desk reporting & preferences |
| Shared UI | `components.jsx` | `PageWrap`, `RcHeader`, `KpiTile`, `Avatar`, `Pill`, `Spinner`, formatters |

**Data isolation:** the backend derives `hospital_id` from the receptionist JWT; the panel never sends a hospital id, so a desk physically cannot read another hospital's records.

**Booking source (`appointment_source`):** every appointment is tagged `ONLINE` (app) or `WALK_IN` (reception). This powers the Patients "Type" column, the dashboard online/walk-in split, and the Online Bookings list — kept separate from payment status so an app booking paid at the desk still shows as **Online**.

### Receptionist management

| Manager | File |
|---------|------|
| Dean (own hospital) | `src/pages/Dean/ManageReceptionists.jsx` |
| Super Admin (all hospitals) | `src/pages/Admin/ManageReceptionists.jsx` |

Both support create, enable/disable, password reset and delete, scoped appropriately.

---

## Other Role Areas (highlights)

| Area | Notable pages |
|------|---------------|
| Super Admin | `Dashboard`, `DoctorsList`, `AllAppointments`, `ManageDeans`, `ManageAdmins`, `ManageUsers`, `HospitalTieUps`, `RevenueAnalytics`, `RefundManagement`, `ManageLabs`, `ManageBloodBanks`, `DeanPortals` |
| Dean | `DeanDashboard`, `DeanDoctors`, `DeanAddDoctor`, `DeanAppointments`, `DeanPatients`, `DeanHospital` (banner upload), `ManageReceptionists` |
| Doctor | `DoctorDashboard` (availability status), `DoctorAppointments`, `DoctorProfile`, `QueueManagement`, `DoctorVideoConsult` (in-call chat, symptoms + reports) |

Shared MediChain design-system components live in `src/components/mc/` (`AdminPageLayout`, `PageHero`, `KpiCard`, `FilterToolbar`, `McCard`, `StatusPill`, `LiveClock`).

---

## Project Structure

```
admin/
├── src/
│   ├── main.jsx                 # App bootstrap + context providers
│   ├── App.jsx                  # Routes for all roles
│   ├── index.css                # Tailwind entry
│   ├── components/
│   │   ├── Navbar.jsx, Sidebar.jsx
│   │   ├── AddDoctorForm.jsx
│   │   └── mc/                  # MediChain design system
│   ├── context/                 # AdminContext, DeanContext, ReceptionContext
│   ├── services/                # authApi, authInterceptor
│   └── pages/                   # Admin / Dean / Doctor / Reception
├── tailwind.config.js           # includes custom `reception` color
├── vite.config.js
└── package.json
```

---

## Notes

- Do not commit the build output (`dist/`) or any credential files.
- After adding new Tailwind colors/classes, restart the Vite dev server so they recompile.
- The backend must be running (local or Render) for the panel to load data.
