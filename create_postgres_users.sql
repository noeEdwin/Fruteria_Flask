-- Script para crear usuarios a nivel de PostgreSQL y asignar permisos

-- 1. Crear el rol de grupo base (NOLOGIN) con los atributos solicitados
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'fruteria_admin_role') THEN
        CREATE ROLE fruteria_admin_role WITH
          NOLOGIN
          NOSUPERUSER
          INHERIT
          NOCREATEDB
          NOCREATEROLE
          NOREPLICATION
          NOBYPASSRLS;
    END IF;
END
$$;

-- 2. Asignar permisos al rol de grupo sobre el esquema fruteria_db
GRANT USAGE ON SCHEMA fruteria_db TO fruteria_admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA fruteria_db TO fruteria_admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA fruteria_db TO fruteria_admin_role;

-- Asegurar que futuras tablas también tengan permisos
ALTER DEFAULT PRIVILEGES IN SCHEMA fruteria_db GRANT ALL ON TABLES TO fruteria_admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA fruteria_db GRANT ALL ON SEQUENCES TO fruteria_admin_role;

-- 3. Función auxiliar para crear o actualizar usuarios
CREATE OR REPLACE FUNCTION gestionar_usuario_postgres(nombre_usuario text, password_usuario text)
RETURNS void AS $$
BEGIN
    -- Si el usuario no existe, lo creamos
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = nombre_usuario) THEN
        EXECUTE format('CREATE USER %I WITH PASSWORD %L LOGIN IN ROLE fruteria_admin_role', nombre_usuario, password_usuario);
    ELSE
        -- Si ya existe, le actualizamos el password y aseguramos el grupo
        EXECUTE format('ALTER USER %I WITH PASSWORD %L', nombre_usuario, password_usuario);
        EXECUTE format('GRANT fruteria_admin_role TO %I', nombre_usuario);
    END IF;

    -- Permitir que el usuario 'postgres' pueda hacer SET ROLE a este usuario
    EXECUTE format('GRANT %I TO postgres', nombre_usuario);
END;
$$ LANGUAGE plpgsql;

-- 4. Crear los usuarios correspondientes a los empleados (incluyendo almacenista)
SELECT gestionar_usuario_postgres('admin', '123');
SELECT gestionar_usuario_postgres('juanp', '123');
SELECT gestionar_usuario_postgres('marial', '123');
SELECT gestionar_usuario_postgres('carlosr', '123');
SELECT gestionar_usuario_postgres('edwin', '123');
SELECT gestionar_usuario_postgres('pedroa', '123'); -- Nuevo almacenista

-- Limpiar la función auxiliar
DROP FUNCTION gestionar_usuario_postgres(text, text);
