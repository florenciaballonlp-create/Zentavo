# ==============================================================================
# SCRIPT DE INCREMENTO DE VERSIÓN - ZENTAVO
# ==============================================================================
# Uso:
#   .\increment-version.ps1 patch    # 1.0.0 -> 1.0.1
#   .\increment-version.ps1 minor    # 1.0.1 -> 1.1.0
#   .\increment-version.ps1 major    # 1.1.0 -> 2.0.0
# ==============================================================================

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("patch", "minor", "major")]
    [string]$type
)

$versionFile = "android\version.properties"

if (-not (Test-Path $versionFile)) {
    Write-Host "❌ Error: No se encontró $versionFile" -ForegroundColor Red
    exit 1
}

# Leer archivo de versión actual
$content = Get-Content $versionFile -Raw
$versionCode = ([regex]::Match($content, "versionCode=(\d+)")).Groups[1].Value
$versionName = ([regex]::Match($content, "versionName=(.+)")).Groups[1].Value.Trim()

# Parsear versionName (MAJOR.MINOR.PATCH)
$versionParts = $versionName -split '\.'
$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
$patch = [int]$versionParts[2]

# Incrementar según tipo
switch ($type) {
    "patch" {
        $patch++
        $newVersionName = "$major.$minor.$patch"
    }
    "minor" {
        $minor++
        $patch = 0
        $newVersionName = "$major.$minor.$patch"
    }
    "major" {
        $major++
        $minor = 0
        $patch = 0
        $newVersionName = "$major.$minor.$patch"
    }
}

# Incrementar versionCode (siempre +1)
$newVersionCode = [int]$versionCode + 1

# Crear nuevo contenido
$newContent = @"
# VERSION DE LA APP - Zentavo
# Incrementa versionCode en +1 para cada actualización en Play Store
# Actualiza versionName según: MAJOR.MINOR.PATCH

versionCode=$newVersionCode
versionName=$newVersionName
"@

# Escribir nuevo archivo
Set-Content -Path $versionFile -Value $newContent -NoNewline

Write-Host ""
Write-Host "✅ VERSIÓN ACTUALIZADA" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  Versión anterior:" -ForegroundColor Cyan -NoNewline
Write-Host " $versionCode ($versionName)"
Write-Host "  Nueva versión:   " -ForegroundColor Green -NoNewline
Write-Host " $newVersionCode ($newVersionName)" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""
Write-Host "📋 PRÓXIMOS PASOS:" -ForegroundColor Cyan
Write-Host "  1. git add android/version.properties"
Write-Host "  2. git commit -m `"chore: Bump version to $newVersionName`""
Write-Host "  3. git push origin main"
Write-Host "  4. Esperar a que GitHub Actions compile"
Write-Host "  5. Descargar el AAB firmado"
Write-Host "  6. Subir a Google Play Console"
Write-Host ""
