# Deploy on Single EC2 (Ubuntu) with SQLite + GitHub Actions CI/CD

## Architecture

- One EC2 Ubuntu instance
- Django backend via Gunicorn + systemd
- React frontend as static build served by Nginx
- SQLite database file (`backend/db.sqlite3`)
- Nginx routes:
  - `/` -> React build
  - `/api/` -> Django
  - `/static/` -> Django collected static files

## 1) EC2 prerequisites

Security group inbound rules:
- `22` SSH from your IP
- `80` HTTP from `0.0.0.0/0`
- `443` HTTPS from `0.0.0.0/0` (optional, recommended later with SSL)

Install packages:

```bash
sudo apt update
sudo apt install -y python3-venv python3-pip nginx nodejs npm git
```

## 2) Clone project

```bash
sudo mkdir -p /var/www/payment_app
sudo chown -R $USER:$USER /var/www/payment_app
cd /var/www/payment_app
git clone <YOUR_GITHUB_REPO_URL> .
```

## 3) Backend one-time setup

```bash
cd /var/www/payment_app/backend
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
cp .env.example .env
```

Edit `backend/.env`:

```env
DJANGO_SECRET_KEY=replace-with-strong-secret
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=<EC2_PUBLIC_IP>,<YOUR_DOMAIN>
DJANGO_CORS_ALLOW_ALL=False
DJANGO_CORS_ALLOWED_ORIGINS=http://<EC2_PUBLIC_IP>,https://<YOUR_DOMAIN>
DB_ENGINE=django.db.backends.sqlite3
DB_NAME=/var/www/payment_app/backend/db.sqlite3
```

Run migrations/static:

```bash
set -a && source .env && set +a
python manage.py migrate
python manage.py collectstatic --noinput
```

## 4) Frontend one-time setup

```bash
cd /var/www/payment_app/frontend
cp .env.example .env
```

Edit `frontend/.env`:

```env
REACT_APP_API_BASE_URL=/api/
```

Build:

```bash
npm ci
npm run build
```

## 5) Configure systemd + Nginx

Copy templates from repo:

```bash
sudo cp /var/www/payment_app/infra/systemd/payment-backend.service /etc/systemd/system/payment-backend.service
sudo cp /var/www/payment_app/infra/nginx/payment_app.conf /etc/nginx/sites-available/payment_app
```

Enable services:

```bash
sudo ln -sf /etc/nginx/sites-available/payment_app /etc/nginx/sites-enabled/payment_app
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl daemon-reload
sudo systemctl enable payment-backend
sudo systemctl restart payment-backend
sudo nginx -t
sudo systemctl restart nginx
```

## 6) Manual deploy command (on EC2)

```bash
cd /var/www/payment_app
chmod +x scripts/deploy_ec2.sh
./scripts/deploy_ec2.sh main
```

## 7) GitHub Actions CI/CD setup

Workflow file: `.github/workflows/ci-cd.yml`

Set GitHub repository secrets:
- `EC2_HOST` -> your EC2 public IP or DNS
- `EC2_USER` -> SSH user (usually `ubuntu`)
- `EC2_SSH_PRIVATE_KEY` -> private key content for the EC2 key pair
- `EC2_APP_DIR` -> optional app path on EC2 (for example `/home/ubuntu/payment_collection`)
- `EC2_VENV_DIR` -> optional backend venv folder name (for example `venv` or `.venv`)

Behavior:
- On PR/push to `main`: runs CI (Django checks/tests + React build)
- On push to `main`: runs deploy job over SSH and executes `scripts/deploy_ec2.sh`

## 8) Verify

```bash
curl -I http://127.0.0.1/
curl -I http://127.0.0.1/api/customers/
```

Service logs:

```bash
sudo journalctl -u payment-backend -f
sudo tail -f /var/log/nginx/error.log
```

## 9) HTTPS with Let's Encrypt (optional, recommended)

Prerequisites:
- Domain DNS `A` record points to your EC2 public IP.
- Nginx site is serving over port `80`.

Install certbot and issue cert:

```bash
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

Test auto-renew:

```bash
sudo certbot renew --dry-run
```
