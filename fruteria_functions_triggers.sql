-- Script de Funciones y Triggers para Frutería

SET search_path TO fruteria_db;

-- ==========================================
-- 1. FUNCIONES ALMACENADAS 
-- ==========================================

-- Función 1: Calcular el total de una venta
CREATE OR REPLACE FUNCTION fn_calcular_total_venta(p_folio_v INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    total NUMERIC(10,2);
BEGIN
    SELECT COALESCE(SUM(dv.cantidad * p.precio_v), 0)
    INTO total
    FROM detalle_venta dv
    JOIN producto p ON dv.codigo = p.codigo
    WHERE dv.folio_v = p_folio_v;
    
    RETURN total;
END;
$$ LANGUAGE plpgsql;

-- Función 2: Consultar stock disponible de un producto
CREATE OR REPLACE FUNCTION fn_stock_disponible(p_codigo INTEGER)
RETURNS INTEGER AS $$
DECLARE
    stock_actual INTEGER;
BEGIN
    SELECT existencia INTO stock_actual
    FROM producto
    WHERE codigo = p_codigo;
    
    RETURN COALESCE(stock_actual, 0);
END;
$$ LANGUAGE plpgsql;

-- Función 3: Calcular ventas totales por empleado en un rango de fechas
CREATE OR REPLACE FUNCTION fn_ventas_por_empleado(p_id_e INTEGER, p_fecha_inicio DATE, p_fecha_fin DATE)
RETURNS NUMERIC AS $$
DECLARE
    total_vendido NUMERIC(14,2);
BEGIN
    SELECT COALESCE(SUM(fn_calcular_total_venta(v.folio_v)), 0)
    INTO total_vendido
    FROM venta v
    WHERE v.id_e = p_id_e
    AND v.fecha BETWEEN p_fecha_inicio AND p_fecha_fin;
    
    RETURN total_vendido;
END;
$$ LANGUAGE plpgsql;

-- Función 4: Calcular valor total del inventario (Costo)
CREATE OR REPLACE FUNCTION fn_valor_inventario_total()
RETURNS NUMERIC AS $$
DECLARE
    valor_total NUMERIC(14,2);
BEGIN
    SELECT COALESCE(SUM(existencia * precio_c), 0)
    INTO valor_total
    FROM producto;
    
    RETURN valor_total;
END;
$$ LANGUAGE plpgsql;


-- ==========================================
-- 2. DISPARADORES (TRIGGERS)
-- ==========================================

-- Trigger 1: Actualizar stock al realizar una venta (Resta)
CREATE OR REPLACE FUNCTION tf_actualizar_stock_venta()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE producto
    SET existencia = existencia - NEW.cantidad
    WHERE codigo = NEW.codigo;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tg_actualizar_stock_venta ON detalle_venta;
CREATE TRIGGER tg_actualizar_stock_venta
AFTER INSERT ON detalle_venta
FOR EACH ROW
EXECUTE FUNCTION tf_actualizar_stock_venta();


-- Trigger 2: Actualizar stock al realizar una compra (Suma)
CREATE OR REPLACE FUNCTION tf_actualizar_stock_compra()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE producto
    SET existencia = existencia + NEW.cantidad
    WHERE codigo = NEW.codigo;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tg_actualizar_stock_compra ON detalle_compra;
CREATE TRIGGER tg_actualizar_stock_compra
AFTER INSERT ON detalle_compra
FOR EACH ROW
EXECUTE FUNCTION tf_actualizar_stock_compra();


-- Trigger 3: Verificar stock suficiente antes de vender
CREATE OR REPLACE FUNCTION tf_verificar_stock_suficiente()
RETURNS TRIGGER AS $$
DECLARE
    stock_actual INTEGER;
BEGIN
    SELECT existencia INTO stock_actual
    FROM producto
    WHERE codigo = NEW.codigo;
    
    IF stock_actual < NEW.cantidad THEN
        RAISE EXCEPTION 'Stock insuficiente para el producto %. Disponible: %, Solicitado: %', NEW.codigo, stock_actual, NEW.cantidad;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tg_verificar_stock_suficiente ON detalle_venta;
CREATE TRIGGER tg_verificar_stock_suficiente
BEFORE INSERT ON detalle_venta
FOR EACH ROW
EXECUTE FUNCTION tf_verificar_stock_suficiente();


-- Trigger 4: Validar que el precio de venta sea mayor al precio de compra
CREATE OR REPLACE FUNCTION tf_validar_precios_producto()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.precio_v <= NEW.precio_c THEN
        RAISE EXCEPTION 'El precio de venta (%) debe ser mayor al precio de compra (%)', NEW.precio_v, NEW.precio_c;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tg_validar_precios_producto ON producto;
CREATE TRIGGER tg_validar_precios_producto
BEFORE INSERT OR UPDATE ON producto
FOR EACH ROW
EXECUTE FUNCTION tf_validar_precios_producto();
