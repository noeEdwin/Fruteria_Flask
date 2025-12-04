
-- Script DML adaptado para la base de datos fruteria_db
-- Se asume el esquema definido en fruteria_ddl (con columnas extra en empleado)

SET search_path TO fruteria_db;

-- Limpiar datos existentes (opcional, para evitar duplicados si se corre varias veces)
-- TRUNCATE TABLE detalle_compra, compra, detalle_venta, venta, supervisor, empleado, p_fisica, p_moral, cliente, producto_proveedor, proveedor, producto CASCADE;

-- 1. Insertar Productos
INSERT INTO producto (codigo, descripcion, categoria, unidad_medida, existencia, precio_c, precio_v) VALUES 
(5000, 'manzana roja','fruta','kilogramo', 15, 40.50, 65),
(5001, 'manzana verde','fruta','kilogramo', 8, 50, 60),
(5002, 'manzana amarilla','fruta','kilogramo', 10, 35, 50),
(5003, 'pera roja','fruta','kilogramo', 7, 50, 65),
(5004, 'pera de anjou','fruta','kilogramo', 5, 45, 56),
(5005, 'papaya','fruta','kilogramo', 20, 25, 30),
(5006, 'melón','fruta','pieza', 18, 25, 40),
(5007, 'naranja','fruta','kilogramo', 30, 20, 35),
(5008, 'plátano tabasco','fruta','kilogramo', 20, 20, 28),
(5009, 'platano macho','fruta','kilogramo', 30, 18, 28),
(5010, 'piña','fruta','pieza', 13, 32, 45),
(5011, 'calabacita italiana','verdura','kilogramo', 12, 10, 20),
(5012, 'chile serrano','verdura','kilogramo', 5, 15, 20),
(5013, 'chile jalapeño','verdura','kilogramo', 3, 22, 34),
(5014, 'papa','verdura','kilogramo', 20, 19, 27),
(5015, 'espinaca','verdura','ramito', 12, 4, 8),
(5016, 'lechuga romanita','verdura','pieza', 15, 5, 12),
(5017, 'ejote','verdura','kilogramo', 3, 17, 23),
(5018, 'jicama','fruta','kilogramo', 20, 28, 35),
(5019, 'sandia','fruta','kilogramo', 18, 10, 18),
(5020, 'chile poblano','verdura','kilogramo', 5, 35, 50),
(5022, 'limon','fruta','kilogramo', 10, 18, 22),
(5023, 'cebolla','verdura','kilogramo', 5, 18, 23),
(5024, 'tomate rojo','verdura','kilogramo', 30, 15, 23);

-- 2. Insertar Proveedores
INSERT INTO proveedor (id_p, nombre, ciudad, contacto, tel_contacto) VALUES 
(2000, 'la manzanita', 'oaxaca','sr. carlos pérez','9512356789'),
(2001, 'la poblanita', 'puebla','sra. guadalupe hernández','2221357698'),
(2002, 'disribuidor el campo', 'tehuacán','sra. pilar martinez','2385763210'),
(2003, 'central de frutas', 'oaxaca','sr. arnulfo lópez','9518041200'),
(2004, 'verduras la guadaluoana', 'puebla','sra. araceli juárez','2223561211'),
(2005, 'surtidora s.a.', 'oaxaca','sr. joaquín solís','9518972344'),
(2006, 'las verduras a su mesa', 'puebla','sra. perla mijangos','2226751201'),
(2007, 'la piña loca', 'oaxaca','sr. fernando ortiz','9515431256'),
(2008, 'la juquilita', 'veracruz','sr. alfonso gómez','2293145798'),
(2009, 'la inmaculada', 'córdoba','sra. maría soriano','2717431155'),
(2010, 'el mango dulce', 'veracruz','sra. juana pascasio','2224671233'),
(2011, 'el sazón poblano', 'tehuacán','sr. jorge buenfil','2382340907'),
(2012, 'la naranjota', 'oaxaca','sra. paola dorantes','9515871244'),
(2013, 'el sazón poblano', 'tehuacán','sr. jorge buenfil','2382340907'),
(2014, 'mixtequita', 'oaxaca','sra. abigail manzano','9518765439'),
(2015, 'el sureño', 'oaxaca','sr. ruben anastasio','9516750908'),
(2016, 'las ánimas', 'tehuacán','sr. juan lópez','2382650078'),
(2017, 'los huacales', 'puebla','sra. bertha gutierrez','2229876501'),
(2018, 'los tenates', 'oaxaca','sra. virginia buenrostro','9512345633'),
(2019, 'frutas y verduras don toño', 'oaxaca','sr. antonio ranírez','9517654388'),
(2020, 'frutería altamirano', 'oaxaca','sr. tomás altamirano','9517659080');

-- 3. Insertar Producto_Proveedor
INSERT INTO producto_proveedor (codigo, id_p) VALUES 
(5000, 2008), (5012, 2019), (5024,2013), (5016,2006), (5015,2006),
(5008, 2015), (5009, 2015), (5001,2003), (5007,2003), (5009,2005),
(5002, 2009), (5010, 2009), (5018,2018), (5019,2015), (5020,2019),
(5003, 2000), (5004, 2000), (5005,2008), (5006,2002), (5010,2020),
(5011, 2003), (5012, 2004), (5013,2003), (5014,2009), (5015,2020);

-- 4. Insertar Clientes
INSERT INTO cliente (id_c, telefono, rfc, domicilio) VALUES 
(3000,'9713234566', 'ABCD123456', 'juárez 505'), 
(3001,'9512067788', 'EFGH789123', 'morelos 1205'),
(3002,'9562899901', 'AIJK345678', 'independencia 2202'),
(3003,'9716234533', 'MABC123456', 'matamoros 345'), 
(3004,'9518231133', 'KLGH789123', 'lindavista 235'),
(3005,'9563214422', 'WZKT345678', 'iturbide 2202'),
(3006,'9713234566', 'ABCD123456', 'juárez 505'), 
(3007,'9518065511', 'AMLN889123', 'pico de orizaba 333'),
(3008,'9571459901', 'OPQR235678', 'anillo periférico 15'),
(3009,'9516451323', 'XYZW234565', 'emiliano zapata 303'), 
(3010,'9512067788', 'IJKH833415', 'emilio carranza 890'),
(3011,'9519870022', 'QRST897654', 'río de la plata 297'),
(3012,'978674532', 'PABC901203', 'justo sierra 1111'), 
(3013,'9516452300', 'MARZ130921', 'cayetano 23'),
(3014,'9589128801', '150623', 'guadalupe hinojosa 2300'),
(3015,'9717234866', 'RTUO170312', 'periférico 5671'), 
(3016,'9585691277', 'HAIO141120', 'alfiles 285'),
(3017,'9514866901', 'ZDOP130630', 'armonía 1302'),
(3018,'9511230907', 'CUBO100418', 'regueira 3456'), 
(3019,'9566231222', 'GPLM110918', 'faisanes 23'),
(3020,'9511599871', 'LEWI170211', 'brasil 803');

-- 5. Insertar Personas Morales
INSERT INTO p_moral (id_c, razon_social) VALUES 
(3000,'la espiga'), (3001,'la calabaza'), (3002, 'grupo frutero'), (3003, 'viandas del centro'),
(3004,'frutas del sur'), (3005,'grupo surtidores del norte'), (3006,'la pera vered'),
(3007,'la central de verduras'), (3008,'frutas la poblana'), (3009,'el mercadito'), 
(3010, 'futeria la tortuga');

-- 6. Insertar Personas Físicas
INSERT INTO p_fisica (id_c, nombre) VALUES 
(3011,'armando pérez'), (3012,'margarita martínez'),(3013,'rogelio medina'), (3014, 'braulio robles'), 
(3015, 'andrés suarez'), (3016,'celia mayoral'), (3017,'mauricio lugo'), (3018,'adriana herrera'), 
(3019,'roberto valladares'), (3020, 'guadalupe santibañez');

-- 7. Insertar Empleados (ADAPTADO: Se agregaron columnas username, is_active, is_staff, is_superuser)
-- Nota: Se generan usernames basados en el nombre. Password se deja NULL o genérico si se requiere.
INSERT INTO empleado (id_e, nombre, turno, salario, username, is_active, is_staff, is_superuser) VALUES 
(7000,'ricardo valencia','matutino',5500, 'rvalencia', true, false, false), 
(7001,'juan gonzález','matutino',5200, 'jgonzalez', true, false, false), 
(7002,'susana lara','matutino',3500, 'slara', true, false, false), 
(7003,'maria fernández','vespertino',5500, 'mfernandez', true, false, false), 
(7004,'andrés rubio','vespertino',4300, 'arubio', true, false, false), 
(7005,'rosalba zárate','vespertino',3800, 'rzarate', true, false, false),
(7006,'bryan smith','matutino',4800, 'bsmith', true, false, false), 
(7007,'will blades','matutino',5100, 'wblades', true, false, false), 
(7008,'cinthya house','matutino',3700, 'chouse', true, false, false),
(7009,'robert de niro','vespertino',5230, 'rdeniro', true, true, false), -- Supervisor
(7010,'william trace','vespertino',3770, 'wtrace', true, false, false), 
(7011,'marie wonk','vespertino',3580, 'mwonk', true, false, false),
(7012,'susan right','matutino',3200, 'sright', true, false, false), 
(7013,'fabricio cortés','matutino',4800, 'fcortes', true, false, false), 
(7014,'randy wells','matutino',4600, 'rwells', true, false, false),
(7015,'maya frost','vespertino',5500, 'mfrost', true, false, false), 
(7016,'ramses white','vespertino',5150, 'rwhite', true, false, false), 
(7017,'rose felp','vespertino',4300, 'rfelp', true, false, false),
(7018,'raúl peniche','matutino',4500, 'rpeniche', true, false, false), 
(7019,'magie swift','matutino',3850, 'mswift', true, false, false), 
(7020,'manuel gómez','matutino',4200, 'mgomez', true, true, false); -- Supervisor

-- 8. Insertar Supervisores
INSERT INTO supervisor (id_e, id_s) VALUES 
(7000,7009),(7001,7009), (7002,7009), (7003,7009), (7004,7009),(7005,7009),(7006,7009),(7007,7009),(7008,7009),
(7010,7020),(7011,7020), (7012,7020), (7013,7020), (7014,7020),(7015,7020),(7016,7020),(7017,7020),(7018,7020),(7019,7020);

-- 9. Insertar Ventas
INSERT INTO venta (folio_v, fecha, id_c, id_e) VALUES 
(1,'2025-01-01',3000, 7010), (2,'2025-01-02',3001,7019),(3,'2025-01-03',3002,7000), (4,'2025-01-04',3003,7001),(5,'2025-01-05',3003,7002),
(6,'2025-02-10',3004, 7011), (7,'2025-02-12',3005,7006),(8,'2025-02-15',3006,7007), (9,'2025-02-17',3007,7008),(10,'2025-02-20',3008,7011),
(11,'2025-03-15',3000, 7001), (12,'2025-03-17',3013,7012),(13,'2025-03-18',3011,7002), (14,'2025-03-20',3016,7017),(15,'2025-03-25',3017,7015), -- Corregido 7071 a 7017 (no existe 7071)
(16,'2025-04-06',3014, 7003), (17,'2025-04-07',3012,7018),(18,'2025-04-08',3014,7011), (19,'2025-04-12',3008,7004),(20,'2025-04-15',3006,7002);

-- 10. Insertar Detalle Venta
INSERT INTO detalle_venta (codigo, folio_v, observaciones, cantidad) VALUES 
(5000,1,'',3), (5013,1,'',2), (5008,1,'',5),
(5004,2,'',1), (5011,2,'',3), (5003,2,'',2),
(5005,3,'',1), (5006,3,'',1), (5007,3,'',1),
(5009,4,'',2), (5007,4,'',1), (5012,4,'',2),
(5001,5,'',1), (5014,5,'',2), (5009,5,'',2),
(5003,6,'',4), (5004,6,'',2), (5016,6,'',5),
(5010,7,'',3), (5011,7,'',2), (5012,7,'',2),
(5001,8,'',1), (5002,8,'',2), (5003,8,'',1),
(5007,9,'',2), (5008,9,'',1), (5014,9,'',2),
(5017,10,'',1), (5018,10,'',2), (5019,10,'',3),
(5008,11,'',2), (5009,11,'',2), (5010,11,'',2),
(5000,12,'',1), (5020,12,'',1), (5015,12,'',1),
(5007,13,'',3), (5009,13,'',2), (5013,13,'',1),
(5017,14,'',2), (5018,14,'',2), (5019,14,'',2),
(5003,15,'',4), (5004,15,'',2), (5016,15,'',5),
(5012,16,'',1), (5013,16,'',2), (5014,16,'',2),
(5005,17,'',1), (5006,17,'',1), (5013,17,'',1),
(5014,18,'',2), (5015,18,'',1), 
(5009,19,'',6), (5020,19,'',3), 
(5008,20,'',3), (5004,20,'',2); 

-- 11. Insertar Compras
INSERT INTO compra (folio_c, no_lote, fecha, id_p, id_e) VALUES 
(8000,4000,'2024-12-01',2015,7002),
(8001,4020,'2024-12-10',2003,7005),
(8002,300,'2024-12-15',2008,7010),
(8003,897,'2024-12-30',2007,7009),
(8004,1250,'2025-01-5',2012,7000),
(8005,8432,'2025-01-8',2005,7001),
(8006,390,'2025-01-11',2010,7006),
(8007,125,'2025-01-16',2011,7002),
(8008,54000,'2025-02-12',2004,7017),
(8009,8234,'2025-02-18',2000,7004),
(8010,565,'2025-02-20',2006,7002),
(8011,1934,'2025-02-21',2013,7005),
(8012,509,'2025-03-01',2002,7015),
(8013,29865,'2025-03-04',2001,7004),
(8014,19823,'2025-03-08',2003,7008),
(8015,2376,'2025-03-01',2016,7011),
(8016,4093,'2025-03-01',2015,7005),
(8017,9870,'2025-04-10',2017,7001),
(8018,5234,'2025-04-12',2005,7002),
(8019,345,'2025-04-15',2012,7018),
(8020,87654,'2025-04-17',2012,7006),
(8021,3123,'2025-05-01',2018,7007),
(8022,1567,'2025-05-03',2004,7008);

-- 12. Insertar Detalle Compra
INSERT INTO detalle_compra (folio_c, codigo, cantidad) VALUES 
(8000, 5018,30),(8000,5017,10),(8000,5005,18),(8000,5010,20),
(8001, 5000,20),(8001,5010,20),(8001,5008,10),(8001,5014,15),
(8002, 5015,40),(8002,5015,20),(8002,5007,22),
(8003, 5006,15),(8003,5005,20),
(8004, 5001,20),(8004,5007,17),(8004,5009,20),(8004,5013,25),
(8005, 5014,10),(8005,5011,15),(8005,5010,26),(8005,5008,30),
(8006, 5008,10),(8006,5009,10),
(8007, 5002,25),(8007,5004,17),(8007,5006,26),
(8008, 5002,20),(8008,5005,20),(8008,5009,10),(8008,5010,10),
(8009, 5003,20),(8009,5005,10),(8009,5007,10),(8009,5012,22),
(8010, 5005,10),(8010,5006,10),(8010,5009,10),
(8011, 5006,20),(8011,5012,20),(8011,5015,20),
(8012, 5002,20),(8012,5013,15),(8012,5004,20),
(8013, 5015,25),(8013,5018,10),(8013,5006,20),
(8014, 5000,15),(8014,5001,10),(8014,5003,10),
(8015, 5004,10),(8015,5005,10),(8015,5006,10),
(8016, 5010,25),(8016,5011,20),(8016,5012,10),
(8017, 5017,20),(8017,5018,20),(8017,5019,15),
(8018, 5001,25),(8018,5019,10),(8018,5020,10),
(8019, 5004,15),(8019,5006,12),(8019,5008,10),
(8020, 5009,20),(8020,5010,15),(8020,5014,18),
(8021, 5000,10),(8020,5002,10),(8021,5006,28),
(8022, 5015,15),(8022,5016,10),(8022,5017,20);
