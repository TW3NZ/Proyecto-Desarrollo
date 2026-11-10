# Compilar el APK

Requisitos: Flutter en `PATH`, Android SDK y Java configurados (Android Studio), licencias aceptadas y dependencias descargadas. Comprobar con `flutter doctor`. Ejecuta desde la raíz del repositorio en PowerShell:

```powershell
.\scripts\build-apk.ps1
```

El script ejecuta `flutter pub get`, construye un APK release para teléfonos **ARM64** y lo copia a `artifacts/my-daily-rutine-android-arm64.apk`. Esa es la descarga enlazada al inicio del README principal. No incluye claves ni tokens locales; la personalización manual funciona y el análisis de fotos requiere configuración adicional.

Si prefieres los comandos directos:

```powershell
cd my_daily_routine
flutter pub get
flutter build apk --release --target-platform android-arm64
```

Resultado: `my_daily_routine/build/app/outputs/flutter-apk/app-release.apk`. Para actualizar el enlace del README, usa el script o copia ese archivo a la ruta `artifacts` indicada. En otro equipo, el enlace de descarga requiere que el APK también se haya incluido en el repositorio compartido; no basta con subir el README. No se publica automáticamente en GitHub Releases ni en Play Store.

Para un emulador x86_64:

```powershell
.\scripts\build-apk.ps1 -TargetPlatform android-x64
```

## APK con servicio de fotos

El backend debe estar ejecutándose en una dirección **HTTPS accesible desde el teléfono**. Crea un JSON privado con únicamente `AVATAR_API_URL` y `AVATAR_API_TOKEN`; nunca incluyas `OPENAI_API_KEY` ni uses `backend/.env`. Después:

```powershell
.\scripts\build-apk.ps1 -ConfigFile .\.tools\avatar-release.json
```

Este APK se guarda con sufijo `-private.apk`, ignorado por Git para no distribuir accidentalmente el token compartido. El APK público sin configuración no se sobrescribe. El token local es solo para pruebas, no autenticación de producción. La URL `http://10.0.2.2:8000` de debug no sirve para esta compilación release ni para un teléfono físico.

## Instalación y firma

Puedes copiar el APK al teléfono e instalarlo permitiendo instalaciones desde esa fuente, o usar `adb install -r RUTA_AL_APK` con el dispositivo conectado. La compilación ARM64 no se instala en emuladores x86_64; usa el destino correspondiente.

El proyecto todavía firma release con la clave **debug** de la máquina: este APK es para pruebas, no una publicación de producción. Para distribuir formalmente se necesita configurar una clave de firma propia. Para actualizar una instalación existente debe coincidir la firma; una desinstalación elimina los datos locales.
