# Script de Preparación para Publicación en Play Store
# Zentavo - Control de Gastos

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ZENTAVO - Preparación Play Store" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar ubicación
$currentDir = Get-Location
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ ERROR: Ejecuta este script desde la raíz del proyecto Zentavo" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Directorio correcto detectado" -ForegroundColor Green
Write-Host ""

# Menú principal
Write-Host "Selecciona una opción:" -ForegroundColor Yellow
Write-Host "1. Crear Keystore (firma de la app)"
Write-Host "2. Compilar AAB para Play Store"
Write-Host "3. Verificar configuración"
Write-Host "4. Abrir guía completa"
Write-Host "5. Salir"
Write-Host ""

$opcion = Read-Host "Opción (1-5)"

switch ($opcion) {
    "1" {
        Write-Host ""
        Write-Host "📝 CREAR KEYSTORE DE FIRMA" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "⚠️  IMPORTANTE: Anota las contraseñas que elijas" -ForegroundColor Yellow
        Write-Host "    Si las pierdes, NO podrás actualizar tu app" -ForegroundColor Yellow
        Write-Host ""
        
        $continuar = Read-Host "¿Continuar? (S/N)"
        if ($continuar -ne "S" -and $continuar -ne "s") {
            Write-Host "❌ Operación cancelada" -ForegroundColor Red
            exit 0
        }

        # Navegar a carpeta android
        Set-Location android

        # Verificar si ya existe keystore
        if (Test-Path "zentavo-release-key.jks") {
            Write-Host ""
            Write-Host "⚠️  Ya existe un keystore: zentavo-release-key.jks" -ForegroundColor Yellow
            $sobrescribir = Read-Host "¿Sobrescribir? ESTO INVALIDARÁ EL ANTERIOR (S/N)"
            if ($sobrescribir -ne "S" -and $sobrescribir -ne "s") {
                Write-Host "❌ Operación cancelada" -ForegroundColor Red
                Set-Location ..
                exit 0
            }
            Remove-Item "zentavo-release-key.jks"
        }

        Write-Host ""
        Write-Host "🔑 Creando keystore..." -ForegroundColor Cyan
        Write-Host ""
        
        # Crear keystore
        keytool -genkey -v -keystore zentavo-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias zentavo-key

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Keystore creado exitosamente: android/zentavo-release-key.jks" -ForegroundColor Green
            Write-Host ""
            Write-Host "📝 SIGUIENTE PASO:" -ForegroundColor Yellow
            Write-Host "   1. Crea el archivo: android/key.properties" -ForegroundColor White
            Write-Host "   2. Usa android/key.properties.template como referencia" -ForegroundColor White
            Write-Host "   3. Agrega tus contraseñas al archivo key.properties" -ForegroundColor White
            Write-Host ""
            Write-Host "⚠️  BACKUP: Haz copia de zentavo-release-key.jks en lugar seguro" -ForegroundColor Yellow
        } else {
            Write-Host ""
            Write-Host "❌ Error al crear keystore" -ForegroundColor Red
        }

        Set-Location ..
    }

    "2" {
        Write-Host ""
        Write-Host "📦 COMPILAR AAB PARA PLAY STORE" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Cyan
        Write-Host ""

        # Verificar que existe keystore
        if (-not (Test-Path "android\zentavo-release-key.jks")) {
            Write-Host "❌ ERROR: No existe keystore" -ForegroundColor Red
            Write-Host "   Primero ejecuta la opción 1 para crear el keystore" -ForegroundColor Yellow
            exit 1
        }

        # Verificar que existe key.properties
        if (-not (Test-Path "android\key.properties")) {
            Write-Host "❌ ERROR: No existe android/key.properties" -ForegroundColor Red
            Write-Host "   Crea el archivo basándote en key.properties.template" -ForegroundColor Yellow
            exit 1
        }

        Write-Host "✅ Configuración de firma detectada" -ForegroundColor Green
        Write-Host ""

        $continuar = Read-Host "¿Continuar con la compilación? (S/N)"
        if ($continuar -ne "S" -and $continuar -ne "s") {
            Write-Host "❌ Operación cancelada" -ForegroundColor Red
            exit 0
        }

        Write-Host ""
        Write-Host "🧹 Limpiando compilaciones anteriores..." -ForegroundColor Cyan
        flutter clean

        Write-Host ""
        Write-Host "🏗️  Compilando AAB (esto puede tardar 2-5 minutos)..." -ForegroundColor Cyan
        flutter build appbundle --release

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ ¡AAB compilado exitosamente!" -ForegroundColor Green
            Write-Host ""
            Write-Host "📍 Ubicación del archivo:" -ForegroundColor Yellow
            Write-Host "   build\app\outputs\bundle\release\app-release.aab" -ForegroundColor White
            Write-Host ""
            
            $tamano = (Get-Item "build\app\outputs\bundle\release\app-release.aab").Length / 1MB
            Write-Host "📊 Tamaño: $([math]::Round($tamano, 2)) MB" -ForegroundColor White
            Write-Host ""

            $abrirCarpeta = Read-Host "¿Abrir carpeta del archivo? (S/N)"
            if ($abrirCarpeta -eq "S" -or $abrirCarpeta -eq "s") {
                explorer "build\app\outputs\bundle\release\"
            }

            Write-Host ""
            Write-Host "📝 SIGUIENTE PASO:" -ForegroundColor Yellow
            Write-Host "   1. Ve a: https://play.google.com/console" -ForegroundColor White
            Write-Host "   2. Crea nueva aplicación" -ForegroundColor White
            Write-Host "   3. Sube el archivo: app-release.aab" -ForegroundColor White
            Write-Host "   4. Sigue la guía en: GUIA_PUBLICACION_PLAY_STORE.md" -ForegroundColor White
        } else {
            Write-Host ""
            Write-Host "❌ Error al compilar AAB" -ForegroundColor Red
            Write-Host "   Verifica los errores arriba" -ForegroundColor Yellow
        }
    }

    "3" {
        Write-Host ""
        Write-Host "🔍 VERIFICACIÓN DE CONFIGURACIÓN" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Cyan
        Write-Host ""

        $allGood = $true

        # Verificar pubspec.yaml
        if (Test-Path "pubspec.yaml") {
            Write-Host "✅ pubspec.yaml encontrado" -ForegroundColor Green
            $content = Get-Content "pubspec.yaml" -Raw
            if ($content -match "version:\s*([\d\.]+)\+(\d+)") {
                $version = $matches[1]
                $build = $matches[2]
                Write-Host "   Versión: $version (Build: $build)" -ForegroundColor Gray
            }
        } else {
            Write-Host "❌ pubspec.yaml NO encontrado" -ForegroundColor Red
            $allGood = $false
        }

        # Verificar version.properties
        if (Test-Path "android\version.properties") {
            Write-Host "✅ android/version.properties encontrado" -ForegroundColor Green
            $versionProps = Get-Content "android\version.properties"
            $versionProps | ForEach-Object {
                if ($_ -match "^version") {
                    Write-Host "   $_" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host "❌ android/version.properties NO encontrado" -ForegroundColor Red
            $allGood = $false
        }

        # Verificar keystore
        if (Test-Path "android\zentavo-release-key.jks") {
            Write-Host "✅ Keystore (zentavo-release-key.jks) encontrado" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Keystore NO encontrado (necesario para Play Store)" -ForegroundColor Yellow
            Write-Host "   Ejecuta opción 1 para crearlo" -ForegroundColor Gray
        }

        # Verificar key.properties
        if (Test-Path "android\key.properties") {
            Write-Host "✅ android/key.properties encontrado" -ForegroundColor Green
        } else {
            Write-Host "⚠️  android/key.properties NO encontrado" -ForegroundColor Yellow
            Write-Host "   Copia key.properties.template y renómbralo" -ForegroundColor Gray
        }

        # Verificar build.gradle.kts
        if (Test-Path "android\app\build.gradle.kts") {
            Write-Host "✅ build.gradle.kts encontrado" -ForegroundColor Green
        } else {
            Write-Host "❌ build.gradle.kts NO encontrado" -ForegroundColor Red
            $allGood = $false
        }

        Write-Host ""
        if ($allGood) {
            Write-Host "🎉 Configuración básica completa" -ForegroundColor Green
            if (-not (Test-Path "android\zentavo-release-key.jks")) {
                Write-Host "⚠️  Recuerda crear el keystore antes de compilar para Play Store" -ForegroundColor Yellow
            }
        } else {
            Write-Host "⚠️  Faltan algunos archivos importantes" -ForegroundColor Yellow
        }
    }

    "4" {
        Write-Host ""
        Write-Host "📖 ABRIENDO GUÍAS..." -ForegroundColor Cyan
        Write-Host ""
        
        if (Test-Path "GUIA_PUBLICACION_PLAY_STORE.md") {
            notepad "GUIA_PUBLICACION_PLAY_STORE.md"
        }
        if (Test-Path "GUIA_PUBLICACION_APP_STORE.md") {
            Start-Sleep -Seconds 1
            notepad "GUIA_PUBLICACION_APP_STORE.md"
        }
        if (Test-Path "INICIO_RAPIDO_PUBLICACION.md") {
            Start-Sleep -Seconds 1
            notepad "INICIO_RAPIDO_PUBLICACION.md"
        }
    }

    "5" {
        Write-Host ""
        Write-Host "👋 ¡Hasta luego!" -ForegroundColor Cyan
        exit 0
    }

    default {
        Write-Host ""
        Write-Host "❌ Opción inválida" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Presiona cualquier tecla para salir" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
