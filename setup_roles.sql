-- Script to initialize roles for Fruteria DB

-- Group Roles
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'fruteria_admin_role') THEN
        CREATE ROLE fruteria_admin_role WITH NOLOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_admin') THEN
        CREATE ROLE rol_admin IN ROLE fruteria_admin_role;
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_supervisor') THEN
        CREATE ROLE rol_supervisor IN ROLE fruteria_admin_role;
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_almacenista') THEN
        CREATE ROLE rol_almacenista IN ROLE fruteria_admin_role;
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_vendedor') THEN
        CREATE ROLE rol_vendedor IN ROLE fruteria_admin_role;
    END IF;
    
   -- Permissions (after schema creation, but safe to run repeatedly)
   -- Note: Schema usually created by DDL. We grant usage here just in case schema exists.
   -- Ideally, this is run BEFORE DDL to create roles, but permissions granted AFTER.
   -- We will split or instruct order carefully.
END
$$;
