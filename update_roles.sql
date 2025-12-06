SET search_path TO fruteria;

-- Agregar columna rol si no existe
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='empleado' AND column_name='rol') THEN 
        ALTER TABLE empleado ADD COLUMN rol VARCHAR(20) DEFAULT 'vendedor'; 
    END IF; 
END $$;

-- Eliminar columnas obsoletas si existen (opcional, pero recomendado para limpieza)
-- ALTER TABLE empleado DROP COLUMN IF EXISTS is_staff;
-- ALTER TABLE empleado DROP COLUMN IF EXISTS is_superuser;
