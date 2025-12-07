SET search_path TO fruteria_db;

-- Función para obtener el nombre del empleado de forma segura
-- SECURITY DEFINER permite que se ejecute con los permisos del creador (postgres/admin)
CREATE OR REPLACE FUNCTION get_empleado_nombre(p_id_e INTEGER)
RETURNS VARCHAR AS $$
DECLARE
    v_nombre VARCHAR;
BEGIN
    SELECT nombre INTO v_nombre
    FROM empleado
    WHERE id_e = p_id_e;
    
    RETURN v_nombre;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Otorgar permiso de ejecución a los roles
GRANT EXECUTE ON FUNCTION get_empleado_nombre(INTEGER) TO rol_almacenista, rol_vendedor, rol_supervisor, rol_admin;
