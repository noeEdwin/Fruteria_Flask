SET search_path TO fruteria_db;

-- 1. Create Group Role
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'fruteria_admin_role') THEN

      CREATE ROLE fruteria_admin_role WITH
        NOLOGIN
        NOSUPERUSER
        INHERIT
        NOCREATEDB
        NOCREATEROLE
        NOREPLICATION;
   END IF;
END
$do$;

-- Grant privileges to the group role
GRANT USAGE ON SCHEMA fruteria_db TO fruteria_admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA fruteria_db TO fruteria_admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA fruteria_db TO fruteria_admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA fruteria_db GRANT ALL PRIVILEGES ON TABLES TO fruteria_admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA fruteria_db GRANT ALL PRIVILEGES ON SEQUENCES TO fruteria_admin_role;

-- 2. Create User 'edwin'
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'edwin') THEN

      CREATE ROLE edwin WITH LOGIN PASSWORD 'edwin123' INHERIT;
      GRANT fruteria_admin_role TO edwin;
   ELSE
      ALTER ROLE edwin WITH PASSWORD 'edwin123';
      GRANT fruteria_admin_role TO edwin;
   END IF;
END
$do$;

-- 3. Modify Employee Table
-- We drop password and last_login as they are no longer needed in the app table
ALTER TABLE empleado DROP COLUMN IF EXISTS password;
ALTER TABLE empleado DROP COLUMN IF EXISTS last_login;

-- 4. Insert/Update 'edwin' in empleado table
-- We use ON CONFLICT to handle if he already exists (assuming id_e or username is unique)
-- First, let's ensure we have a record for him.
INSERT INTO empleado (id_e, nombre, turno, salario, username, is_active, is_staff, is_superuser)
VALUES (100, 'Edwin Noe', 'Matutino', 5000.00, 'edwin', true, true, true)
ON CONFLICT (id_e) DO UPDATE 
SET username = 'edwin', nombre = 'Edwin Noe';

-- Also ensure username is unique constraint if not already (DDL said it was)
