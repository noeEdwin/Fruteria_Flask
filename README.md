# Frutería - Backend & Base de Datos

Este documento detalla la arquitectura del backend, el diseño de la base de datos y la implementación técnica que garantiza el cumplimiento de los requerimientos del Proyecto Integrador.

## 1. Tecnologías del Backend

*   **Lenguaje**: Python 3.10+
*   **Framework Web**: Flask (Estructura Modular con Blueprints y MVC)
*   **Base de Datos**: PostgreSQL 14+
*   **Driver BD**: `psycopg2-binary`
*   **Autenticación**: Basada en roles de Base de Datos (PostgreSQL Roles) + Flask-Login

## 2. Base de Datos Relacional

El sistema utiliza una base de datos relacional robusta compuesta por **12 tablas** normalizadas, diseñadas para manejar la integridad de los datos y las operaciones de negocio.

### Estructura de Tablas (DDL)

El esquema de la base de datos (`fruteria_ddl`) incluye:

1.  **Entidades Principales**: `producto`, `proveedor`, `cliente`, `empleado`.
2.  **Herencia/Especialización**: `p_fisica` y `p_moral` (heredan de `cliente`), `supervisor` (relación recursiva de `empleado`).
3.  **Transaccionales**: `venta`, `detalle_venta`, `compra`, `detalle_compra`.
4.  **Relaciones N:M**: `producto_proveedor`.

### Matriz de Autorizaciones (Seguridad)

La seguridad se implementa a nivel de base de datos utilizando Roles de PostgreSQL y se refleja en la aplicación mediante `app/routes/auth.py`.

*   **Autenticación Real**: El login (`/login`) intenta conectar a PostgreSQL con el usuario/contraseña proporcionados. Si la conexión falla, el acceso se deniega.
*   **Roles Implementados**:
    *   `vendedor`: Acceso limitado a registrar ventas (INSERT en `venta`).
    *   `almacenista`: Acceso a gestión de productos y compras.
    *   `admin` / `supervisor`: Acceso total al dashboard y reportes.

---

## 3. Cumplimiento de la Rúbrica (Lista de Cotejo)

A continuación, se detalla cómo el backend cumple con cada punto de la lista de cotejo para la interfaz, referenciando los archivos y líneas de código específicos.

| # | Criterio de Evaluación | Implementación en el Backend (Evidencia) | Archivo / Ubicación |
| :--- | :--- | :--- | :--- |
| **1** | **Consulta de al menos 3 tablas reunidas** | Reporte de Ventas: Une `venta` (v), `cliente` (c), `empleado` (e) y `p_moral`/`p_fisica`. | `app/models/venta.py` <br> Función: `get_sales_report()` |
| **2** | **Inserta datos en 3 tablas diferentes** | 1. **Ventas**: Inserta en `venta` y `detalle_venta`. <br> 2. **Productos**: Inserta en `producto`. <br> 3. **Clientes**: Inserta en `cliente` y `p_fisica`/`p_moral`. | `app/models/venta.py` (`create_sale`) <br> `app/models/product.py` (`add_product`) <br> `app/models/cliente.py` (`add_client`) |
| **3** | **Actualiza datos de algunas tablas** | 1. **Productos**: Edición completa de datos del producto. <br> 2. **Stock**: Actualización automática vía Trigger al vender. | `app/models/product.py` (`update_product`) <br> `fruteria_functions_triggers.sql` (`tf_actualizar_stock_venta`) |
| **4** | **Elimina datos** | Eliminación de productos (con validación de uso) y eliminación de clientes. | `app/models/product.py` (`delete_product`) <br> `app/models/cliente.py` (`delete_client`) |
| **5** | **Funcionamiento de 4 Funciones** | 1. `fn_calcular_total_venta` (Total monetario de una venta)<br>2. `fn_stock_disponible` (Consulta existencia)<br>3. `fn_ventas_por_empleado` (Totales por vendedor)<br>4. `fn_valor_inventario_total` (Valoración de almacén) | Archivo: `fruteria_functions_triggers.sql` <br> Uso en: `app/models/venta.py` y Dashboard |
| **6** | **Funcionamiento de 4 Disparadores** | 1. `tg_actualizar_stock_venta` (Resta stock tras venta)<br>2. `tg_actualizar_stock_compra` (Suma stock tras compra)<br>3. `tg_verificar_stock_suficiente` (Impide venta sin stock)<br>4. `tg_validar_precios_producto` (Valida Precio Venta > compra) | Archivo: `fruteria_functions_triggers.sql` <br> Se activan automáticamente en `INSERT/UPDATE`. |
| **7** | **Código muestra conexión a la BD** | Configuración de conexión con `psycopg2` y diccionario de configuración. | `config/config.py` (`DB_CONFIG`) <br> `app/routes/auth.py` (`get_db`) |
| **8** | **Autentifica al menos dos usuarios** | Login validado contra PostgreSQL. Soporta múltiples usuarios (`vendedor`, `almacenista`). Redirecciona según el rol obtenido de la tabla `empleado`. | `app/routes/auth.py` (`login`) <br> `app/models/user.py` (`User.get`) |

---

## 4. Detalles de las Funciones y Triggers

### Funciones Almacenadas
Las funciones encapsulan lógica de negocio compleja directamente en el motor de base de datos para mayor eficiencia.
*   **`fn_calcular_total_venta(folio)`**: Itera sobre los detalles de venta y suma `cantidad * precio`.
*   **`fn_ventas_por_empleado(id, fecha_inicio, fecha_fin)`**: Reporte financiero utilizado para calcular comisiones o desempeño.

### Disparadores (Triggers)
Automatizan la integridad de los datos:
*   **Control de Stock**: Los triggers `tg_actualizar_stock_venta` y `tg_actualizar_stock_compra` garantizan que el campo `existencia` en la tabla `producto` siempre refleje la realidad sin necesidad de código extra en la aplicación Python.
*   **Validación de Negocio**: `tg_validar_precios_producto` impide errores humanos al registrar precios, asegurando que nunca se venda por debajo del costo.

---

## 5. Profundización Técnica: Funcionamiento de la Base de Datos

Esta sección explica los mecanismos internos implementados en `config/db.py` para gestionar conexiones robustas y seguras.

### Gestión de Conexiones y Context Managers (`config/db.py`)
El sistema no utiliza conexiones crudas dispersas por el código. En su lugar, implementa un patrón de diseño **Context Manager** personalizado mediante el decorador `@contextmanager` en la función `get_cursor()`.

```python
@contextmanager
def get_cursor(dict_cursor=True):
    conn = get_db()
    # ... creación del cursor ...
    try:
        yield cursor  # Entrega el control a la función que lo llamó
        conn.commit() # Si todo sale bien, CONFIRMA los cambios automáticamente
    except Exception:
        conn.rollback() # Si hay error, DESHACE todo (Atomicidad)
        raise
    finally:
        cursor.close() # Siempre limpia los recursos
```
Esto garantiza **Propiedades ACID** (Atomicidad, Consistencia, Aislamiento, Durabilidad) en cada operación. Si una venta falla a la mitad (se crea la venta pero falla el detalle), el `rollback` deshace la venta inicial, evitando datos corruptos.

### Seguridad Avanzada: "Role Masquerading"
Una característica única de este sistema es el cambio dinámico de identidad en la base de datos (Impersonation).

1.  **Conexión Genérica**: La aplicación conecta inicialmente como un usuario de servicio (`postgres` en desarrollo).
2.  **Cambio de Rol (`SET ROLE`)**: Cuando un usuario inicia sesión, el sistema ejecuta:
    ```sql
    SET ROLE "nombre_usuario";
    ```
    Esto fuerza a que todas las consultas subsiguientes se ejecuten con los **privilegios exactos** de ese usuario en PostgreSQL.
3.  **Resultado**: Incluso si un hacker lograra inyectar código SQL en la sesión de un "vendedor", no podría borrar la tabla de productos ni ver salarios, porque el motor de base de datos bloquearía la acción a nivel de permisos, independientemente de lo que intente la aplicación Python.
