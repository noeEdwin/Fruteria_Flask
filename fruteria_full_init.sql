DROP SCHEMA IF EXISTS fruteria_db CASCADE;
CREATE SCHEMA IF NOT EXISTS fruteria_db AUTHORIZATION postgres;

SET search_path TO fruteria_db;

CREATE TABLE producto(
    codigo INTEGER PRIMARY KEY,
    descripcion VARCHAR(50),
    categoria VARCHAR(50),
    unidad_medida VARCHAR(20),
    existencia INTEGER,
    precio_c numeric (8,2),
    precio_v numeric (8,2)
);

CREATE TABLE proveedor(
    id_p INTEGER PRIMARY KEY,
    nombre VARCHAR(80),
    ciudad VARCHAR(30),
    contacto VARCHAR(70),
    tel_contacto VARCHAR(20)
);

CREATE TABLE producto_proveedor(
    codigo INTEGER,
    id_p INTEGER,
    FOREIGN KEY (codigo) REFERENCES producto(codigo),
    FOREIGN KEY (id_p) REFERENCES proveedor(id_p)
);

CREATE TABLE cliente(
    id_c INTEGER PRIMARY KEY,
    telefono VARCHAR(12),
    rfc VARCHAR(16),
    domicilio VARCHAR(50)
);

CREATE TABLE p_moral(
    id_c INTEGER,
    razon_social VARCHAR(50),
    FOREIGN KEY (id_c) REFERENCES cliente(id_c)
);

CREATE TABLE p_fisica(
    id_c INTEGER,
    nombre VARCHAR(25),
    FOREIGN KEY (id_c) REFERENCES cliente(id_c)
);

-- Tabla corregida y limpia
CREATE TABLE empleado(
    id_e INTEGER PRIMARY KEY,
    nombre VARCHAR(60),
    turno VARCHAR(20),
    salario NUMERIC(14,2),
    username VARCHAR(150) UNIQUE,
    rol VARCHAR(20) DEFAULT 'vendedor',
    last_login TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE supervisor(
    id_e INTEGER,
    id_s INTEGER,
    FOREIGN KEY (id_e) REFERENCES empleado(id_e),
    FOREIGN KEY (id_s) REFERENCES empleado(id_e)
);

CREATE TABLE venta(
    folio_v INTEGER PRIMARY KEY,
    fecha DATE,
    id_c integer,
    id_e integer
);

CREATE TABLE detalle_venta(
    codigo integer,
    folio_v integer,
    observaciones varchar(50),
    cantidad integer,
    FOREIGN KEY (codigo) REFERENCES producto(codigo),
    FOREIGN KEY (folio_v) REFERENCES venta(folio_v)
);

CREATE TABLE compra(
    folio_c INTEGER PRIMARY KEY,
    no_lote INTEGER,
    fecha DATE,
    id_p integer references proveedor (id_p),
    id_e integer references empleado (id_e)
);

CREATE TABLE detalle_compra(
    folio_c integer references compra (folio_c),
    codigo integer REFERENCES producto(codigo),
    cantidad integer 
);-- Script para crear jerarquía de roles y usuarios en PostgreSQL

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

-- Resetear permisos
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA fruteria_db FROM rol_vendedor, rol_almacenista, rol_supervisor, rol_admin;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA fruteria_db FROM rol_vendedor, rol_almacenista, rol_supervisor, rol_admin;

-- Permisos Comunes (Uso de esquema y secuencias)
GRANT USAGE ON SCHEMA fruteria_db TO rol_vendedor, rol_almacenista, rol_supervisor, rol_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA fruteria_db TO rol_vendedor, rol_almacenista, rol_supervisor, rol_admin;

-- Permisos VENDEDOR
-- producto: R
GRANT SELECT ON producto TO rol_vendedor;
-- venta: C, R
GRANT INSERT, SELECT ON venta TO rol_vendedor;
-- detalle_venta: C, R
GRANT INSERT, SELECT ON detalle_venta TO rol_vendedor;
-- cliente (y p_fisica/moral): C, R, U
GRANT INSERT, SELECT, UPDATE ON cliente, p_fisica, p_moral TO rol_vendedor;

-- Permisos ALMACENISTA
-- producto: R, U
GRANT INSERT, SELECT, UPDATE ON producto TO rol_almacenista;
-- compra: C, R, U, D
GRANT INSERT, SELECT, UPDATE, DELETE ON compra TO rol_almacenista;
-- detalle_compra: C, R, U, D
GRANT INSERT, SELECT, UPDATE, DELETE ON detalle_compra TO rol_almacenista;
-- proveedor: C, R, U, D
GRANT INSERT, SELECT, UPDATE, DELETE ON proveedor TO rol_almacenista;
-- producto_proveedor: C, R, U, D
GRANT INSERT, SELECT, UPDATE, DELETE ON producto_proveedor TO rol_almacenista;

-- Permisos SUPERVISOR
-- producto: C, R, U, D
GRANT INSERT, SELECT, UPDATE, DELETE ON producto TO rol_supervisor;
-- venta: C, R, U, D
GRANT INSERT, SELECT, UPDATE, DELETE ON venta TO rol_supervisor;
-- detalle_venta: C, R, U, D
GRANT INSERT, SELECT, UPDATE, DELETE ON detalle_venta TO rol_supervisor;
-- cliente (y p_fisica/moral): C, R, U, D
GRANT INSERT, SELECT, UPDATE, DELETE ON cliente, p_fisica, p_moral TO rol_supervisor;
-- compra: C, R, U, D
GRANT INSERT, SELECT, UPDATE, DELETE ON compra TO rol_supervisor;
-- detalle_compra: C, R, U, D
GRANT INSERT, SELECT, UPDATE, DELETE ON detalle_compra TO rol_supervisor;
-- proveedor: C, R, U, D
GRANT INSERT, SELECT, UPDATE, DELETE ON proveedor TO rol_supervisor;
-- producto_proveedor: C, R, U, D
GRANT INSERT, SELECT, UPDATE, DELETE ON producto_proveedor TO rol_supervisor;
-- empleado: R
GRANT SELECT ON empleado TO rol_supervisor;

-- Permisos ADMIN
-- Total
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
-- Script DML Generado Automáticamente con Datos Realistas
SET search_path TO fruteria_db;
TRUNCATE TABLE detalle_compra, compra, detalle_venta, venta, supervisor, empleado, p_fisica, p_moral, cliente, producto_proveedor, proveedor, producto CASCADE;
INSERT INTO producto (codigo, descripcion, categoria, unidad_medida, existencia, precio_c, precio_v) VALUES
(1001, 'coco roja', 'fruta', 'bolsa', 8, 44.77, 71.63),
(1002, 'calabacita amarilla', 'verdura', 'pieza', 24, 29.52, 47.23),
(1003, 'frambuesa amarilla', 'fruta', 'kilogramo', 17, 30.45, 48.72),
(1004, 'camote grande', 'verdura', 'kilogramo', 91, 10.96, 17.54),
(1005, 'melon nacional', 'fruta', 'manojo', 42, 18.64, 29.82),
(1006, 'jitomate importada', 'verdura', 'pieza', 12, 14.07, 22.51),
(1007, 'naranja verde', 'fruta', 'kilogramo', 22, 26.38, 42.21),
(1008, 'papa amarilla', 'verdura', 'manojo', 20, 16.42, 26.27),
(1009, 'fresa importada', 'fruta', 'manojo', 78, 26.31, 42.1),
(1010, 'cebolla roja', 'verdura', 'bolsa', 13, 28.07, 44.91),
(1011, 'manzana verde', 'fruta', 'bolsa', 76, 19.34, 30.94),
(1012, 'brocoli chica', 'verdura', 'bolsa', 22, 29.97, 47.95),
(1013, 'fresa chica', 'fruta', 'manojo', 8, 45.56, 72.9),
(1014, 'tomate kg', 'verdura', 'pieza', 28, 32.64, 52.22),
(1015, 'mango verde', 'fruta', 'bolsa', 48, 43.34, 69.34),
(1016, 'brocoli verde', 'verdura', 'bolsa', 73, 39.15, 62.64),
(1017, 'cereza premium', 'fruta', 'bolsa', 18, 30.28, 48.45),
(1018, 'brocoli amarilla', 'verdura', 'bolsa', 93, 32.63, 52.21),
(1019, 'guanabana roja', 'fruta', 'manojo', 66, 25.27, 40.43),
(1020, 'ejote roja', 'verdura', 'bolsa', 81, 46.07, 73.71),
(1021, 'platano importada', 'fruta', 'bolsa', 63, 47.05, 75.28),
(1022, 'apio bolsa', 'verdura', 'manojo', 92, 29.25, 46.8),
(1023, 'mamey nacional', 'fruta', 'bolsa', 64, 22.6, 36.16),
(1024, 'lechuga chica', 'verdura', 'kilogramo', 15, 30.73, 49.17),
(1025, 'mamey amarilla', 'fruta', 'kilogramo', 25, 48.3, 77.28),
(1026, 'betabel amarilla', 'verdura', 'kilogramo', 75, 40.03, 64.05),
(1027, 'limon verde', 'fruta', 'kilogramo', 74, 43.15, 69.04),
(1028, 'espinaca bolsa', 'verdura', 'bolsa', 70, 21.6, 34.56),
(1029, 'mamey bolsa', 'fruta', 'pieza', 35, 36.26, 58.02),
(1030, 'chayote chica', 'verdura', 'pieza', 15, 36.5, 58.4),
(1031, 'mamey premium', 'fruta', 'kilogramo', 56, 33.92, 54.27),
(1032, 'nopales amarilla', 'verdura', 'bolsa', 64, 23.05, 36.88),
(1033, 'durazno importada', 'fruta', 'pieza', 32, 45.81, 73.3),
(1034, 'espinaca importada', 'verdura', 'manojo', 21, 13.37, 21.39),
(1035, 'mamey kg', 'fruta', 'kilogramo', 30, 20.32, 32.51),
(1036, 'acelga amarilla', 'verdura', 'kilogramo', 46, 26.84, 42.94),
(1037, 'kiwi chica', 'fruta', 'kilogramo', 22, 27.0, 43.2),
(1038, 'apio chica', 'verdura', 'bolsa', 79, 45.81, 73.3),
(1039, 'piña chica', 'fruta', 'manojo', 82, 13.45, 21.52),
(1040, 'cilantro nacional', 'verdura', 'bolsa', 26, 31.9, 51.04),
(1041, 'kiwi nacional', 'fruta', 'manojo', 68, 40.09, 64.14),
(1042, 'coliflor chica', 'verdura', 'bolsa', 40, 49.47, 79.15),
(1043, 'frambuesa premium', 'fruta', 'bolsa', 53, 43.42, 69.47),
(1044, 'calabacita kg', 'verdura', 'bolsa', 97, 44.12, 70.59),
(1045, 'zapote nacional', 'fruta', 'pieza', 94, 28.8, 46.08),
(1046, 'betabel importada', 'verdura', 'kilogramo', 63, 41.47, 66.35),
(1047, 'mamey kg', 'fruta', 'pieza', 95, 22.3, 35.68),
(1048, 'pepino premium', 'verdura', 'pieza', 22, 43.31, 69.3),
(1049, 'zapote amarilla', 'fruta', 'manojo', 25, 36.95, 59.12),
(1050, 'chayote bolsa', 'verdura', 'manojo', 71, 27.77, 44.43),
(1051, 'mamey premium', 'fruta', 'kilogramo', 93, 46.0, 73.6),
(1052, 'champiñon bolsa', 'verdura', 'pieza', 71, 28.2, 45.12),
(1053, 'pera kg', 'fruta', 'kilogramo', 36, 17.24, 27.58),
(1054, 'nopales kg', 'verdura', 'kilogramo', 16, 19.54, 31.26),
(1055, 'zarzamora grande', 'fruta', 'bolsa', 71, 43.12, 68.99);

INSERT INTO proveedor (id_p, nombre, ciudad, contacto, tel_contacto) VALUES
(2001, 'Agroindustrias del Valle', 'Oaxaca', 'Lucia Lopez', '9516306668'),
(2002, 'Frutas Selectas del Sur', 'Puebla', 'Miguel Ramos', '9516093866'),
(2003, 'Comercializadora Verde', 'Veracruz', 'Elena Diaz', '9514488840'),
(2004, 'Hortalizas de México', 'Tehuacán', 'Eduardo Castro', '9514918405'),
(2005, 'Campo Fresco S.A.', 'Oaxaca', 'Pilar Castillo', '9517797829'),
(2006, 'Distribuidora La Soledad', 'Oaxaca', 'Manuel Aguilar', '9518820384'),
(2007, 'Frutería Mayorista del Centro', 'Puebla', 'Jorge Blanco', '9519757210'),
(2008, 'Agroexportadora Mixteca', 'Huajuapan', 'Jose Alvarez', '9513343288'),
(2009, 'El Huerto de Don Pepe', 'Atlixco', 'Francisco Reyes', '9512212652'),
(2010, 'Verduras del Istmo', 'Juchitán', 'Antonio Ruiz', '9511732485'),
(2011, 'Productores Unidos de la Sierra', 'Ixtlán', 'Juan Castro', '9519969866'),
(2012, 'Organicos de la Costa', 'Puerto Escondido', 'Roberto Bravo', '9518550070'),
(2013, 'Mercado de Abastos Oriente', 'Mexico DF', 'Patricia Guerrero', '9517123923'),
(2014, 'Central de Abasto Puebla', 'Puebla', 'Raul Moreno', '9518369110'),
(2015, 'Frutas Exóticas de Chiapas', 'Tuxtla', 'Andrea Torres', '9514067965'),
(2016, 'Invernaderos San Antonio', 'Texcoco', 'Patricia Jimenez', '9511931471'),
(2017, 'Rancho El Paraíso', 'Tuxtepec', 'Pilar Fernandez', '9513947873'),
(2018, 'Agricola Santa Maria', 'Santa Maria', 'Rosa Hernandez', '9516019890'),
(2019, 'Grupo Citrícola del Golfo', 'Martínez de la Torre', 'Antonio Soto', '9512952673'),
(2020, 'Manzanas de Zacatlán', 'Zacatlán', 'Ana Flores', '9515038440'),
(2021, 'Fresas de Irapuato', 'Irapuato', 'Elizabeth Moreno', '9517216149'),
(2022, 'Aguacates de Michoacán', 'Uruapan', 'Daniel Gomez', '9516454981'),
(2023, 'Tomates de Sinaloa', 'Culiacán', 'Lorena Vazquez', '9519819963'),
(2024, 'Papayas del Pacifico', 'Colima', 'Carlos Jimenez', '9519890711'),
(2025, 'Plátanos de Teapa', 'Teapa', 'Francisco Vargas', '9516813261'),
(2026, 'Agropecuaria Los Altos', 'Tepatitlán', 'Elena Sanchez', '9511270985'),
(2027, 'Vegetales Selectos', 'Celaya', 'Laura Torres', '9512908761'),
(2028, 'Distribuidora San Juan', 'San Juan', 'Rosa Gutierrez', '9514163659'),
(2029, 'Frutas y Legumbres Lopez', 'Oaxaca', 'Lucia Salazar', '9519867608'),
(2030, 'La Cosecha Perfecta', 'Puebla', 'Monica Rivera', '9513797429'),
(2031, 'Del Campo a su Mesa', 'Tehuacán', 'David Blanco', '9515313851'),
(2032, 'NutriVegetales', 'Orizaba', 'Juan Moreno', '9514161429'),
(2033, 'Sabor Natural', 'Córdoba', 'Guadalupe Delgado', '9511408196'),
(2034, 'BioFrutas', 'Xalapa', 'Patricia Romero', '9517370045'),
(2035, 'EcoGranja', 'Coatepec', 'Fernanda Mendez', '9512097536'),
(2036, 'El Bodegón de la Fruta', 'Minatitlán', 'Raul Domínguez', '9511824310'),
(2037, 'Abastecedora de Restaurantes', 'Oaxaca', 'Raul Morales', '9518276103'),
(2038, 'Provedora Gastronómica', 'Puebla', 'Juan Romero', '9514935312'),
(2039, 'Insumos Frescos', 'Oaxaca', 'Carmen Morales', '9516671478'),
(2040, 'La Huerta Familiar', 'Etla', 'Adriana Luna', '9518971567'),
(2041, 'Cultivos Hidropónicos', 'Ocotlán', 'Andrea Morales', '9517139887'),
(2042, 'Frutales del Valle', 'Zaachila', 'Pedro Domínguez', '9512134559'),
(2043, 'Verduras Finas', 'San Felipe', 'Jose Romero', '9511982854'),
(2044, 'El Rey del Tomate', 'Puebla', 'Lucia Blanco', '9518734922'),
(2045, 'La Casa de la Manzana', 'Zacatlán', 'Arturo Guerrero', '9511119517'),
(2046, 'Citricos Mexicanos', 'Veracruz', 'Eduardo Ramirez', '9515691357'),
(2047, 'Legumbres del Sol', 'Sonora', 'Manuel Jimenez', '9519196609'),
(2048, 'Frutas Tropicales', 'Tabasco', 'Lorena Castillo', '9513995579'),
(2049, 'AgroAlimentos', 'Jalisco', 'Miguel Vargas', '9512608447'),
(2050, 'Distribuidora Nacional', 'Monterrey', 'Gabriel Ramos', '9513250656'),
(2051, 'Campo y Vida', 'Chiapas', 'Lucia Castillo', '9518082318'),
(2052, 'Productor Agricola Global 52', 'Oaxaca', 'Silvia Castillo', '9517255447'),
(2053, 'Productor Agricola Global 53', 'Oaxaca', 'Fernanda Reyes', '9517590488'),
(2054, 'Productor Agricola Global 54', 'Oaxaca', 'Sofia Rodriguez', '9514185900'),
(2055, 'Productor Agricola Global 55', 'Oaxaca', 'Antonio Perez', '9518810358');

INSERT INTO producto_proveedor (codigo, id_p) VALUES
(1001, 2055),
(1002, 2023),
(1003, 2040),
(1004, 2006),
(1005, 2007),
(1006, 2022),
(1007, 2015),
(1008, 2017),
(1009, 2020),
(1010, 2017),
(1011, 2045),
(1012, 2037),
(1013, 2015),
(1014, 2010),
(1015, 2001),
(1016, 2045),
(1017, 2051),
(1018, 2016),
(1019, 2013),
(1020, 2051),
(1021, 2045),
(1022, 2014),
(1023, 2010),
(1024, 2034),
(1025, 2002),
(1026, 2053),
(1027, 2031),
(1028, 2026),
(1029, 2019),
(1030, 2017),
(1031, 2037),
(1032, 2044),
(1033, 2021),
(1034, 2043),
(1035, 2016),
(1036, 2041),
(1037, 2008),
(1038, 2012),
(1039, 2018),
(1040, 2052),
(1041, 2038),
(1042, 2047),
(1043, 2001),
(1044, 2003),
(1045, 2037),
(1046, 2036),
(1047, 2047),
(1048, 2013),
(1049, 2046),
(1050, 2027),
(1051, 2037),
(1052, 2049),
(1053, 2019),
(1054, 2030),
(1055, 2035);

INSERT INTO cliente (id_c, telefono, rfc, domicilio) VALUES
(3001, '5527509141', 'RFC001GEN', 'Calle Galeana #682, Centro'),
(3002, '5531464198', 'RFC002GEN', 'Calle Republica #428, Centro'),
(3003, '5552690121', 'RFC003GEN', 'Calle 5 de Mayo #572, Centro'),
(3004, '5530599850', 'RFC004GEN', 'Calle Republica #275, Centro'),
(3005, '5549337280', 'RFC005GEN', 'Calle Independencia #217, Centro'),
(3006, '5556614030', 'RFC006GEN', 'Calle Juarez #910, Centro'),
(3007, '5574806053', 'RFC007GEN', 'Calle 20 de Noviembre #319, Centro'),
(3008, '5555778548', 'RFC008GEN', 'Calle 20 de Noviembre #547, Centro'),
(3009, '5553505627', 'RFC009GEN', 'Calle Benito Juarez #634, Centro'),
(3010, '5580776323', 'RFC010GEN', 'Calle Revolucion #447, Centro'),
(3011, '5544932583', 'RFC011GEN', 'Calle Matamoros #799, Centro'),
(3012, '5525720753', 'RFC012GEN', 'Calle 20 de Noviembre #211, Centro'),
(3013, '5561556745', 'RFC013GEN', 'Calle Insurgentes #442, Centro'),
(3014, '5569148015', 'RFC014GEN', 'Calle Reforma #521, Centro'),
(3015, '5526551590', 'RFC015GEN', 'Calle Bravo #110, Centro'),
(3016, '5554616884', 'RFC016GEN', 'Calle Guerrero #332, Centro'),
(3017, '5554502057', 'RFC017GEN', 'Calle Guerrero #834, Centro'),
(3018, '5575968710', 'RFC018GEN', 'Calle Hidalgo #680, Centro'),
(3019, '5582800561', 'RFC019GEN', 'Calle Republica #484, Centro'),
(3020, '5547386631', 'RFC020GEN', 'Calle Constitucion #758, Centro'),
(3021, '5510442732', 'RFC021GEN', 'Calle Emiliano Zapata #606, Centro'),
(3022, '5571472977', 'RFC022GEN', 'Calle Reforma #380, Centro'),
(3023, '5599689950', 'RFC023GEN', 'Calle Insurgentes #264, Centro'),
(3024, '5511451454', 'RFC024GEN', 'Calle Zaragoza #945, Centro'),
(3025, '5596445067', 'RFC025GEN', 'Calle Benito Juarez #571, Centro'),
(3026, '5587657960', 'RFC026GEN', 'Calle Guerrero #715, Centro'),
(3027, '5561516782', 'RFC027GEN', 'Calle Matamoros #115, Centro'),
(3028, '5542842886', 'RFC028GEN', 'Calle 5 de Mayo #216, Centro'),
(3029, '5579726661', 'RFC029GEN', 'Calle Pino Suarez #756, Centro'),
(3030, '5597973449', 'RFC030GEN', 'Calle 16 de Septiembre #700, Centro'),
(3031, '5535086281', 'RFC031GEN', 'Calle Constitucion #796, Centro'),
(3032, '5527903012', 'RFC032GEN', 'Calle Reforma #133, Centro'),
(3033, '5575380697', 'RFC033GEN', 'Calle Iturbide #721, Centro'),
(3034, '5575492085', 'RFC034GEN', 'Calle Guerrero #484, Centro'),
(3035, '5590629117', 'RFC035GEN', 'Calle Guerrero #861, Centro'),
(3036, '5590500879', 'RFC036GEN', 'Calle Emiliano Zapata #573, Centro'),
(3037, '5578912487', 'RFC037GEN', 'Calle Revolucion #842, Centro'),
(3038, '5573046276', 'RFC038GEN', 'Calle Republica #998, Centro'),
(3039, '5592556379', 'RFC039GEN', 'Calle Independencia #113, Centro'),
(3040, '5598644717', 'RFC040GEN', 'Calle 16 de Septiembre #988, Centro'),
(3041, '5557782196', 'RFC041GEN', 'Calle Allende #765, Centro'),
(3042, '5579621784', 'RFC042GEN', 'Calle Pino Suarez #123, Centro'),
(3043, '5537737027', 'RFC043GEN', 'Calle Emiliano Zapata #257, Centro'),
(3044, '5525104981', 'RFC044GEN', 'Calle Morelos #795, Centro'),
(3045, '5526778305', 'RFC045GEN', 'Calle Zaragoza #569, Centro'),
(3046, '5555005086', 'RFC046GEN', 'Calle 5 de Mayo #633, Centro'),
(3047, '5542231368', 'RFC047GEN', 'Calle Bravo #524, Centro'),
(3048, '5571207189', 'RFC048GEN', 'Calle Madero #925, Centro'),
(3049, '5572583366', 'RFC049GEN', 'Calle Insurgentes #659, Centro'),
(3050, '5529038560', 'RFC050GEN', 'Calle Emiliano Zapata #387, Centro'),
(3051, '5549136169', 'RFC051GEN', 'Calle Independencia #986, Centro'),
(3052, '5582949472', 'RFC052GEN', 'Calle Constitucion #580, Centro'),
(3053, '5559034277', 'RFC053GEN', 'Calle Aldama #359, Centro'),
(3054, '5528404668', 'RFC054GEN', 'Calle Iturbide #256, Centro'),
(3055, '5583464480', 'RFC055GEN', 'Calle 20 de Noviembre #492, Centro');

INSERT INTO p_moral (id_c, razon_social) VALUES
(3001, 'Restaurante Casa Oaxaca'),
(3003, 'Hotel Misión de los Ángeles'),
(3005, 'Comedor Familiar La Tía'),
(3007, 'Taquería El Primo'),
(3009, 'Juguería La Salud'),
(3011, 'Cafetería La Brújula'),
(3013, 'Hotel Victoria'),
(3015, 'Hostal de la Noria'),
(3017, 'Fonda Florecita'),
(3019, 'Restaurante Los Danzantes'),
(3021, 'Mercado Orgánico El Pochote'),
(3023, 'Escuela Culinaria de Oaxaca'),
(3025, 'Hospital Civil (Cocina)'),
(3027, 'Guardería Infantil Pasitos'),
(3029, 'Residencia de Adultos Mayores'),
(3031, 'Comedor Industrial Bimbo'),
(3033, 'Restaurante La Olla'),
(3035, 'Tlayudas Doña Flavia'),
(3037, 'Mariscos El Pescador'),
(3039, 'Catering Eventos Especiales'),
(3041, 'Hotel Fortín Plaza'),
(3043, 'Panadería La Bamby'),
(3045, 'Pastelería Carmelita'),
(3047, 'Restaurante El Asador'),
(3049, 'Buffet La Gran Fiesta'),
(3051, 'Cocina Económica Doña Mari'),
(3053, 'Café Blasón'),
(3055, 'Restaurante Catedral');

INSERT INTO p_fisica (id_c, nombre) VALUES
(3002, 'Arturo Flores'),
(3004, 'Miguel Reyes'),
(3006, 'Patricia Chavez'),
(3008, 'Ana Torres'),
(3010, 'Gabriela Blanco'),
(3012, 'Ricardo Blanco'),
(3014, 'Leticia Vargas'),
(3016, 'Gerardo Ortega'),
(3018, 'Elena Martinez'),
(3020, 'Pilar Ruiz'),
(3022, 'Miguel Gomez'),
(3024, 'Leticia Fernandez'),
(3026, 'Luis Rios'),
(3028, 'Sergio Rivera'),
(3030, 'Lorena Vargas'),
(3032, 'Jose Chavez'),
(3034, 'Lucia Jimenez'),
(3036, 'Pilar Rivera'),
(3038, 'Adriana Rodriguez'),
(3040, 'Juan Chavez'),
(3042, 'Claudia Diaz'),
(3044, 'Andrea Gonzalez'),
(3046, 'Leticia Soto'),
(3048, 'Claudia Rivera'),
(3050, 'Gabriel Castillo'),
(3052, 'Pilar Jimenez'),
(3054, 'Alejandro Medina');

INSERT INTO empleado (id_e, nombre, turno, salario, username, rol, is_active) VALUES
(7000, 'Edwin Noe', 'matutino', 15000, 'edwin', 'administrador', true),
(1, 'System Administrator', 'Completo', 0.00, 'admin', 'administrador', true),
(7001, 'Carlos Castro', 'matutino', 5000, 'ccastro', 'almacenista', true),
(7002, 'Elizabeth Guzman', 'matutino', 5000, 'eguzman', 'almacenista', true),
(7003, 'David Reyes', 'matutino', 5000, 'dreyes', 'almacenista', true),
(7004, 'Daniel Delgado', 'matutino', 5000, 'ddelgado', 'vendedor', true),
(7005, 'Sofia Ortiz', 'matutino', 5000, 'sortiz', 'vendedor', true),
(7006, 'Margarita Garcia', 'matutino', 5000, 'mgarcia', 'vendedor', true),
(7007, 'Gerardo Morales', 'matutino', 5000, 'gmorales', 'vendedor', true),
(7008, 'Fernanda Reyes', 'matutino', 5000, 'freyes', 'vendedor', true),
(7009, 'David Fernandez', 'matutino', 5000, 'dfernandez', 'vendedor', true),
(7010, 'Fernando Ruiz', 'matutino', 5000, 'fruiz', 'vendedor', true),
(7011, 'Elena Martinez', 'matutino', 5000, 'emartinez', 'almacenista', true),
(7012, 'Laura Diaz', 'matutino', 5000, 'ldiaz', 'almacenista', true),
(7013, 'Jorge Cruz', 'matutino', 5000, 'jcruz', 'almacenista', true),
(7014, 'Carlos Flores', 'matutino', 5000, 'cflores', 'vendedor', true),
(7015, 'Veronica Jimenez', 'matutino', 5000, 'vjimenez', 'almacenista', true),
(7016, 'Pedro Aguilar', 'matutino', 5000, 'paguilar', 'vendedor', true),
(7017, 'Claudia Rivera', 'matutino', 5000, 'crivera', 'vendedor', true),
(7018, 'Alejandro Rivera', 'matutino', 5000, 'arivera', 'almacenista', true),
(7019, 'Veronica Gonzalez', 'matutino', 5000, 'vgonzalez', 'vendedor', true),
(7020, 'Pedro Rios', 'matutino', 5000, 'prios', 'vendedor', true),
(7021, 'Claudia Lara', 'matutino', 5000, 'clara', 'supervisor', true),
(7022, 'Veronica Jimenez', 'matutino', 5000, 'vjimenez22', 'almacenista', true),
(7023, 'Claudia Soto', 'matutino', 5000, 'csoto', 'vendedor', true),
(7024, 'Adriana Fernandez', 'matutino', 5000, 'afernandez', 'almacenista', true),
(7025, 'Alejandro Sanchez', 'matutino', 5000, 'asanchez', 'vendedor', true),
(7026, 'Manuel Ramirez', 'matutino', 5000, 'mramirez', 'vendedor', true),
(7027, 'Ricardo Soto', 'matutino', 5000, 'rsoto', 'supervisor', true),
(7028, 'Rosa Estrada', 'matutino', 5000, 'restrada', 'vendedor', true),
(7029, 'Patricia Cruz', 'matutino', 5000, 'pcruz', 'almacenista', true),
(7030, 'Adriana Mendez', 'matutino', 5000, 'amendez', 'vendedor', true),
(7031, 'Leticia Reyes', 'matutino', 5000, 'lreyes', 'almacenista', true),
(7032, 'Leticia Ramos', 'matutino', 5000, 'lramos', 'almacenista', true),
(7033, 'Gabriel Jimenez', 'matutino', 5000, 'gjimenez', 'vendedor', true),
(7034, 'Antonio Guerrero', 'matutino', 5000, 'aguerrero', 'almacenista', true),
(7035, 'Gabriel Rios', 'matutino', 5000, 'grios', 'almacenista', true),
(7036, 'Maria Ruiz', 'matutino', 5000, 'mruiz', 'vendedor', true),
(7037, 'Luis Aguilar', 'matutino', 5000, 'laguilar', 'almacenista', true),
(7038, 'Jose Garcia', 'matutino', 5000, 'jgarcia', 'vendedor', true),
(7039, 'Pilar Romero', 'matutino', 5000, 'promero', 'almacenista', true),
(7040, 'Claudia Hernandez', 'matutino', 5000, 'chernandez', 'vendedor', true),
(7041, 'Andrea Guzman', 'matutino', 5000, 'aguzman', 'vendedor', true),
(7042, 'Veronica Estrada', 'matutino', 5000, 'vestrada', 'almacenista', true),
(7043, 'Sofia Flores', 'matutino', 5000, 'sflores', 'almacenista', true),
(7044, 'Eduardo Fernandez', 'matutino', 5000, 'efernandez', 'vendedor', true),
(7045, 'Gabriela Gonzalez', 'matutino', 5000, 'ggonzalez', 'vendedor', true),
(7046, 'Pedro Rivera', 'matutino', 5000, 'privera', 'vendedor', true),
(7047, 'Pedro Guerrero', 'matutino', 5000, 'pguerrero', 'vendedor', true),
(7048, 'Veronica Ramirez', 'matutino', 5000, 'vramirez', 'almacenista', true),
(7049, 'Andrea Fernandez', 'matutino', 5000, 'afernandez49', 'vendedor', true),
(7050, 'David Blanco', 'matutino', 5000, 'dblanco', 'vendedor', true),
(7051, 'Adriana Delgado', 'matutino', 5000, 'adelgado', 'vendedor', true),
(7052, 'Daniel Diaz', 'matutino', 5000, 'ddiaz', 'vendedor', true),
(7053, 'Claudia Mendoza', 'matutino', 5000, 'cmendoza', 'vendedor', true),
(7054, 'Francisco Lara', 'matutino', 5000, 'flara', 'almacenista', true),
(7055, 'Margarita Torres', 'matutino', 5000, 'mtorres', 'vendedor', true);

INSERT INTO supervisor (id_e, id_s) VALUES
(7001, 7021),
(7002, 7027),
(7003, 7021),
(7004, 7021),
(7005, 7021),
(7006, 7021),
(7007, 7027),
(7008, 7027),
(7009, 7027),
(7010, 7021),
(7011, 7021),
(7012, 7021),
(7013, 7027),
(7014, 7021),
(7015, 7027),
(7016, 7027),
(7017, 7021),
(7018, 7027),
(7019, 7021),
(7020, 7021),
(7022, 7021),
(7023, 7027),
(7024, 7021),
(7025, 7021),
(7026, 7021),
(7028, 7027),
(7029, 7021),
(7030, 7027),
(7031, 7021),
(7032, 7021),
(7033, 7021),
(7034, 7027),
(7035, 7021),
(7036, 7027),
(7037, 7021),
(7038, 7027),
(7039, 7021),
(7040, 7027),
(7041, 7027),
(7042, 7021),
(7043, 7021),
(7044, 7021),
(7045, 7021),
(7046, 7027),
(7047, 7021),
(7048, 7027),
(7049, 7021),
(7050, 7027),
(7051, 7027),
(7052, 7021),
(7053, 7021),
(7054, 7027),
(7055, 7027);

INSERT INTO venta (folio_v, fecha, id_c, id_e) VALUES
(1, '2025-01-01', 3020, 7020),
(2, '2025-01-02', 3014, 7002),
(3, '2025-01-03', 3003, 7012),
(4, '2025-01-04', 3028, 7030),
(5, '2025-01-05', 3019, 7054),
(6, '2025-01-06', 3005, 7054),
(7, '2025-01-07', 3035, 7027),
(8, '2025-01-08', 3019, 7044),
(9, '2025-01-09', 3007, 7007),
(10, '2025-01-10', 3017, 7001),
(11, '2025-01-11', 3017, 7054),
(12, '2025-01-12', 3003, 7025),
(13, '2025-01-13', 3048, 7053),
(14, '2025-01-14', 3016, 7028),
(15, '2025-01-15', 3040, 7002),
(16, '2025-01-16', 3037, 7038),
(17, '2025-01-17', 3009, 7041),
(18, '2025-01-18', 3046, 7055),
(19, '2025-01-19', 3055, 7007),
(20, '2025-01-20', 3039, 7034),
(21, '2025-01-21', 3035, 7043),
(22, '2025-01-22', 3022, 7037),
(23, '2025-01-23', 3055, 7031),
(24, '2025-01-24', 3017, 7043),
(25, '2025-01-25', 3033, 7010),
(26, '2025-01-26', 3049, 7026),
(27, '2025-01-27', 3028, 7042),
(28, '2025-01-28', 3053, 7038),
(29, '2025-01-29', 3039, 7036),
(30, '2025-01-30', 3017, 7043),
(31, '2025-01-31', 3032, 7009),
(32, '2025-02-01', 3005, 7007),
(33, '2025-02-02', 3027, 7006),
(34, '2025-02-03', 3036, 7025),
(35, '2025-02-04', 3023, 7029),
(36, '2025-02-05', 3054, 7025),
(37, '2025-02-06', 3018, 7017),
(38, '2025-02-07', 3023, 7005),
(39, '2025-02-08', 3034, 7015),
(40, '2025-02-09', 3032, 7053),
(41, '2025-02-10', 3020, 7029),
(42, '2025-02-11', 3022, 7029),
(43, '2025-02-12', 3013, 7001),
(44, '2025-02-13', 3029, 7040),
(45, '2025-02-14', 3026, 7049),
(46, '2025-02-15', 3009, 7042),
(47, '2025-02-16', 3006, 7028),
(48, '2025-02-17', 3037, 7021),
(49, '2025-02-18', 3009, 7009),
(50, '2025-02-19', 3044, 7002),
(51, '2025-02-20', 3019, 7041),
(52, '2025-02-21', 3024, 7025),
(53, '2025-02-22', 3018, 7035),
(54, '2025-02-23', 3002, 7046),
(55, '2025-02-24', 3019, 7055),
(56, '2025-02-25', 3029, 7015),
(57, '2025-02-26', 3018, 7053),
(58, '2025-02-27', 3031, 7051),
(59, '2025-02-28', 3041, 7036),
(60, '2025-03-01', 3025, 7019);

INSERT INTO detalle_venta (codigo, folio_v, observaciones, cantidad) VALUES
(1008, 1, '', 3),
(1044, 1, '', 1),
(1036, 1, '', 3),
(1040, 1, '', 2),
(1029, 2, '', 1),
(1031, 2, '', 2),
(1041, 3, '', 1),
(1034, 4, '', 1),
(1053, 4, '', 1),
(1018, 4, '', 3),
(1027, 5, '', 2),
(1007, 5, '', 1),
(1040, 6, '', 1),
(1034, 6, '', 3),
(1045, 7, '', 2),
(1001, 7, '', 3),
(1039, 8, '', 2),
(1020, 8, '', 1),
(1037, 9, '', 1),
(1031, 9, '', 1),
(1021, 9, '', 1),
(1051, 10, '', 1),
(1043, 10, '', 1),
(1033, 10, '', 2),
(1055, 11, '', 2),
(1025, 11, '', 2),
(1039, 11, '', 2),
(1008, 12, '', 1),
(1018, 13, '', 1),
(1036, 14, '', 2),
(1047, 15, '', 2),
(1026, 16, '', 2),
(1010, 16, '', 2),
(1039, 16, '', 3),
(1036, 16, '', 3),
(1053, 17, '', 3),
(1003, 17, '', 2),
(1014, 17, '', 1),
(1044, 18, '', 3),
(1039, 18, '', 1),
(1004, 18, '', 2),
(1006, 19, '', 1),
(1043, 19, '', 2),
(1020, 20, '', 1),
(1025, 20, '', 1),
(1010, 20, '', 1),
(1027, 20, '', 2),
(1016, 21, '', 2),
(1037, 21, '', 3),
(1009, 22, '', 2),
(1047, 22, '', 1),
(1020, 23, '', 3),
(1003, 23, '', 2),
(1040, 24, '', 3),
(1013, 24, '', 3),
(1009, 24, '', 2),
(1007, 25, '', 2),
(1002, 25, '', 2),
(1014, 25, '', 3),
(1050, 25, '', 3),
(1041, 26, '', 1),
(1037, 26, '', 1),
(1001, 26, '', 3),
(1028, 26, '', 2),
(1044, 27, '', 1),
(1028, 28, '', 2),
(1006, 28, '', 3),
(1007, 29, '', 2),
(1017, 30, '', 2),
(1020, 30, '', 3),
(1004, 31, '', 1),
(1050, 31, '', 1),
(1019, 31, '', 3),
(1033, 31, '', 3),
(1017, 32, '', 1),
(1045, 32, '', 1),
(1020, 32, '', 2),
(1046, 33, '', 3),
(1036, 33, '', 1),
(1010, 33, '', 1),
(1052, 33, '', 2),
(1022, 34, '', 1),
(1035, 35, '', 2),
(1029, 35, '', 2),
(1044, 36, '', 2),
(1049, 36, '', 2),
(1036, 36, '', 2),
(1041, 37, '', 1),
(1037, 37, '', 3),
(1035, 37, '', 3),
(1053, 37, '', 3),
(1023, 38, '', 1),
(1053, 39, '', 2),
(1048, 39, '', 2),
(1024, 39, '', 1),
(1006, 39, '', 1),
(1022, 40, '', 3),
(1046, 40, '', 1),
(1028, 40, '', 3),
(1038, 40, '', 2),
(1001, 41, '', 1),
(1036, 41, '', 2),
(1025, 41, '', 3),
(1017, 42, '', 2),
(1039, 42, '', 1),
(1052, 42, '', 1),
(1004, 42, '', 1),
(1046, 43, '', 2),
(1002, 43, '', 3),
(1026, 44, '', 1),
(1010, 45, '', 3),
(1040, 45, '', 3),
(1019, 45, '', 2),
(1005, 45, '', 1),
(1024, 46, '', 1),
(1045, 46, '', 2),
(1051, 47, '', 1),
(1039, 47, '', 2),
(1039, 48, '', 1),
(1002, 48, '', 1),
(1026, 48, '', 1),
(1027, 48, '', 3),
(1051, 49, '', 3),
(1022, 49, '', 2),
(1048, 50, '', 1),
(1008, 51, '', 1),
(1015, 51, '', 1),
(1004, 52, '', 1),
(1034, 52, '', 1),
(1028, 52, '', 2),
(1034, 53, '', 1),
(1027, 53, '', 3),
(1045, 53, '', 3),
(1015, 54, '', 2),
(1008, 55, '', 2),
(1039, 55, '', 1),
(1022, 55, '', 3),
(1012, 56, '', 1),
(1005, 56, '', 2),
(1010, 56, '', 3),
(1039, 56, '', 3),
(1001, 57, '', 2),
(1034, 57, '', 2),
(1053, 57, '', 1),
(1023, 57, '', 2),
(1037, 58, '', 2),
(1054, 58, '', 1),
(1005, 58, '', 3),
(1018, 59, '', 3),
(1055, 59, '', 3),
(1024, 59, '', 3),
(1014, 60, '', 2),
(1017, 60, '', 3),
(1031, 60, '', 3);

INSERT INTO compra (folio_c, no_lote, fecha, id_p, id_e) VALUES
(8000, 6972, '2025-03-14', 2032, 7055),
(8001, 1514, '2025-04-09', 2007, 7012),
(8002, 6029, '2025-01-16', 2028, 7020),
(8003, 8824, '2025-03-07', 2049, 7004),
(8004, 4520, '2025-02-26', 2002, 7004),
(8005, 7358, '2025-01-19', 2041, 7017),
(8006, 9386, '2025-02-13', 2013, 7045),
(8007, 4035, '2025-03-18', 2009, 7019),
(8008, 5315, '2025-02-10', 2045, 7010),
(8009, 1724, '2025-02-28', 2013, 7021),
(8010, 4054, '2025-02-14', 2002, 7033),
(8011, 8061, '2025-01-08', 2027, 7040),
(8012, 2229, '2025-03-19', 2049, 7036),
(8013, 9852, '2025-01-16', 2006, 7006),
(8014, 7195, '2025-01-06', 2023, 7046),
(8015, 2227, '2025-01-22', 2001, 7024),
(8016, 3913, '2025-02-06', 2005, 7031),
(8017, 2809, '2025-01-01', 2023, 7037),
(8018, 2008, '2025-02-26', 2022, 7016),
(8019, 9901, '2025-02-25', 2015, 7011),
(8020, 3117, '2025-03-28', 2026, 7033),
(8021, 8815, '2025-03-12', 2028, 7043),
(8022, 1516, '2025-01-07', 2043, 7044),
(8023, 6487, '2025-01-07', 2013, 7003),
(8024, 1840, '2025-01-31', 2011, 7052),
(8025, 7792, '2025-01-05', 2022, 7038),
(8026, 7385, '2025-02-10', 2006, 7019),
(8027, 8971, '2025-03-30', 2035, 7051),
(8028, 1155, '2025-02-05', 2003, 7024),
(8029, 1120, '2025-01-26', 2025, 7051),
(8030, 3383, '2025-01-26', 2054, 7047),
(8031, 3994, '2025-04-07', 2018, 7021),
(8032, 6178, '2025-04-11', 2010, 7039),
(8033, 1102, '2025-03-02', 2053, 7030),
(8034, 5270, '2025-02-19', 2047, 7032),
(8035, 4643, '2025-03-13', 2043, 7016),
(8036, 8853, '2025-04-09', 2005, 7001),
(8037, 1884, '2025-01-22', 2006, 7007),
(8038, 6741, '2025-01-04', 2048, 7040),
(8039, 4056, '2025-03-10', 2047, 7004),
(8040, 3644, '2025-02-26', 2019, 7016),
(8041, 4313, '2025-01-13', 2012, 7025),
(8042, 9640, '2025-02-25', 2047, 7032),
(8043, 6532, '2025-02-27', 2054, 7041),
(8044, 7409, '2025-04-04', 2004, 7006),
(8045, 2023, '2025-02-21', 2042, 7007),
(8046, 1516, '2025-01-27', 2017, 7004),
(8047, 2371, '2025-02-17', 2031, 7026),
(8048, 6160, '2025-02-16', 2028, 7016),
(8049, 3885, '2025-03-03', 2003, 7020),
(8050, 3194, '2025-02-22', 2028, 7028),
(8051, 2563, '2025-03-29', 2026, 7028),
(8052, 3759, '2025-04-08', 2045, 7000),
(8053, 7541, '2025-04-08', 2047, 7045),
(8054, 2911, '2025-02-08', 2011, 7027),
(8055, 2817, '2025-04-06', 2022, 7044),
(8056, 9591, '2025-02-09', 2036, 7052),
(8057, 1786, '2025-01-02', 2021, 7041),
(8058, 5880, '2025-03-12', 2001, 7006),
(8059, 2201, '2025-03-28', 2025, 7038);

INSERT INTO detalle_compra (folio_c, codigo, cantidad) VALUES
(8000, 1029, 34),
(8001, 1015, 20),
(8002, 1040, 25),
(8003, 1018, 24),
(8004, 1041, 11),
(8005, 1015, 48),
(8006, 1053, 24),
(8007, 1001, 18),
(8008, 1019, 37),
(8009, 1032, 35),
(8010, 1026, 46),
(8011, 1007, 16),
(8012, 1015, 10),
(8013, 1015, 11),
(8014, 1046, 26),
(8015, 1034, 31),
(8016, 1043, 13),
(8017, 1014, 31),
(8018, 1029, 44),
(8019, 1037, 17),
(8020, 1011, 30),
(8021, 1046, 49),
(8022, 1023, 15),
(8023, 1043, 17),
(8024, 1035, 45),
(8025, 1001, 11),
(8026, 1038, 36),
(8027, 1020, 26),
(8028, 1009, 28),
(8029, 1002, 42),
(8030, 1012, 20),
(8031, 1035, 44),
(8032, 1047, 11),
(8033, 1031, 28),
(8034, 1044, 39),
(8035, 1013, 38),
(8036, 1044, 40),
(8037, 1013, 28),
(8038, 1021, 31),
(8039, 1050, 38),
(8040, 1055, 25),
(8041, 1053, 21),
(8042, 1047, 15),
(8043, 1008, 32),
(8044, 1012, 47),
(8045, 1012, 49),
(8046, 1014, 37),
(8047, 1048, 16),
(8048, 1044, 46),
(8049, 1021, 29),
(8050, 1005, 33),
(8051, 1053, 18),
(8052, 1011, 21),
(8053, 1038, 25),
(8054, 1013, 20),
(8055, 1015, 28),
(8056, 1015, 37),
(8057, 1013, 11),
(8058, 1020, 43),
(8059, 1052, 19);


-- Script para sincronizar roles de PostgreSQL con la tabla empleado
SET search_path TO fruteria_db;

-- 1. NO creamos los roles base aquí porque ya existen en la DB (rol_vendedor, etc)
--    Solo aseguramos que funcionen.

-- 2. Función auxiliar actualizada para usar el prefijo 'rol_'
CREATE OR REPLACE FUNCTION gestion_usuario_auto(p_username text, p_password text, p_rol text)
RETURNS void AS $$
DECLARE
    v_db_role text;
BEGIN
    -- Map application role to DB role
    CASE p_rol
        WHEN 'vendedor' THEN v_db_role := 'rol_vendedor';
        WHEN 'almacenista' THEN v_db_role := 'rol_almacenista';
        WHEN 'supervisor' THEN v_db_role := 'rol_supervisor';
        WHEN 'administrador' THEN v_db_role := 'rol_admin';
        ELSE v_db_role := 'rol_vendedor'; -- Fallback
    END CASE;

    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = p_username) THEN
        EXECUTE format('CREATE USER %I WITH PASSWORD %L LOGIN IN ROLE %I', p_username, p_password, v_db_role);
    ELSE
        -- Actualizar password
        EXECUTE format('ALTER USER %I WITH PASSWORD %L', p_username, p_password);
        
        -- Asignar nuevo rol (simple grant)
        EXECUTE format('GRANT %I TO %I', v_db_role, p_username);
    END IF;
    
    -- Dar permiso a postgres para impersonar
    EXECUTE format('GRANT %I TO postgres', p_username);
END;
$$ LANGUAGE plpgsql;

-- 3. Iterar y Crear
DO $$
DECLARE
    emp RECORD;
BEGIN
    FOR emp IN SELECT username, rol FROM empleado WHERE username IS NOT NULL LOOP
        -- Password '123' para todos
        PERFORM gestion_usuario_auto(emp.username, '123', emp.rol);
    END LOOP;
END
$$;

DROP FUNCTION gestion_usuario_auto(text, text, text);

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
SET search_path TO fruteria_db;

-- Fix: Allow Almacenista to INSERT new products
GRANT INSERT ON producto TO rol_almacenista;
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

-- PATCH: Add password column for Application-Level Auth
SET search_path TO fruteria_db;
ALTER TABLE empleado ADD COLUMN password VARCHAR(100) DEFAULT '123';
UPDATE empleado SET password = '123';
