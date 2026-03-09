#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/var/www/payment_app"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"
SERVICE_NAME="payment-backend"
BRANCH="${1:-main}"

echo "[deploy] app dir: $APP_DIR"
cd "$APP_DIR"

echo "[deploy] fetching latest code from branch: $BRANCH"
git fetch origin "$BRANCH"
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"

echo "[deploy] backend dependencies"
cd "$BACKEND_DIR"
if [[ ! -d ".venv" ]]; then
  python3 -m venv .venv
fi
source .venv/bin/activate
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
sudo systemctl restart "$SERVICE_NAME"
sudo systemctl restart nginx

echo "[deploy] completed"
