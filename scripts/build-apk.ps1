param(
    [string]$ConfigFile,
    [ValidateSet('android-arm64', 'android-x64', 'android-arm')]
    [string]$TargetPlatform = 'android-arm64',
    [int]$BuildNumber = 0
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$appRoot = Join-Path $repoRoot 'my_daily_routine'
$buildArgs = @('build', 'apk', '--release', '--target-platform', $TargetPlatform)
$manifestPath = Join-Path $repoRoot 'app-update.json'
if (!$ConfigFile -and $TargetPlatform -eq 'android-arm64') {
    $pubspec = Get-Content -LiteralPath (Join-Path $appRoot 'pubspec.yaml') -Raw
    if ($pubspec -notmatch '(?m)^version:\s*([^+\s]+)\+(\d+)\s*$') { throw 'Falta version: nombre+numero en pubspec.yaml.' }
    $versionName = $Matches[1]
    $minimumBuild = [int]$Matches[2]
    if (Test-Path -LiteralPath $manifestPath) {
        $previous = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        $minimumBuild = [Math]::Max($minimumBuild, [int]$previous.build + 1)
    }
    if ($BuildNumber -eq 0) { $BuildNumber = $minimumBuild }
    if ($BuildNumber -lt $minimumBuild) { throw "El numero de compilacion debe ser al menos $minimumBuild." }
    $buildArgs += "--build-number=$BuildNumber"
    $buildArgs += "--build-name=$versionName"
}
if (!$ConfigFile) {
    $buildArgs += '--dart-define=API_URL=https://my-daily-rutine.onrender.com'
    $buildArgs += '--dart-define=AVATAR_API_URL=https://my-daily-rutine.onrender.com'
}
if ($ConfigFile) {
    $configPath = (Resolve-Path -LiteralPath $ConfigFile).Path
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    foreach ($property in $config.PSObject.Properties.Name) {
        if ($property -notin @('API_URL', 'AVATAR_API_URL', 'AVATAR_API_TOKEN')) {
            throw 'El JSON solo debe contener API_URL, AVATAR_API_URL y AVATAR_API_TOKEN, nunca claves de OpenAI.'
        }
    }
    if ($config.API_URL -and $config.API_URL -notmatch '^https://') {
        throw 'Para release API_URL debe usar HTTPS.'
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
    $destination = if ($ConfigFile) { Join-Path $repoRoot 'artifacts' } else { $repoRoot }
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    $name = if ($ConfigFile) { "my-daily-rutine-$TargetPlatform-private.apk" } else { "my-daily-rutine-$TargetPlatform.apk" }
    Copy-Item -LiteralPath (Join-Path $appRoot 'build/app/outputs/flutter-apk/app-release.apk') -Destination (Join-Path $destination $name) -Force
    if (!$ConfigFile -and $TargetPlatform -eq 'android-arm64') {
        $apkPath = Join-Path $destination $name
        $manifest = [ordered]@{
            schema = 1
            version = $versionName
            build = $BuildNumber
            abi = 'arm64-v8a'
            size = (Get-Item -LiteralPath $apkPath).Length
            sha256 = (Get-FileHash -LiteralPath $apkPath -Algorithm SHA256).Hash.ToLowerInvariant()
        } | ConvertTo-Json
        [System.IO.File]::WriteAllText($manifestPath, $manifest + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
        Write-Output "Publica juntos $name y app-update.json en la rama principal de GitHub."
    }
    Write-Output "APK generado: $(Join-Path $destination $name)"
} finally {
    Pop-Location
}
