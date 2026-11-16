-- Script de inicialización de la BD de django-polls.
-- Se ejecuta UNA SOLA VEZ, cuando el directorio de datos está vacío.
-- La base de datos y el usuario principal ya los crea la imagen oficial
-- a partir de POSTGRES_DB / POSTGRES_USER / POSTGRES_PASSWORD.

-- Mensaje de confirmación en los logs del contenedor.
DO $$
BEGIN
    RAISE NOTICE 'django-polls database initialized';
END
$$;
