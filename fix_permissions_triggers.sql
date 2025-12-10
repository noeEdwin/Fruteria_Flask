SET search_path TO fruteria_db;

-- Trigger 1: Actualizar stock al realizar una venta (Resta)
-- SECURITY DEFINER added to allow 'vendedor' to update stock without direct table permissions
CREATE OR REPLACE FUNCTION tf_actualizar_stock_venta()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE producto
    SET existencia = existencia - NEW.cantidad
    WHERE codigo = NEW.codigo;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
