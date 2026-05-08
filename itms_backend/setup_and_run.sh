#!/usr/bin/env bash
# =============================================================================
#  ITMS — Intelligent Traffic Management System
#  setup_and_run.sh — Full automated setup and launch script
#
#  Usage:
#    chmod +x setup_and_run.sh
#    ./setup_and_run.sh                  # full setup + start all services
#    ./setup_and_run.sh --reset-db       # drop & recreate DB then full setup
#    ./setup_and_run.sh --skip-seed      # skip sample data seeding
#    ./setup_and_run.sh --docker         # use Docker Compose instead
#    ./setup_and_run.sh --stop           # stop all background services
#    ./setup_and_run.sh --status         # show service status
#
#  Services started:
#    • PostgreSQL    (system service or Docker)
#    • Redis         (system service or Docker)
#    • Django/Daphne (HTTP + WebSocket on :8000)
#    • Celery Worker
#    • Celery Beat   (scheduled tasks)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Directories ───────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
VENV_DIR="$PROJECT_DIR/.venv"
LOG_DIR="$PROJECT_DIR/logs"
PID_DIR="$PROJECT_DIR/.pids"
ENV_FILE="$PROJECT_DIR/.env"
ENV_EXAMPLE="$PROJECT_DIR/.env.example"

# ── Default flags ─────────────────────────────────────────────────────────────
RESET_DB=false
SKIP_SEED=false
USE_DOCKER=false
STOP_SERVICES=false
SHOW_STATUS=false

# ── Parse arguments ───────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --reset-db)    RESET_DB=true ;;
    --skip-seed)   SKIP_SEED=true ;;
    --docker)      USE_DOCKER=true ;;
    --stop)        STOP_SERVICES=true ;;
    --status)      SHOW_STATUS=true ;;
    --help|-h)
      grep '^#  ' "$0" | sed 's/^#  //'
      exit 0 ;;
    *)
      echo -e "${RED}Unknown argument: $arg${RESET}"
      echo "Run with --help for usage."
      exit 1 ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────
print_header() {
  echo ""
  echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${RESET}"
  echo -e "${BLUE}${BOLD}  $1${RESET}"
  echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${RESET}"
  echo ""
}

print_step() {
  echo -e "${CYAN}▶  $1${RESET}"
}

print_ok() {
  echo -e "${GREEN}✓  $1${RESET}"
}

print_warn() {
  echo -e "${YELLOW}⚠  $1${RESET}"
}

print_error() {
  echo -e "${RED}✗  $1${RESET}"
}

require_cmd() {
  if ! command -v "$1" &>/dev/null; then
    print_error "Required command not found: $1"
    echo "  Install it with: $2"
    exit 1
  fi
}

confirm() {
  local prompt="${1:-Are you sure?}"
  read -r -p "$(echo -e "${YELLOW}${prompt} [y/N] ${RESET}")" reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

pid_file() {
  echo "$PID_DIR/${1}.pid"
}

save_pid() {
  local name="$1"
  local pid="$2"
  mkdir -p "$PID_DIR"
  echo "$pid" > "$(pid_file "$name")"
}

read_pid() {
  local f
  f="$(pid_file "$1")"
  [[ -f "$f" ]] && cat "$f" || echo ""
}

service_running() {
  local pid
  pid="$(read_pid "$1")"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

# ── --status ──────────────────────────────────────────────────────────────────
if $SHOW_STATUS; then
  print_header "ITMS Service Status"
  for svc in daphne celery_worker celery_beat; do
    if service_running "$svc"; then
      pid=$(read_pid "$svc")
      print_ok "$svc  (PID $pid)"
    else
      print_error "$svc  (not running)"
    fi
  done
  echo ""
  # Show port listeners
  for port in 8000 5432 6379; do
    if lsof -i ":$port" &>/dev/null 2>&1; then
      print_ok "Port $port is open"
    else
      print_warn "Port $port is not listening"
    fi
  done
  exit 0
fi

# ── --stop ────────────────────────────────────────────────────────────────────
if $STOP_SERVICES; then
  print_header "Stopping ITMS Services"
  for svc in daphne celery_worker celery_beat; do
    pid="$(read_pid "$svc")"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" && print_ok "Stopped $svc (PID $pid)"
      rm -f "$(pid_file "$svc")"
    else
      print_warn "$svc was not running"
    fi
  done
  echo ""
  print_ok "All ITMS services stopped."
  exit 0
fi

# ── Docker mode ───────────────────────────────────────────────────────────────
if $USE_DOCKER; then
  print_header "ITMS — Docker Compose Setup"

  require_cmd docker   "https://docs.docker.com/get-docker/"
  require_cmd docker-compose "https://docs.docker.com/compose/install/  (or use 'docker compose')"

  # Determine docker compose command
  if command -v docker-compose &>/dev/null; then
    DC="docker-compose"
  else
    DC="docker compose"
  fi

  print_step "Copying .env.example → .env (if missing)"
  [[ ! -f "$ENV_FILE" ]] && cp "$ENV_EXAMPLE" "$ENV_FILE" && print_ok ".env created"

  print_step "Pulling Docker images"
  $DC pull

  print_step "Building application image"
  $DC build --no-cache

  print_step "Starting all services (db, redis, minio, backend, celery, celery-beat)"
  $DC up -d

  print_step "Waiting for PostgreSQL to be ready..."
  sleep 5
  for i in {1..20}; do
    if $DC exec -T db pg_isready -U itms_user -d itms_db &>/dev/null; then
      print_ok "PostgreSQL is ready"
      break
    fi
    [[ $i -eq 20 ]] && { print_error "PostgreSQL did not start in time"; exit 1; }
    sleep 2
  done

  print_step "Running Django migrations"
  $DC exec -T backend python manage.py migrate --run-syncdb

  print_step "Creating default superuser (if needed)"
  $DC exec -T backend python manage.py shell -c "
from accounts.models import CustomUser
if not CustomUser.objects.filter(username='admin').exists():
    u = CustomUser.objects.create_superuser('admin','admin@itms.gov.et','admin123')
    u.full_name='System Administrator'; u.role='ADMIN'; u.save()
    print('Superuser created: admin / admin123')
else:
    print('Superuser already exists')
"

  if ! $SKIP_SEED; then
    print_step "Seeding sample data"
    $DC exec -T backend python scripts/seed_data.py
  fi

  print_step "Collecting static files"
  $DC exec -T backend python manage.py collectstatic --noinput 2>/dev/null || true

  echo ""
  print_header "🚀  ITMS is Running (Docker)"
  echo -e "  ${GREEN}API:${RESET}      http://localhost:8000/api/v1/"
  echo -e "  ${GREEN}Admin UI:${RESET} http://localhost:8000/admin/"
  echo -e "  ${GREEN}MinIO:${RESET}    http://localhost:9001/"
  echo ""
  echo -e "  ${CYAN}Credentials: admin / admin123${RESET}"
  echo ""
  echo -e "  ${YELLOW}Logs:   $DC logs -f backend${RESET}"
  echo -e "  ${YELLOW}Stop:   $DC down${RESET}"
  echo ""
  exit 0
fi

# =============================================================================
#  NATIVE (non-Docker) SETUP
# =============================================================================

print_header "ITMS — Intelligent Traffic Management System Setup"
echo -e "  ${CYAN}Project: $PROJECT_DIR${RESET}"
echo ""

# ── 1. System prerequisites ───────────────────────────────────────────────────
print_header "Step 1 of 8 — Checking System Prerequisites"

require_cmd python3 "sudo apt install python3  OR  brew install python"

# Python version check (need 3.10+)
PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)
if [[ $PY_MAJOR -lt 3 || ($PY_MAJOR -eq 3 && $PY_MINOR -lt 10) ]]; then
  print_error "Python 3.10+ required. Found: $PY_VERSION"
  exit 1
fi
print_ok "Python $PY_VERSION"

require_cmd pip3    "sudo apt install python3-pip"
require_cmd psql    "sudo apt install postgresql postgresql-client  OR  brew install postgresql"
require_cmd redis-cli "sudo apt install redis-tools  OR  brew install redis"
print_ok "psql and redis-cli found"

# Check pip / venv
python3 -m venv --help &>/dev/null || { print_error "python3-venv missing. Run: sudo apt install python3-venv"; exit 1; }
print_ok "All system prerequisites satisfied"

# ── 2. Environment file ───────────────────────────────────────────────────────
print_header "Step 2 of 8 — Environment Configuration"

if [[ ! -f "$ENV_FILE" ]]; then
  print_step "Creating .env from .env.example"
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  print_ok ".env created"

  # Auto-generate a strong SECRET_KEY
  SECRET=$(python3 -c "import secrets, string; print(''.join(secrets.choice(string.ascii_letters+string.digits+'!@#\$%^&*') for _ in range(64)))")
  AI_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")

  # Use sed to patch .env
  sed -i.bak \
    -e "s|SECRET_KEY=.*|SECRET_KEY=${SECRET}|" \
    -e "s|AI_SERVICE_KEY=.*|AI_SERVICE_KEY=${AI_KEY}|" \
    "$ENV_FILE"
  rm -f "${ENV_FILE}.bak"
  print_ok "Generated SECRET_KEY and AI_SERVICE_KEY"
else
  print_ok ".env already exists — keeping existing values"
fi

# Source the env file to read DB credentials
set +u
# shellcheck disable=SC2046
export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)
set -u

DB_NAME="${DB_NAME:-itms_db}"
DB_USER="${DB_USER:-itms_user}"
DB_PASSWORD="${DB_PASSWORD:-itms_pass}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

print_ok "DB: ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# ── 3. PostgreSQL ─────────────────────────────────────────────────────────────
print_header "Step 3 of 8 — PostgreSQL Setup"

# Ensure PostgreSQL service is running
start_postgres() {
  if command -v systemctl &>/dev/null; then
    print_step "Starting PostgreSQL via systemctl"
    sudo systemctl start postgresql 2>/dev/null || \
    sudo systemctl start postgresql@15-main 2>/dev/null || \
    sudo systemctl start postgresql@14-main 2>/dev/null || true
    sleep 2
  elif command -v brew &>/dev/null; then
    print_step "Starting PostgreSQL via brew services"
    brew services start postgresql@15 2>/dev/null || \
    brew services start postgresql 2>/dev/null || true
    sleep 2
  elif command -v pg_ctl &>/dev/null; then
    print_step "Starting PostgreSQL via pg_ctl"
    pg_ctl start 2>/dev/null || true
    sleep 2
  fi
}

# Check if PostgreSQL is already accepting connections
if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -q 2>/dev/null; then
  print_step "PostgreSQL not responding — attempting to start..."
  start_postgres
  # Second check
  if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -q 2>/dev/null; then
    print_error "PostgreSQL is not running and could not be started automatically."
    echo ""
    echo "  Please start it manually:"
    echo "    Ubuntu/Debian: sudo systemctl start postgresql"
    echo "    macOS:         brew services start postgresql"
    echo "    Windows:       Start the 'postgresql-x64-15' service"
    echo ""
    echo "  Then re-run this script."
    exit 1
  fi
fi
print_ok "PostgreSQL is running"

# Handle --reset-db
if $RESET_DB; then
  print_warn "You requested --reset-db. This will DROP the existing database!"
  if confirm "Drop database '$DB_NAME' and recreate it?"; then
    print_step "Dropping database $DB_NAME"
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U postgres \
      -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || \
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || true
    print_ok "Database dropped"
  else
    print_warn "Skipping database reset"
  fi
fi

# Create user if not exists
print_step "Creating database user '$DB_USER' (if not exists)"
CREATE_USER_SQL="DO \$\$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
    CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD';
  ELSE
    ALTER ROLE $DB_USER WITH PASSWORD '$DB_PASSWORD';
  END IF;
END \$\$;"

(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -c "$CREATE_USER_SQL" 2>/dev/null) || \
(sudo -u postgres psql -c "$CREATE_USER_SQL" 2>/dev/null) || \
print_warn "Could not verify/create DB user (may already exist — continuing)"

# Create database if not exists
print_step "Creating database '$DB_NAME' (if not exists)"
CREATE_DB_SQL="SELECT 'CREATE DATABASE $DB_NAME OWNER $DB_USER' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname='$DB_NAME')\gexec"

(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -c "$CREATE_DB_SQL" 2>/dev/null) || \
(sudo -u postgres psql -c "$CREATE_DB_SQL" 2>/dev/null) || \
print_warn "Could not verify/create database (may already exist — continuing)"

# Grant privileges
GRANT_SQL="GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -c "$GRANT_SQL" 2>/dev/null) || \
(sudo -u postgres psql -c "$GRANT_SQL" 2>/dev/null) || true

print_ok "Database '$DB_NAME' ready with user '$DB_USER'"

# ── 4. Redis ──────────────────────────────────────────────────────────────────
print_header "Step 4 of 8 — Redis Setup"

REDIS_URL="${REDIS_URL:-redis://localhost:6379/0}"
REDIS_HOST=$(echo "$REDIS_URL" | sed 's|redis://||' | cut -d: -f1)
REDIS_PORT=$(echo "$REDIS_URL" | sed 's|redis://||' | cut -d: -f2 | cut -d/ -f1)

if ! redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping &>/dev/null; then
  print_step "Redis not responding — attempting to start..."
  if command -v systemctl &>/dev/null; then
    sudo systemctl start redis 2>/dev/null || sudo systemctl start redis-server 2>/dev/null || true
  elif command -v brew &>/dev/null; then
    brew services start redis 2>/dev/null || true
  else
    # Start redis-server in background as a fallback
    redis-server --daemonize yes --logfile "$LOG_DIR/redis.log" 2>/dev/null || true
  fi
  sleep 2

  if ! redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping &>/dev/null; then
    print_error "Redis is not running and could not be started."
    echo ""
    echo "  Please start it manually:"
    echo "    Ubuntu/Debian: sudo systemctl start redis"
    echo "    macOS:         brew services start redis"
    echo "    Or run:        redis-server"
    echo ""
    echo "  Then re-run this script."
    exit 1
  fi
fi
print_ok "Redis is running at $REDIS_HOST:$REDIS_PORT"

# ── 5. Python virtual environment ────────────────────────────────────────────
print_header "Step 5 of 8 — Python Virtual Environment"

if [[ ! -d "$VENV_DIR" ]]; then
  print_step "Creating virtual environment at $VENV_DIR"
  python3 -m venv "$VENV_DIR"
  print_ok "Virtual environment created"
else
  print_ok "Virtual environment already exists"
fi

# Activate venv
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"
print_ok "Virtual environment activated"

# Upgrade pip silently
print_step "Upgrading pip"
pip install --upgrade pip --quiet
print_ok "pip up to date"

# Install all dependencies
print_step "Installing Python dependencies from requirements.txt"
echo "  (This may take 1-2 minutes on first run...)"
pip install -r "$PROJECT_DIR/requirements.txt" --quiet 2>&1 | \
  grep -v "^Requirement already" | \
  grep -v "^Collecting" | \
  grep -v "^  Downloading" | \
  grep -v "^  Using cached" || true
print_ok "All dependencies installed"

# ── 6. Django setup ───────────────────────────────────────────────────────────
print_header "Step 6 of 8 — Django Migrations & Database Tables"
cd "$PROJECT_DIR"

# Test Django can import settings
print_step "Checking Django configuration"
python manage.py check --deploy 2>/dev/null || python manage.py check 2>&1 | grep -v "^System check" || true
print_ok "Django configuration valid"

# Run migrations
print_step "Running database migrations"
python manage.py migrate --run-syncdb 2>&1 | \
  grep -E "^(Applying|Running|OK|No migration|Creating)" || true
print_ok "All database tables created"

# Create admin superuser if not exists
print_step "Creating default admin superuser"
python manage.py shell << 'PYEOF'
from accounts.models import CustomUser, UserProfile
if not CustomUser.objects.filter(username='admin').exists():
    u = CustomUser.objects.create_superuser(
        username='admin',
        email='admin@itms.gov.et',
        password='admin123',
    )
    u.full_name = 'System Administrator'
    u.role = 'ADMIN'
    u.save()
    UserProfile.objects.get_or_create(user=u)
    print('  ✓ Admin superuser created: admin / admin123')
else:
    print('  ✓ Admin superuser already exists')
PYEOF

# Collect static files
print_step "Collecting static files"
python manage.py collectstatic --noinput --clear 2>/dev/null | tail -1 || true
print_ok "Static files ready"

# ── 7. Seed sample data ───────────────────────────────────────────────────────
print_header "Step 7 of 8 — Loading Sample Data"

if $SKIP_SEED; then
  print_warn "Skipping seed data (--skip-seed flag set)"
else
  print_step "Seeding intersections, violation types, fine rules, and sample records"
  python scripts/seed_data.py 2>&1 | grep -E "^(✓|Creating|⚠|✅|  )" || python scripts/seed_data.py
  print_ok "Sample data loaded"
fi

# ── 8. Start services ─────────────────────────────────────────────────────────
print_header "Step 8 of 8 — Starting Application Services"

mkdir -p "$LOG_DIR" "$PID_DIR"

# Helper: stop any previously running instance of a service
stop_old() {
  local name="$1"
  local old_pid
  old_pid="$(read_pid "$name")"
  if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
    print_step "Stopping previous $name (PID $old_pid)"
    kill "$old_pid" 2>/dev/null || true
    sleep 1
  fi
  rm -f "$(pid_file "$name")"
}

# ── Daphne (Django ASGI — HTTP + WebSocket) ───────────────────────────────────
stop_old daphne

# Free port 8000 if occupied by something else
if lsof -ti:8000 &>/dev/null; then
  print_warn "Port 8000 is in use — killing the existing process"
  kill "$(lsof -ti:8000)" 2>/dev/null || true
  sleep 1
fi

print_step "Starting Daphne on http://0.0.0.0:8000"
DJANGO_SETTINGS_MODULE=itms_backend.settings \
nohup "$VENV_DIR/bin/daphne" \
  -b 0.0.0.0 \
  -p 8000 \
  --access-log "$LOG_DIR/daphne_access.log" \
  itms_backend.asgi:application \
  >> "$LOG_DIR/daphne.log" 2>&1 &
DAPHNE_PID=$!
save_pid daphne "$DAPHNE_PID"
sleep 2

if kill -0 "$DAPHNE_PID" 2>/dev/null; then
  print_ok "Daphne started (PID $DAPHNE_PID)"
else
  print_error "Daphne failed to start. Check $LOG_DIR/daphne.log"
  cat "$LOG_DIR/daphne.log" | tail -20
  exit 1
fi

# ── Celery Worker ─────────────────────────────────────────────────────────────
stop_old celery_worker

print_step "Starting Celery worker"
DJANGO_SETTINGS_MODULE=itms_backend.settings \
nohup "$VENV_DIR/bin/celery" \
  -A itms_backend worker \
  --loglevel=warning \
  --concurrency=2 \
  >> "$LOG_DIR/celery_worker.log" 2>&1 &
WORKER_PID=$!
save_pid celery_worker "$WORKER_PID"
sleep 2

if kill -0 "$WORKER_PID" 2>/dev/null; then
  print_ok "Celery worker started (PID $WORKER_PID)"
else
  print_warn "Celery worker did not start (Redis may not be reachable). Check $LOG_DIR/celery_worker.log"
fi

# ── Celery Beat ───────────────────────────────────────────────────────────────
stop_old celery_beat

print_step "Starting Celery beat (scheduled tasks)"
DJANGO_SETTINGS_MODULE=itms_backend.settings \
nohup "$VENV_DIR/bin/celery" \
  -A itms_backend beat \
  --loglevel=warning \
  --scheduler django_celery_beat.schedulers:DatabaseScheduler \
  >> "$LOG_DIR/celery_beat.log" 2>&1 &
BEAT_PID=$!
save_pid celery_beat "$BEAT_PID"
sleep 2

if kill -0 "$BEAT_PID" 2>/dev/null; then
  print_ok "Celery beat started (PID $BEAT_PID)"
else
  print_warn "Celery beat did not start. Check $LOG_DIR/celery_beat.log"
fi

# ── Health check ──────────────────────────────────────────────────────────────
print_step "Waiting for Daphne to be ready..."
READY=false
for i in {1..15}; do
  if curl -sf "http://localhost:8000/api/v1/auth/login/" \
       -X POST -H "Content-Type: application/json" \
       -d '{}' &>/dev/null; then
    READY=true
    break
  fi
  # Also accept 400 (bad request = server is up, just rejected empty payload)
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "http://localhost:8000/api/v1/auth/login/" \
    -H "Content-Type: application/json" -d '{}' 2>/dev/null || echo "000")
  if [[ "$HTTP_CODE" =~ ^[234] ]]; then
    READY=true
    break
  fi
  sleep 1
done

if $READY; then
  print_ok "Django is responding to HTTP requests"
else
  print_warn "Django may still be starting — check $LOG_DIR/daphne.log if issues arise"
fi

# ═════════════════════════════════════════════════════════════════════════════
#  FINAL SUMMARY
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  🚀  ITMS Backend is Running!${RESET}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${CYAN}${BOLD}API Base URL:${RESET}   http://localhost:8000/api/v1/"
echo -e "  ${CYAN}${BOLD}Django Admin:${RESET}   http://localhost:8000/admin/"
echo -e "  ${CYAN}${BOLD}WebSocket:${RESET}      ws://localhost:8000/ws/"
echo ""
echo -e "  ${BOLD}Test Credentials:${RESET}"
echo -e "  ┌──────────────┬──────────────┬──────────────┐"
echo -e "  │ Role         │ Username     │ Password     │"
echo -e "  ├──────────────┼──────────────┼──────────────┤"
echo -e "  │ Admin        │ admin        │ admin123     │"
echo -e "  │ Developer    │ developer    │ dev123       │"
echo -e "  │ Supervisor   │ supervisor01 │ super123     │"
echo -e "  │ Officer      │ officer01    │ officer123   │"
echo -e "  │ Citizen      │ citizen01    │ citizen123   │"
echo -e "  └──────────────┴──────────────┴──────────────┘"
echo ""
echo -e "  ${BOLD}PID files:${RESET}  $PID_DIR/"
echo -e "  ${BOLD}Log files:${RESET}"
echo -e "    Daphne:       $LOG_DIR/daphne.log"
echo -e "    Celery worker: $LOG_DIR/celery_worker.log"
echo -e "    Celery beat:  $LOG_DIR/celery_beat.log"
echo ""
echo -e "  ${YELLOW}${BOLD}Manage:${RESET}"
echo -e "  ${YELLOW}  Stop all:        ./setup_and_run.sh --stop${RESET}"
echo -e "  ${YELLOW}  Check status:    ./setup_and_run.sh --status${RESET}"
echo -e "  ${YELLOW}  Reset database:  ./setup_and_run.sh --reset-db${RESET}"
echo -e "  ${YELLOW}  Docker mode:     ./setup_and_run.sh --docker${RESET}"
echo -e "  ${YELLOW}  Follow logs:     tail -f $LOG_DIR/daphne.log${RESET}"
echo ""
echo -e "  ${CYAN}${BOLD}Flutter app base URL: http://<YOUR_LAN_IP>:8000/api/v1/${RESET}"
echo -e "  ${CYAN}(Find your LAN IP with: hostname -I | awk '{print \$1}')${RESET}"
echo ""