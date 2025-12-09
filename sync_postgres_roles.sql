-- Script para sincronizar roles de PostgreSQL con la tabla empleado
-- Se puede ejecutar independientemente o como parte del DML

SET search_path TO fruteria_db;

-- 1. Asegurar que existe el rol de grupo base
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
        
        GRANT USAGE ON SCHEMA fruteria_db TO fruteria_admin_role;
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA fruteria_db TO fruteria_admin_role;
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA fruteria_db TO fruteria_admin_role;
        ALTER DEFAULT PRIVILEGES IN SCHEMA fruteria_db GRANT ALL ON TABLES TO fruteria_admin_role;
        ALTER DEFAULT PRIVILEGES IN SCHEMA fruteria_db GRANT ALL ON SEQUENCES TO fruteria_admin_role;
    END IF;
END
$$;

-- 2. Función auxiliar (temporal o persistente) para crear usuarios
CREATE OR REPLACE FUNCTION gestion_usuario_auto(p_username text, p_password text)
RETURNS void AS $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = p_username) THEN
        EXECUTE format('CREATE USER %I WITH PASSWORD %L LOGIN IN ROLE fruteria_admin_role', p_username, p_password);
    ELSE
        -- Si existe, solo aseguramos el password y el grupo
        EXECUTE format('ALTER USER %I WITH PASSWORD %L', p_username, p_password);
        EXECUTE format('GRANT fruteria_admin_role TO %I', p_username);
    END IF;
    
    -- Dar permiso a postgres para impersonar (SET ROLE)
    EXECUTE format('GRANT %I TO postgres', p_username);
END;
$$ LANGUAGE plpgsql;

-- 3. Iterar sobre la tabla empleado y crear los roles
DO $$
DECLARE
    emp RECORD;
BEGIN
    FOR emp IN SELECT username FROM empleado WHERE username IS NOT NULL LOOP
        -- Usamos '123' como password por defecto para todos en este entorno de desarrollo
        PERFORM gestion_usuario_auto(emp.username, '123');
    END LOOP;
END
$$;

-- Limpieza
DROP FUNCTION gestion_usuario_auto(text, text);
