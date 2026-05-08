# ITMS — Intelligent Traffic Management System Backend

**Django 4.2 · DRF 3.15 · Channels 4 · PostgreSQL · Redis · Celery**

Single backend serving five subsystems:
- Citizen Flutter App
- Officer Flutter App
- React Admin Panel
- React Developer Panel
- AI Traffic Brain (SUMO + RL + CV)

---

## Project Structure

```
itms_backend/
├── manage.py
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── .env.example
│
├── itms_backend/          # Project config
│   ├── settings.py
│   ├── urls.py            # Root URL routing
│   ├── asgi.py            # ASGI + WebSocket
│   ├── wsgi.py
│   ├── celery.py
│   ├── routing.py         # WebSocket routes
│   ├── pagination.py
│   ├── permissions.py     # Role-based permission classes
│   └── exceptions.py      # Custom error handler
│
├── accounts/              # Auth + all user roles
│   ├── models.py          # CustomUser, UserProfile, OTP, PushToken
│   ├── views.py           # Login, Register, OTP, Me, Logout
│   ├── serializers.py
│   ├── authentication.py  # AI service key auth
│   ├── urls.py            # /api/v1/auth/*
│   ├── citizen_urls.py    # /api/v1/citizen/*
│   ├── citizen_views.py
│   ├── admin_urls.py      # /api/v1/admin/*
│   └── admin_views.py
│
├── vehicles/              # Vehicle + driver license registry
├── intersections/         # Intersection, lane, camera, signal state
├── violations/            # Core enforcement (AI + officer sources)
│   ├── officer_urls.py    # /api/v1/officer/*
│   ├── officer_views.py
│   ├── supervisor_urls.py # /api/v1/supervisor/*
│   └── admin_views.py
├── fines/                 # Fine rules, fines, payments, receipts
├── disputes/              # Citizen dispute workflow
├── ai_brain/              # AI bridge — sessions, episodes, signals
│   ├── urls.py            # /api/v1/ai/*  (AI service key auth)
│   ├── views.py
│   ├── dev_urls.py        # /api/v1/dev/* (developer panel)
│   └── dev_views.py
└── notifications/         # Push + in-app notifications, Celery tasks
```

---

## Quick Start (Local Development)

### Prerequisites
- Python 3.11+
- PostgreSQL 15+
- Redis 7+

### 1 — Clone and install

```bash
cd itms_backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2 — Environment

```bash
cp .env.example .env
# Edit .env with your database credentials
```

Minimum required in `.env`:
```
DB_NAME=itms_db
DB_USER=itms_user
DB_PASSWORD=itms_pass
DB_HOST=localhost
SECRET_KEY=change-this-secret-key
AI_SERVICE_KEY=change-this-ai-key
```

### 3 — Database

```bash
# Create PostgreSQL DB
createdb itms_db
createuser itms_user
psql -c "ALTER USER itms_user WITH PASSWORD 'itms_pass';"
psql -c "GRANT ALL PRIVILEGES ON DATABASE itms_db TO itms_user;"

# Run migrations
python manage.py migrate

# Load seed data (creates test users + sample data)
python manage.py shell < scripts/seed_data.py
```

### 4 — Run servers

```bash
# Terminal 1 — Django (HTTP + WebSocket via Daphne)
daphne -b 0.0.0.0 -p 8000 itms_backend.asgi:application

# Or just Django dev server (HTTP only, no WebSocket):
python manage.py runserver

# Terminal 2 — Celery worker
celery -A itms_backend worker --loglevel=info

# Terminal 3 — Celery beat (scheduled tasks)
celery -A itms_backend beat --loglevel=info
```

### 5 — Docker Compose (all services)

```bash
docker-compose up --build
```

This starts: PostgreSQL · Redis · MinIO · Django/Daphne · Celery worker · Celery beat

---

## Test Accounts (after seed)

| Role       | Username     | Password     |
|------------|-------------|--------------|
| Admin      | admin        | admin123     |
| Developer  | developer    | dev123       |
| Supervisor | supervisor01 | super123     |
| Officer    | officer01    | officer123   |
| Citizen    | citizen01    | citizen123   |

---

## API Base URL

```
http://localhost:8000/api/v1/
```

All endpoints require `Authorization: Bearer <access_token>` except:
- `POST /api/v1/auth/login/`
- `POST /api/v1/auth/register/`
- `POST /api/v1/auth/otp/send/`
- `POST /api/v1/auth/otp/verify/`
- `POST /api/v1/auth/password/reset/`

AI Brain endpoints use `X-AI-Service-Key: <key>` instead of JWT.

---

## API Endpoint Map

### Authentication — `/api/v1/auth/`
| Method | Path | Description |
|--------|------|-------------|
| POST | `/register/` | Citizen self-registration |
| POST | `/login/` | Login (all roles) |
| POST | `/logout/` | Invalidate refresh token |
| POST | `/token/refresh/` | Refresh JWT |
| GET/PUT | `/me/` | Current user profile |
| POST | `/otp/send/` | Send OTP |
| POST | `/otp/verify/` | Verify OTP |
| POST | `/password/reset/` | Reset password |
| POST | `/push-token/` | Register FCM push token |

### Citizen App — `/api/v1/citizen/`
| Method | Path | Description |
|--------|------|-------------|
| GET | `/violations/` | List own violations |
| GET | `/violations/summary/` | Dashboard stats |
| GET | `/violations/{id}/` | Violation detail |
| GET | `/fines/` | List fines |
| GET | `/fines/{id}/` | Fine detail |
| POST | `/fines/{id}/pay/` | Pay fine |
| GET | `/receipts/` | Payment receipts |
| GET/POST | `/disputes/` | List / submit dispute |
| GET/DELETE | `/disputes/{id}/` | Detail / withdraw |
| GET/POST | `/vehicles/` | List / add vehicle |
| DELETE | `/vehicles/{id}/` | Remove vehicle |
| GET | `/traffic-alerts/` | Active congestion alerts |
| GET | `/notifications/` | In-app notifications |
| PATCH | `/notifications/{id}/read/` | Mark read |

### Officer App — `/api/v1/officer/`
| Method | Path | Description |
|--------|------|-------------|
| GET/POST | `/tickets/` | List / create field ticket (multipart) |
| GET/PATCH | `/tickets/{id}/` | Detail / update draft |
| POST | `/tickets/{id}/submit/` | Submit for review |
| POST | `/tickets/bulk-sync/` | Upload offline queue |
| GET | `/plate-lookup/` | Vehicle + owner lookup |
| GET | `/violation-types/` | Cached violation types |
| GET | `/intersections/` | Nearby intersections |
| GET | `/notifications/` | Officer notifications |

### Supervisor — `/api/v1/supervisor/`
| Method | Path | Description |
|--------|------|-------------|
| GET | `/tickets/pending/` | Pending review tickets |
| POST | `/tickets/{id}/validate/` | Approve / reject ticket |
| GET | `/officers/` | Officers under supervision |
| GET | `/reports/daily/` | Daily enforcement report |

### Admin Panel — `/api/v1/admin/`
| Method | Path | Description |
|--------|------|-------------|
| GET | `/dashboard/summary/` | Main stats |
| GET | `/analytics/violations/` | Violation trends |
| GET | `/analytics/fines/` | Fine collection |
| GET | `/analytics/compliance/` | City compliance |
| GET | `/analytics/officer-performance/` | Officer productivity |
| GET/PATCH | `/violations/` + `/{id}/` | Violations CRUD |
| GET | `/evidence/` + `/{id}/` | Evidence files |
| GET | `/hotspot-map/` | Violation heatmap data |
| GET/PATCH | `/fines/` + `/{id}/` | Fines management |
| GET/POST/PUT/DELETE | `/fine-rules/` | Fine rules config |
| GET | `/intersections/` + `/{id}/` | Intersection detail |
| POST/DELETE | `/intersections/{id}/manual-override/` | Signal override |
| GET/POST | `/disputes/` + `/{id}/` | Disputes |
| POST | `/disputes/{id}/decide/` | Approve/reject dispute |
| GET/POST/PATCH | `/users/` + `/{id}/` | User management |
| GET/PUT | `/settings/` | System settings |

### Developer Panel — `/api/v1/dev/`
| Method | Path | Description |
|--------|------|-------------|
| GET/POST | `/ai-sessions/` | List / start RL session |
| GET | `/ai-sessions/{id}/` | Session detail |
| POST | `/ai-sessions/{id}/stop/` | Stop session |
| GET | `/ai-sessions/{id}/episodes/` | Episode data for charts |
| GET/POST | `/experiments/` | Experiment configs |
| GET | `/scenarios/` | SUMO scenarios |
| GET | `/scenarios/{id}/replay/` | Scenario replay |
| GET | `/system-logs/` | AI system logs |
| GET | `/performance-comparison/` | RL vs fixed timing |
| PUT | `/rl-params/` | Update live hyperparams |

### AI Brain Service — `/api/v1/ai/` (X-AI-Service-Key)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/intersections/state/` | Fetch all intersection states |
| POST | `/signal-decision/` | Post RL signal decision |
| POST | `/cv-detection/` | Post CV-detected violation |
| POST | `/congestion-alert/` | Post congestion zone |
| POST | `/episode-log/` | Log RL episode result |
| POST | `/simulation-log/` | Post simulation log |
| GET | `/config/` | Fetch AI config from Django |

---

## WebSocket Channels

```
ws://localhost:8000/ws/traffic/{intersection_id}/    # Live signal states
ws://localhost:8000/ws/violations/feed/              # New violation events
ws://localhost:8000/ws/ai/session/{session_id}/      # RL training metrics
ws://localhost:8000/ws/alerts/                       # System alerts
ws://localhost:8000/ws/officer/sync/{officer_id}/    # Sync confirmations
```

---

## AI Brain Integration

The AI service calls Django via REST. Required env vars on the AI side:
```bash
DJANGO_BASE_URL=http://localhost:8000/api/v1
AI_SERVICE_KEY=<same value as Django's AI_SERVICE_KEY>
```

Example AI → Django call:
```python
import requests
headers = {'X-AI-Service-Key': 'your-key'}
# Fetch intersection state
state = requests.get(f'{BASE}/ai/intersections/state/', headers=headers).json()
# Post signal decision
requests.post(f'{BASE}/ai/signal-decision/', headers=headers, json={
    'intersection_id': '...', 'phase': 'NS_GREEN',
    'duration_seconds': 45, 'confidence': 0.87
})
# Post CV detection
requests.post(f'{BASE}/ai/cv-detection/', headers=headers, json={
    'plate_number': 'AA-12345', 'violation_type_code': 'RED_LIGHT',
    'intersection_id': '...', 'confidence': 0.94
})
```

---

## Celery Scheduled Tasks

Configured in `notifications/tasks.py`:
- `notify_fine_due_reminders` — daily at 09:00, notifies citizens of fines due in 3 days
- `update_compliance_scores` — daily at 02:00, recalculates all citizen scores
- `cleanup_old_notifications` — weekly, deletes read notifications > 30 days

Add to Django admin under **Periodic Tasks** (django-celery-beat).

---

## Response Format

**Success (list):**
```json
{ "count": 42, "next": "...", "previous": null, "results": [...] }
```

**Success (object):** raw object

**Error:**
```json
{ "error": "Validation failed", "code": "VALIDATION_ERROR", "details": {"field": "message"} }
```

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Django 4.2 + DRF 3.15 |
| Auth | SimpleJWT (rotate + blacklist) |
| WebSockets | Django Channels 4 + Redis |
| Database | PostgreSQL 15 |
| Cache/Broker | Redis 7 |
| Task Queue | Celery 5 + Celery Beat |
| File Storage | Local (dev) / MinIO/S3 (prod) |
| ASGI Server | Daphne 4 |
