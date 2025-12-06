-- Script para crear jerarquía de roles y usuarios en PostgreSQL

SET search_path TO fruteria_db;

-- 1. Definir Roles Funcionales (NOLOGIN)
-- Función auxiliar para crear roles si no existen
DO $$
BEGIN
    -- Rol Vendedor
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_vendedor') THEN
        CREATE ROLE rol_vendedor WITH NOLOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;
    
    -- Rol Almacenista
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_almacenista') THEN
        CREATE ROLE rol_almacenista WITH NOLOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;
    
    -- Rol Supervisor
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_supervisor') THEN
        CREATE ROLE rol_supervisor WITH NOLOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;
    
    -- Rol Admin (Dueño)
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_admin') THEN
        CREATE ROLE rol_admin WITH NOLOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;
END
$$;

-- 2. Asignar Permisos a los Roles Funcionales

-- Permisos Comunes (Uso de esquema y secuencias)
GRANT USAGE ON SCHEMA fruteria_db TO rol_vendedor, rol_almacenista, rol_supervisor, rol_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA fruteria_db TO rol_vendedor, rol_almacenista, rol_supervisor, rol_admin;

-- Permisos VENDEDOR
-- Puede leer productos y clientes
GRANT SELECT ON producto, cliente, p_fisica, p_moral TO rol_vendedor;
-- Puede registrar ventas
GRANT INSERT, SELECT ON venta, detalle_venta TO rol_vendedor;
-- Puede registrar clientes
GRANT INSERT, UPDATE ON cliente, p_fisica, p_moral TO rol_vendedor;

-- Permisos ALMACENISTA
-- Puede leer y actualizar productos (stock)
GRANT SELECT, UPDATE ON producto TO rol_almacenista;
-- Puede gestionar proveedores y compras
GRANT ALL PRIVILEGES ON proveedor, compra, detalle_compra, producto_proveedor TO rol_almacenista;

-- Permisos SUPERVISOR
-- Acceso amplio para supervisar, pero restringido en borrado crítico si se desea (aquí damos ALL a tablas operativas)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA fruteria_db TO rol_supervisor;
-- REVOKE DELETE ON venta FROM rol_supervisor; -- Ejemplo si se quisiera restringir

-- Permisos ADMIN
-- Dueño absoluto del esquema
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA fruteria_db TO rol_admin;


-- 3. Crear Usuarios y Asignar Roles (Herencia)

CREATE OR REPLACE FUNCTION gestionar_usuario_jerarquico(nombre_usuario text, password_usuario text, rol_asignar text)
RETURNS void AS $$
BEGIN
    -- Crear usuario si no existe
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = nombre_usuario) THEN
        EXECUTE format('CREATE USER %I WITH PASSWORD %L LOGIN', nombre_usuario, password_usuario);
    ELSE
        EXECUTE format('ALTER USER %I WITH PASSWORD %L', nombre_usuario, password_usuario);
    END IF;

    -- Asignar el rol funcional correspondiente
    -- Primero removemos membresías anteriores para evitar mezclas
    EXECUTE format('REVOKE rol_vendedor, rol_almacenista, rol_supervisor, rol_admin FROM %I', nombre_usuario);
    
    -- Asignamos el nuevo rol
    EXECUTE format('GRANT %I TO %I', rol_asignar, nombre_usuario);
    
    -- Permitir que postgres haga SET ROLE
    EXECUTE format('GRANT %I TO postgres', nombre_usuario);
END;
$$ LANGUAGE plpgsql;

-- Asignación de Roles a Usuarios Específicos
SELECT gestionar_usuario_jerarquico('admin', '123', 'rol_admin');
SELECT gestionar_usuario_jerarquico('edwin', '123', 'rol_admin');

SELECT gestionar_usuario_jerarquico('marial', '123', 'rol_supervisor');

SELECT gestionar_usuario_jerarquico('juanp', '123', 'rol_vendedor');
SELECT gestionar_usuario_jerarquico('carlosr', '123', 'rol_vendedor');

SELECT gestionar_usuario_jerarquico('pedroa', '123', 'rol_almacenista');

-- Limpieza
DROP FUNCTION gestionar_usuario_jerarquico(text, text, text);
