#!/usr/bin/env bash
set -e

echo "Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT} ..."

# Wait for the database to be up and ready, if not ready, then sleep for 5 seconds
while ! nc -z "${DB_HOST}" "${DB_PORT}"; do
  sleep 2
done

echo "PostgreSQL is active"

cd /app/src


python manage.py migrate --noinput
python manage.py collectstatic --noinput


if python manage.py shell -c "import sys; from django.contrib.auth import get_user_model;
 sys.exit(0 if get_user_model().objects.filter(username='${DJANGO_SUPERUSER_USERNAME}').exists() else 1)";
  then echo "Superuser already exists, skipping"
else
  python manage.py createsuperuser --noinput
fi

exec gunicorn tsa_app.wsgi:application --bind 0.0.0.0:8000
