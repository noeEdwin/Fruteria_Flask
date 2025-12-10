SET search_path TO fruteria_db;

-- Fix: Allow Almacenista to INSERT new products
GRANT INSERT ON producto TO rol_almacenista;
