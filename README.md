# django-polls en contenedores — Actividad 2

Este repositorio contiene **los Dockerfiles** necesarios para
construir las dos imágenes del aplicativo (`polls-web`) y la base de datos
(`polls-db`).

## Estructura

```
contenedores/
├── app/                  # Imagen de la aplicación Django
│   ├── Dockerfile        # multi-stage (builder + runtime), usuario no-root
│   ├── .dockerignore
│   ├── entrypoint.sh     # espera BD → migrate → collectstatic → gunicorn
│   ├── requirements.txt
│   ├── manage.py
│   ├── mysite/           # proyecto Django (settings leen de env vars)
│   └── polls/            # app del tutorial oficial de Django
└── db/                   # Imagen de PostgreSQL
    ├── Dockerfile        # basada en postgres:16-alpine
    └── init.sql          # script de init (se ejecuta si el volumen está vacío)
```

## Build local

```bash
# App web
docker build -t <usuario>/polls-web:v1 ./app

# Base de datos
docker build -t <usuario>/polls-db:v1 ./db
```

## Publicación en Docker Hub

```bash
docker login
docker push <usuario>/polls-web:v1
docker push <usuario>/polls-db:v1
```

## Prueba local (antes de publicar)

```bash
docker network create pollsnet

docker run -d --name polls-db --network pollsnet \
  -e POSTGRES_DB=polls \
  -e POSTGRES_USER=polls \
  -e POSTGRES_PASSWORD=supersecret \
  <usuario>/polls-db:v1

docker run -d --name polls-web --network pollsnet -p 8000:8000 \
  -e DB_HOST=polls-db \
  -e DB_PORT=5432 \
  -e DB_NAME=polls \
  -e DB_USER=polls \
  -e DB_PASSWORD=supersecret \
  -e SECRET_KEY=change-me \
  -e DEBUG=False \
  -e ALLOWED_HOSTS=* \
  <usuario>/polls-web:v1

# Crear superusuario para acceder al admin
docker exec -it polls-web python manage.py createsuperuser
```

Abrir `http://localhost:8000/polls/` y `http://localhost:8000/admin/`.

---

## Contrato con el equipo de Kubernetes

### Imágenes
| Rol | Imagen (sugerida) | Puerto |
|---|---|---|
| App web | `<usuario>/polls-web:v1` | **8000** |
| Base de datos | `<usuario>/polls-db:v1` | **5432** |

### Volumen persistente de la BD
Montar el PVC en: `/var/lib/postgresql/data`

### Variables de entorno — `polls-db`
Las consume la imagen oficial de Postgres durante el init.

| Variable | Origen recomendado | Ejemplo |
|---|---|---|
| `POSTGRES_DB` | ConfigMap | `polls` |
| `POSTGRES_USER` | Secret | `polls` |
| `POSTGRES_PASSWORD` | **Secret** | `********` |
| `PGDATA` *(opcional)* | ConfigMap | `/var/lib/postgresql/data/pgdata` |

### Variables de entorno — `polls-web`

| Variable | Origen recomendado | Obligatoria | Ejemplo |
|---|---|---|---|
| `DB_HOST` | ConfigMap | Sí | `polls-db` (nombre del Service) |
| `DB_PORT` | ConfigMap | Sí | `5432` |
| `DB_NAME` | ConfigMap | Sí | `polls` |
| `DB_USER` | Secret | Sí | `polls` |
| `DB_PASSWORD` | **Secret** | Sí | `********` |
| `SECRET_KEY` | **Secret** | Sí | clave aleatoria Django |
| `DEBUG` | ConfigMap | No | `False` (default) |
| `ALLOWED_HOSTS` | ConfigMap | No | `*` o el dominio público, separado por comas |
| `CSRF_TRUSTED_ORIGINS` | ConfigMap | No | `https://midominio.com` |
| `GUNICORN_WORKERS` | ConfigMap | No | `3` (default) |

### Readiness / Liveness sugerido
- Path HTTP: `GET /polls/`
- Puerto: `8000`
- `initialDelaySeconds`: 20 (la app corre `migrate` + `collectstatic` al arrancar)

### Notas para el despliegue
- La app ejecuta migraciones **en cada arranque** (idempotentes). Con 2+ réplicas no hay problema porque Django usa transacciones.
- La app corre como **usuario no-root (UID 1001)**. Si se usan `securityContext` restrictivos, es compatible.
- Se recomienda un `initContainer` para `createsuperuser` o hacerlo manualmente vía `kubectl exec` una vez desplegado.
