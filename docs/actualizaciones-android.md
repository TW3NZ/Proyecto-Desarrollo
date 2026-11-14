# Actualizaciones desde la app — 2026-11-14

El usuario pidió detectar y descargar los APK publicados en la rama principal. La implementación consulta el repositorio público `TW3NZ/Proyecto-Desarrollo`, sin claves, al abrir una compilación release Android. También comprueba al volver a primer plano si han pasado seis horas. No trabaja con la app cerrada. Sin conexión, sin archivo publicado o si GitHub limita las peticiones, la app sigue funcionando y vuelve a intentar en una comprobación posterior.

La rama se resuelve mediante la API de contenidos de GitHub sin `ref`: usa la rama predeterminada del repositorio, actualmente `master`. Si se cambia a `main` en GitHub no hay que recompilar para cambiar esa referencia. La ruta de descarga se obtiene de la ubicación del manifiesto en esa rama; no se acepta una URL arbitraria dentro del JSON. [Contrato oficial de GitHub](https://docs.github.com/en/rest/repos/contents#get-repository-content).

## Para la persona que usa el teléfono

1. Instalar manualmente una vez el primer APK con esta función (0.2.0, compilación 2 o posterior). Las versiones antiguas no pueden detectar actualizaciones por sí solas.
2. Al abrir una versión anterior a la publicada aparece un aviso con tamaño y botón **Descargar**. Puede posponerse sin bloquear la app.
3. Tras descargar y verificar, se abre el instalador de Android. La primera vez Android puede pedir permitir instalaciones desde My Daily Routine; al regresar se pulsa **Instalar**, reutilizando la descarga.
4. Android solicita confirmar la actualización. Se conserva la instalación y sus datos. Cancelar el instalador permite volver a intentarlo.

No hay instalación silenciosa. Se usa el permiso `REQUEST_INSTALL_PACKAGES`, un `FileProvider` limitado a la carpeta de actualizaciones y la pantalla del sistema para autorizar esta fuente. [API de permisos de instalación de Android](https://developer.android.com/reference/android/content/pm/PackageManager#canRequestPackageInstalls()).

## Publicar una versión

Desde la raíz, ejecutar:

```powershell
.\scripts\build-apk.ps1
```

El script genera el APK ARM64 y `app-update.json` juntos. El número de compilación es el mayor entre el de `pubspec.yaml` y el anterior publicado localmente más uno. Para fijarlo explícitamente:

```powershell
.\scripts\build-apk.ps1 -BuildNumber 10
```

Debe superar al manifiesto anterior. Antes de compilar desde otro equipo, sincronizar la rama para no reutilizar números. El nombre visible (por ejemplo 0.2.0) viene de `pubspec.yaml`; la detección compara el número entero de compilación, no el nombre. Publicar **ambos archivos en el mismo commit** de la rama predeterminada. Subir únicamente un APK nuevo no actualiza el manifiesto; reemplazar el archivo conservando el mismo número tampoco anuncia una nueva versión. El script compila, pero no hace commit ni push automáticamente.

Las compilaciones privadas y las de otras arquitecturas no sobrescriben el manifiesto público. Por ahora solo se distribuyen actualizaciones ARM64. No se necesita modificar Render para este mecanismo.

## Integridad y firma

El manifiesto incluye versión, número, ABI, tamaño y SHA-256. La descarga usa HTTPS, tiene límite de tamaño y tiempo, guarda un archivo parcial y solo lo acepta completo. Antes de instalar se vuelve a verificar SHA-256, ID de paquete, número superior al instalado, compatibilidad de Android y coincidencia de firmas. Si el APK y el manifiesto cambian durante la descarga, la comprobación falla y se debe volver a abrir la app para consultar la publicación nueva.

Se debe conservar la clave con la que se firmó el APK ya instalado. Actualmente se usa la clave debug de esta máquina para los APK de prueba: compilar con otra clave no permite actualizar esa instalación. No subir claves privadas al repositorio. Esta distribución es para los APK instalados directamente; una futura distribución mediante Play Store necesitará su propio flujo de actualización.

## Ubicación y pruebas

- `lib/services/app_update_service.dart`: consulta de versiones y validación del manifiesto.
- `lib/widgets/common/app_update_gate.dart`: aviso, progreso, errores y reintento de instalación.
- `android/app/src/main/kotlin/com/example/my_daily_routine/AppUpdater.kt`: descarga, verificación y apertura del instalador.
- `scripts/build-apk.ps1`: compilación y metadatos de publicación.

Prueba automatizada desde `my_daily_routine/`: `flutter test test/app_update_test.dart`.
Para una prueba completa en un teléfono, instalar la compilación 2, publicar una compilación 3 con el mismo firmante y su manifiesto, volver a abrir la app, descargar y confirmar. Verificar también cancelar el instalador, rechazar/autorizar el permiso, interrumpir la conexión y posponer el aviso. La comprobación automática se habilita solo en release Android, para no introducir consultas durante los tests ni al desarrollar en debug.
