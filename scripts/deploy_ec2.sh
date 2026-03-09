#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/var/www/payment_app}"
BACKEND_DIR="${BACKEND_DIR:-$APP_DIR/backend}"
FRONTEND_DIR="${FRONTEND_DIR:-$APP_DIR/frontend}"
SERVICE_NAME="${SERVICE_NAME:-payment-backend}"
VENV_DIR="${VENV_DIR:-}"
BRANCH="${1:-main}"

echo "[deploy] app dir: $APP_DIR"
cd "$APP_DIR"

echo "[deploy] fetching latest code from branch: $BRANCH"
git fetch origin "$BRANCH"
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"

echo "[deploy] backend dependencies"
cd "$BACKEND_DIR"
if [[ -z "$VENV_DIR" ]]; then
  if [[ -d ".venv" ]]; then
    VENV_DIR=".venv"
  elif [[ -d "venv" ]]; then
    VENV_DIR="venv"
  else
    VENV_DIR=".venv"
  fi
fi

if [[ ! -d "$VENV_DIR" ]]; then
  python3 -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install -r requirements.txt

if [[ ! -f ".env" ]]; then
  echo "[deploy] missing $BACKEND_DIR/.env"
  exit 1
fi

set -a
source .env
set +a

echo "[deploy] running django migrations + static collection"
python manage.py migrate --noinput
python manage.py collectstatic --noinput

echo "[deploy] frontend build"
cd "$FRONTEND_DIR"
if [[ ! -f ".env" ]]; then
  echo "[deploy] missing $FRONTEND_DIR/.env"
  exit 1
fi
npm ci
npm run build

echo "[deploy] restarting services"
sudo systemctl daemon-reload
sudo systemctl restart "$SERVICE_NAME"
sudo systemctl is-active --quiet "$SERVICE_NAME"
sudo nginx -t
sudo systemctl restart nginx

echo "[deploy] health checks"
curl --fail --silent --show-error http://127.0.0.1/ >/dev/null
curl --fail --silent --show-error http://127.0.0.1/api/customers/ >/dev/null

echo "[deploy] completed"
