param(
    [string]$ConfigFile,
    [ValidateSet('android-arm64', 'android-x64', 'android-arm')]
    [string]$TargetPlatform = 'android-arm64'
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$appRoot = Join-Path $repoRoot 'my_daily_routine'
$buildArgs = @('build', 'apk', '--release', '--target-platform', $TargetPlatform)
if ($ConfigFile) {
    $configPath = (Resolve-Path -LiteralPath $ConfigFile).Path
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    foreach ($property in $config.PSObject.Properties.Name) {
        if ($property -notin @('AVATAR_API_URL', 'AVATAR_API_TOKEN')) {
            throw 'El JSON solo debe contener AVATAR_API_URL y AVATAR_API_TOKEN, nunca claves de OpenAI.'
        }
    }
    if ($config.AVATAR_API_URL -notmatch '^https://' -or $config.AVATAR_API_TOKEN.Length -lt 24) {
        throw 'Para release usa una URL HTTPS y un token del servicio de al menos 24 caracteres.'
    }
    $buildArgs += "--dart-define-from-file=$configPath"
}
Push-Location $appRoot
try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Falló flutter pub get.' }
    & flutter @buildArgs
    if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación del APK.' }
    $destination = Join-Path $repoRoot 'artifacts'
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    $name = if ($ConfigFile) { "my-daily-rutine-$TargetPlatform-private.apk" } else { "my-daily-rutine-$TargetPlatform.apk" }
    Copy-Item -LiteralPath (Join-Path $appRoot 'build/app/outputs/flutter-apk/app-release.apk') -Destination (Join-Path $destination $name) -Force
    Write-Output "APK generado: artifacts/$name"
} finally {
    Pop-Location
}
