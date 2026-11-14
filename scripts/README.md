# Compilar el APK

## Actualizaciones desde la app

El script público ARM64 genera también `app-update.json` e incrementa el número de compilación respecto del manifiesto anterior. Publica el APK y ese JSON juntos en la rama principal de GitHub para que las instalaciones con el actualizador detecten la versión nueva. Usa la misma clave de firma. Las instrucciones completas, incluida la primera instalación manual, están en [actualizaciones Android](../docs/actualizaciones-android.md).

Para fijar un número superior al anterior: `.\scripts\build-apk.ps1 -BuildNumber 10`.
Los comandos Flutter directos de abajo no generan el manifiesto: para publicar una actualización usa el script.

Requisitos: Flutter en `PATH`, Android SDK y Java configurados (Android Studio), licencias aceptadas y dependencias descargadas. Comprobar con `flutter doctor`. Ejecuta desde la raíz del repositorio en PowerShell:

```powershell
.\scripts\build-apk.ps1
```

El script ejecuta `flutter pub get`, construye un APK release para teléfonos **ARM64** y lo copia a `my-daily-rutine-android-arm64.apk` en la raíz del repositorio. Esa es la descarga enlazada al inicio del README principal. Incluye las URLs públicas de Render y usa la sesión del usuario para el análisis de fotos; no incluye claves ni tokens compartidos. El backend debe tener desplegado el soporte de JWT en `/avatar/suggest`.

Si prefieres los comandos directos:

```powershell
cd my_daily_routine
flutter pub get
flutter build apk --release --target-platform android-arm64 --dart-define=API_URL=https://my-daily-rutine.onrender.com --dart-define=AVATAR_API_URL=https://my-daily-rutine.onrender.com
```

Resultado: `my_daily_routine/build/app/outputs/flutter-apk/app-release.apk`. Para actualizar el enlace del README, usa el script o copia ese archivo a la raiz del proyecto. En otro equipo, el enlace de descarga requiere que el APK también se haya incluido en el repositorio compartido; no basta con subir el README. No se publica automáticamente en GitHub Releases ni en Play Store.

Para un emulador x86_64:

```powershell
.\scripts\build-apk.ps1 -TargetPlatform android-x64
```

## APK privado con token compartido (compatibilidad)

El backend debe estar ejecutándose en una dirección **HTTPS accesible desde el teléfono**. Crea un JSON privado con `API_URL` (usuarios y tareas), `AVATAR_API_URL` y `AVATAR_API_TOKEN`; nunca incluyas `OPENAI_API_KEY` ni uses `backend/.env`. Las dos URLs actuales son `https://my-daily-rutine.onrender.com`. Puedes usar `.tools/avatar-flutter.json`, ya configurado para Render, como `-ConfigFile`. Después:

```powershell
.\scripts\build-apk.ps1 -ConfigFile .\.tools\avatar-release.json
```

Este APK se guarda con sufijo `-private.apk`, ignorado por Git para no distribuir accidentalmente el token compartido. El APK público sin configuración no se sobrescribe. El token local es solo para pruebas, no autenticación de producción. La URL `http://10.0.2.2:8000` de debug no sirve para esta compilación release ni para un teléfono físico.

## Instalación y firma

Puedes copiar el APK al teléfono e instalarlo permitiendo instalaciones desde esa fuente, o usar `adb install -r RUTA_AL_APK` con el dispositivo conectado. La compilación ARM64 no se instala en emuladores x86_64; usa el destino correspondiente.

El proyecto todavía firma release con la clave **debug** de la máquina: este APK es para pruebas, no una publicación de producción. Para distribuir formalmente se necesita configurar una clave de firma propia. Para actualizar una instalación existente debe coincidir la firma; una desinstalación elimina los datos locales.
