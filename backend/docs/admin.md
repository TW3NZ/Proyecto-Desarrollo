# Panel administrativo de la base de datos

## Iniciar y entrar

Desde la raíz del repositorio, inicia el backend habitual:

```powershell
.\.venv\Scripts\python.exe -m uvicorn backend.app:app --host 127.0.0.1 --port 8000
```

Abre **http://127.0.0.1:8000/admin**. Si el servidor ya estaba abierto sin `--reload`, reinícialo para cargar las rutas y variables nuevas.

El acceso desde este mismo equipo mediante `127.0.0.1` o `localhost` **no pide contraseña**. El backend lee las credenciales de Aiven de `backend/.env`; nunca se envían al navegador. `ADMIN_USER` y `ADMIN_PASSWORD` no son necesarios para el uso local y sus valores existentes se conservan como autenticación alternativa para accesos no locales.

Si en el futuro necesitas configurar esa autenticación alternativa, puedes generar una contraseña administrativa y guardarla en el `.env`:

```powershell
.\.venv\Scripts\python.exe -c "import secrets; print(secrets.token_urlsafe(32))"
```

Reinicia el backend tras cambiar el `.env`. Mantén el servidor enlazado a `127.0.0.1` para este uso local. El acceso automático comprueba la dirección del cliente, el host solicitado y el origen del navegador, y no se aplica a peticiones reenviadas por proxies. Cualquier persona con acceso al navegador de este equipo puede consultar el panel. Para una publicación futura, revisa la autenticación y utiliza HTTPS.

## Consultas disponibles

### Abrir desde Live Server (puerto 5500)

También puedes abrir `backend/admin/index.html` con Live Server. Mantén FastAPI iniciado en otra terminal con el comando anterior. El panel conecta automáticamente a `http://127.0.0.1:8000`, sin credenciales en el navegador. Si el backend usa otro puerto o la conexión falla, mostrará **Conecta tu panel**:

1. Dirección del backend: `http://127.0.0.1:8000` (o el puerto que hayas usado al iniciar Uvicorn).
2. Pulsa **Conectar y ver tablas**. Puedes cambiar la conexión con el botón **Conexión API**. No hay campos de usuario o contraseña.

El frontend envía las consultas a `http://127.0.0.1:8000/admin/api/...`, no al puerto 5500. No lee el `.env` ni envía cabeceras de contraseña: el backend gestiona la conexión MySQL.

El backend permite estos orígenes locales mediante:

```dotenv
ADMIN_ALLOWED_ORIGINS=http://127.0.0.1:5500,http://localhost:5500
```

Si Live Server utiliza otro puerto, añade su origen local exacto, separado por comas, y reinicia el backend. No uses `*`. Tanto el origen como la conexión deben ser locales para acceder sin contraseña. Al abrir mediante FastAPI en `/admin/`, también se entra automáticamente.

**Diagnóstico:** un 404 en `:5500/admin/api/schema` significa que se está consultando Live Server, que solo entrega archivos y no implementa esa API. Un 401 indica que la petición no cumple las condiciones de acceso local; un fallo de red puede indicar que FastAPI está detenido o que falta permitir el origen del frontend. Tras actualizar, reinicia FastAPI y recarga el panel con `Ctrl+F5`.

### Explorar los datos

- Barra lateral: tablas reales de la base configurada en `DB_NAME` y buscador de nombres.
- Datos: búsqueda de texto en las columnas visibles de la tabla seleccionada, ordenación por cabecera y páginas de 25, 50 o 100 filas.
- Botón **Ver**: detalle completo de un registro, referencias a sus padres y registros hijos relacionados. Los enlaces abren la tabla correspondiente con filtros exactos, incluidas claves compuestas.
- **Quitar filtros** elimina el filtro de relación; el buscador de texto se limpia desde su campo.
- **Estructura y relaciones**: tipos de columnas, claves, campos que admiten NULL y claves foráneas.
- **Actualizar** vuelve a consultar el esquema y la página actual. Un resultado vacío se distingue de un fallo de conexión.

En SQL no hay “subtablas” como carpetas: se muestran tablas relacionadas por claves foráneas en ambas direcciones. No se inventan relaciones que no estén declaradas en MySQL. La búsqueda se aplica a una tabla cada vez, no a toda la base simultáneamente. El contador de registros refleja el filtro y la búsqueda actuales.

## Alcance y organización

La primera entrega es de **solo lectura**: no incluye edición, borrado ni consola SQL arbitraria. Todas las consultas usan transacciones de lectura; los identificadores se validan contra el esquema y los valores se envían como parámetros. Las columnas cuyos nombres indican contraseñas, secretos, tokens o credenciales se muestran como protegidas y no se recuperan, buscan ni ordenan. Si el esquema añade campos sensibles con otros nombres, amplía `sensitive()` antes de exponerlos.

El panel permite acceso local automático, exige autenticación para el resto de conexiones y usa respuestas sin caché y recursos locales. Las credenciales de Aiven y OpenAI permanecen en el servidor. No hay llamadas a OpenAI al navegar por el panel.

| Ruta | Responsabilidad |
| --- | --- |
| `backend/app.py` | Único servidor; contiene autenticación administrativa, entrega del HTML/CSS/JS y todos los endpoints de consulta. |
| `backend/database/admin.py` | Metadatos, filtros, relaciones y consultas de solo lectura. |
| `backend/admin/index.html` | Estructura HTML del panel. |
| `backend/admin/admin.css` | Estilos separados del HTML. |
| `backend/admin/admin.js` | Consultas mediante fetch a la API y presentación de resultados. |
| `backend/test/test_admin.py` | Pruebas de acceso, consultas y protección de campos. |

Los endpoints son `GET /admin/api/schema` y `GET /admin/api/tables/{tabla}`. Ambos comprueban acceso local o autenticación administrativa alternativa. No se modifica el esquema ni los datos al abrir el panel.

El flujo es: navegador → `admin.js` → endpoints de `app.py` → MySQL → respuesta JSON → tabla HTML. Abre el panel mediante `http://127.0.0.1:8000/admin/`; `/admin` redirige a esa URL. Los archivos CSS, JS y la imagen de marca se cargan con rutas relativas desde `backend/admin/` y tipos MIME explícitos. Las rutas anteriores `/admin/assets/` conservan compatibilidad. Si abres el HTML con doble clic, puedes visualizar el diseño, pero verás un aviso para abrir el servidor antes de consultar datos.

El estilo reutiliza la paleta de `my_daily_routine/lib/theme.dart`: azul royal `#4169E1`, degradado hacia `#2F80ED`, fondo `#F5F7FF`, controles redondeados y sombras suaves. `brand.png` es una copia del icono existente de la app, cuyo original se conserva. El diseño se adapta a móvil y respeta movimiento reducido. Tras actualizar el backend, reinícialo y recarga el navegador con `Ctrl+F5`.
