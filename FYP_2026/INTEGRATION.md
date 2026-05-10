# FYP_2026 — Backend Integration Guide

## What Changed

The dashboard was originally built on **@base44/sdk** (a no-code backend).
It is now fully integrated with our **Django DRF backend** (`itms_backend`).

### Files replaced / added

| File | Change |
|------|--------|
| `src/api/base44Client.js` | Replaced with stub (no-op) |
| `src/lib/app-params.js` | Replaced with stub |
| `src/lib/AuthContext.jsx` | Full rewrite — Django JWT auth |
| `src/store/authStore.js` | **NEW** — Zustand store for JWT tokens |
| `src/api/client.js` | **NEW** — Axios instance with auto-refresh |
| `src/api/auth.js` | **NEW** — Login, logout, me, OTP, reset |
| `src/api/admin.js` | **NEW** — All admin panel API calls |
| `src/api/developer.js` | **NEW** — All developer panel API calls |
| `src/api/websocket.js` | **NEW** — WebSocket manager (violations feed, alerts, AI session, traffic signals) |
| `src/pages/Login.jsx` | **NEW** — Login page (no base44 redirect) |
| `src/App.jsx` | Updated routing — /login, / with auth guard |
| `vite.config.js` | Removed @base44/vite-plugin, added Django proxy |
| `package.json` | Removed @base44/sdk, added axios + zustand |
| `src/pages/admin/Dashboard.jsx` | + Real backend summary stats |
| `src/pages/admin/Analytics.jsx` | + Backend violation/fine/compliance analytics |
| `src/pages/admin/ViolationsCenter.jsx` | Full rewrite — real Django violations API + WebSocket feed |
| `src/pages/admin/LiveTrafficControl.jsx` | + Backend intersections + signal override API |
| `src/pages/admin/PunishmentSystem.jsx` | Full rewrite — real violations/fines/disputes API |
| `src/pages/admin/Settings.jsx` | + Backend settings API |
| `src/pages/developer/AISimulationLab.jsx` | + Backend AI session management + WebSocket |
| `src/pages/developer/ParameterControl.jsx` | + Push RL params to live backend session |
| `src/pages/developer/SystemLogs.jsx` | + Toggle simulation vs backend logs |
| `src/pages/developer/PerformanceComparison.jsx` | + Backend historical sessions table |
| `src/components/layout/Topbar.jsx` | Shows real user name/role, logout button |

## Quick Start

### 1. Start the Django backend first

```bash
cd itms_backend
./setup_and_run.sh        # First run — full setup
# Or: daphne -b 0.0.0.0 -p 8000 itms_backend.asgi:application
```

### 2. Start the React dashboard

```bash
cd FYP_2026
npm install
npm run dev
```

Opens at http://localhost:5173

### 3. Login

Use any of the seeded accounts:

| Role | Username | Password |
|------|----------|----------|
| Admin | admin | admin123 |
| Developer | developer | dev123 |
| Supervisor | supervisor01 | super123 |
| Officer | officer01 | officer123 |

## How It Works

### Auth Flow
1. User enters credentials on `/login`
2. `authStore.login()` calls `POST /api/v1/auth/login/`
3. Django returns `{ access, refresh, user }`
4. Tokens stored in `localStorage` (keys: `itms_access_token`, `itms_refresh_token`)
5. Axios interceptor attaches `Authorization: Bearer <token>` to every request
6. On 401, the interceptor silently calls `/auth/token/refresh/` and retries
7. On permanent 401 (refresh expired), dispatches `itms:session_expired` event → `AuthContext` calls `forceLogout()` → redirects to `/login`

### Simulation Engine (unchanged)
The local RL simulation engine (`simulationEngine.js`) runs entirely in-browser.
It drives the real-time charts, intersection canvas, and lane status grids.

### Backend Integration Pattern
Each page that needs live data uses:
- `useQuery` (TanStack Query) → fetches from Django REST API
- `useMutation` → POSTs/PATCHes to Django REST API
- `useEffect` + `ManagedWebSocket` → subscribes to Django Channels WebSocket

### WebSocket Channels
| Channel | Used by |
|---------|---------|
| `ws/violations/feed/` | ViolationsCenter — new violation events |
| `ws/alerts/` | AISimulationLab — system alerts |
| `ws/ai/session/{id}/` | AISimulationLab — live RL training metrics |
| `ws/traffic/{id}/` | LiveTrafficControl — live signal state per intersection |

## Data Sources Per Page

| Page | Local Sim | Backend API | WebSocket |
|------|-----------|-------------|-----------|
| Dashboard | ✓ | ✓ Summary stats | — |
| Analytics | ✓ | ✓ Violation/fine analytics | — |
| ViolationsCenter | — | ✓ GET /admin/violations/ | ✓ violations/feed/ |
| LiveTrafficControl | ✓ | ✓ Intersections + override | ✓ traffic/{id}/ |
| PunishmentSystem | — | ✓ Violations + fines + disputes | — |
| EvidencePanel | ✓ (canvas) | — | — |
| HotspotMap | ✓ (canvas) | — | — |
| Settings | ✓ | ✓ GET/PUT /admin/settings/ | — |
| AISimulationLab | ✓ | ✓ Sessions CRUD | ✓ ai/session/{id}/ + alerts/ |
| ParameterControl | ✓ | ✓ PUT /dev/rl-params/ | — |
| SystemLogs | ✓ | ✓ GET /dev/system-logs/ (toggle) | — |
| PerformanceComparison | ✓ | ✓ GET /dev/performance-comparison/ | — |
| RewardAnalytics | ✓ | — | — |
| ScenarioReplay | ✓ | — | — |
| ExperimentMode | ✓ | — | — |
