# syntax=docker/dockerfile:1.7

FROM postgres:16-alpine

LABEL maintainer="UNIR - Contenedores Actividad 2" \
      app="django-polls-db" \
      version="1.0"

COPY init.sql /docker-entrypoint-initdb.d/00-init.sql

EXPOSE 5432

HEALTHCHECK --interval=15s --timeout=5s --start-period=20s --retries=5 \
    CMD pg_isready -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-postgres}" || exit 1
