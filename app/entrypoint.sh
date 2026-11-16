#!/bin/sh
set -e

echo "[entrypoint] Waiting for database at ${DB_HOST}:${DB_PORT}..."
python <<'PY'
import os
import socket
import time

host = os.environ.get("DB_HOST", "localhost")
port = int(os.environ.get("DB_PORT", "5432"))
deadline = time.time() + 60

while time.time() < deadline:
    try:
        with socket.create_connection((host, port), timeout=2):
            print(f"[entrypoint] Database {host}:{port} is reachable")
            break
    except OSError:
        time.sleep(1)
else:
    raise SystemExit(f"[entrypoint] Timed out waiting for {host}:{port}")
PY

echo "[entrypoint] Applying migrations..."
python manage.py migrate --noinput

echo "[entrypoint] Collecting static files..."
python manage.py collectstatic --noinput

echo "[entrypoint] Starting gunicorn..."
exec gunicorn mysite.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers "${GUNICORN_WORKERS:-3}" \
    --access-logfile - \
    --error-logfile -
