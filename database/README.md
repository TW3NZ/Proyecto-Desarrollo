# Conectarse desde Windows a MySQL en Aiven

Estos comandos se ejecutan en **PowerShell, desde la raíz del repositorio**. La base está alojada en Aiven: no necesitas iniciar un servidor MySQL local ni levantar FastAPI para consultarla.

## 1. Ubicarse en el proyecto

En este equipo:

```powershell
cd "C:\Users\HP\Documents\Dart\My Daily Rutine\Proyecto-Desarrollo"
```

Si descargaste el proyecto en otra ubicación, cambia esa ruta. Si estás dentro de `database`, puedes volver a la raíz con `cd ..`.

## 2. Requisitos y configuración

Usa el entorno Python `.venv` del proyecto y el cliente MySQL. No necesitas activar el entorno: los comandos invocan su Python directamente.

Comprueba el cliente instalado en este equipo:

```powershell
& "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" --version
```

La utilidad busca `mysql` en el PATH y, si no lo encuentra, usa esa ruta. `pip install mysql` instala una biblioteca de Python; no instala el programa `mysql.exe`.

Para preparar un entorno nuevo, solo si todavía no tienes `.venv`:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt
```

Configura las siguientes variables en `backend/.env`, conservando las de OpenAI y las demás existentes. Puedes consultar `backend/.env.example` como plantilla; no sobrescribas un `.env` que ya tenga credenciales.

```dotenv
DB_HOST=HOST_DE_TU_SERVICIO.aivencloud.com
DB_PORT=10472
DB_USER=avnadmin
DB_PASSWORD='TU_CONTRASEÑA'
DB_NAME=BD_my_daily_routine
DB_SSL_CA="-----BEGIN CERTIFICATE-----
PEGA_AQUI_EL_CONTENIDO_COMPLETO_DEL_CERTIFICADO_CA
-----END CERTIFICATE-----"
DB_SSL_VERIFY_CERT=true
DB_CONNECT_TIMEOUT=10
```

Confirma host, puerto y usuario en Aiven. El certificado queda **dentro del `.env`**, entre comillas dobles y con saltos de línea reales. No uses una ruta en `DB_SSL_CA`. Las credenciales no deben copiarse a Flutter ni versionarse.

## 3. Probar la conexión

```powershell
.\.venv\Scripts\python.exe -m backend.utils.check_database
```

La prueba utiliza las credenciales del `.env`, valida el certificado y el nombre del servidor, ejecuta `SELECT 1`, consulta el cifrado TLS y cuenta las tablas. No modifica datos.

El resultado correcto incluye `connection_ok` con valor `1`, un `Ssl_cipher` no vacío y `table_count`. En la comprobación del 2026-11-11 se encontraron **10 tablas**.

## 4. Abrir una terminal SQL interactiva

```powershell
.\.venv\Scripts\python.exe -m backend.utils.check_database --interactive
```

Esta opción abre el cliente MySQL usando el mismo `.env`. Cuando aparezca `mysql>`, puedes ejecutar:

```sql
SELECT DATABASE();
SHOW TABLES;
SHOW SESSION STATUS LIKE 'Ssl_cipher';
SELECT COUNT(*) AS usuarios FROM Usuario;
```

Para salir y regresar a PowerShell:

```sql
exit;
```

La sesión interactiva permite ejecutar SQL con los permisos del usuario configurado; las sentencias que escribas pueden modificar la base remota. La utilidad no ejecuta automáticamente el script de creación.

Ambos modos exigen `VERIFY_IDENTITY`. El cliente MySQL necesita leer el certificado desde un archivo: la utilidad crea una copia temporal del PEM y la elimina al finalizar. La configuración permanente sigue estando únicamente en el `.env`; no tienes que manejar una ruta adicional.

## 5. Script de creación: solo para una base nueva

`BD_My_Daily_Routine.sql` crea la base y sus 10 tablas. **La base actual ya está inicializada; no vuelvas a ejecutar el script sobre ella.** No es una migración ni está preparado para repetirse.

Para inicializar otro servicio nuevo, configura sus credenciales en el `.env` y usa temporalmente `DB_NAME=defaultdb`, porque la base de la aplicación todavía no existe. Abre la sesión del paso 4 y ejecuta, manteniendo PowerShell inicialmente en la raíz del repositorio:

```sql
SOURCE database/BD_My_Daily_Routine.sql;
USE BD_my_daily_routine;
SHOW TABLES;
exit;
```

Después cambia `DB_NAME` a `BD_my_daily_routine` y repite la prueba del paso 3. El script no inserta usuarios ni categorías iniciales.

## Errores frecuentes

| Mensaje | Qué revisar |
| --- | --- |
| `No module named backend` | Ejecuta el comando desde la raíz del repositorio. |
| `CLIENT_ERROR` | Comprueba la instalación del cliente MySQL y su PATH. |
| `CONFIG_ERROR` | Completa las variables y revisa las comillas del certificado; el timeout admite 1–120 segundos. |
| `1045` | Usuario, contraseña y permisos en Aiven. |
| `1049` | El nombre de la base o si ya fue creada. |
| `2003` / `2005` | Estado del servicio, host, puerto, red y restricciones de acceso. |
| `2026` | Certificado CA y coincidencia del host con el certificado del servicio. |

El backend unificado ya contiene registro y login de usuarios mediante MySQL. Los endpoints de equipos y tareas siguen pendientes. El conector Python está en `backend/database/`; los scripts SQL permanecen en esta carpeta `database/` de la raíz. Para probar ese conector directamente, ejecuta `.\.venv\Scripts\python.exe -m backend.utils.prueba_conexion` desde la raíz. Los comandos para ejecutar la API y probar Flutter están en [backend/README.md](../backend/README.md).
