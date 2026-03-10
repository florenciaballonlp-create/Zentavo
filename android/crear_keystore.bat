@echo off
chcp 65001 >nul
echo ========================================
echo   CREAR KEYSTORE PARA ZENTAVO
echo ========================================
echo.
echo Este comando te hará varias preguntas.
echo.
echo DATOS A INGRESAR:
echo   Contraseña: Argentina2025!
echo   Reingresar contraseña: Argentina2025!
echo   Nombre: Florencia Ballon
echo   Unidad organizativa: Desarrollo
echo   Organización: Zentavo
echo   Ciudad: Cremona
echo   Estado/Provincia: Cremona
echo   Código país: IT
echo   ¿Es correcto? Escribe: si
echo   Contraseña llave: (presiona Enter para usar la misma)
echo.
echo ========================================
echo.
pause
echo.
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore zentavo-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias zentavo-key
echo.
echo ========================================
if exist zentavo-release-key.jks (
    echo ✓ KEYSTORE CREADO EXITOSAMENTE!
    echo.
    echo Archivo: zentavo-release-key.jks
    echo.
    echo IMPORTANTE: Guarda este archivo en lugar seguro
) else (
    echo × Error al crear keystore
)
echo ========================================
echo.
pause
