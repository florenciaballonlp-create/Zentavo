# 📱 Sistema de Versionado Automático - Zentavo

## 🎯 Descripción

Sistema simplificado para gestionar versiones de la app en Google Play Store.

## 📂 Archivos

- **android/version.properties**: Contiene `versionCode` y `versionName`
- **increment-version.ps1**: Script para incrementar versiones fácilmente

## 🚀 Uso

### Incrementar Versión

Para actualizar la versión de la app, usa el script:

```powershell
# Para correcciones de bugs (1.0.0 -> 1.0.1)
.\increment-version.ps1 patch

# Para nuevas funcionalidades (1.0.1 -> 1.1.0)
.\increment-version.ps1 minor

# Para cambios importantes (1.1.0 -> 2.0.0)
.\increment-version.ps1 major
```

### Flujo Completo de Actualización

1. **Haz tus cambios** en el código
2. **Incrementa la versión**:
   ```powershell
   .\increment-version.ps1 patch
   ```
3. **Commit y push**:
   ```powershell
   git add .
   git commit -m "feat: Nueva funcionalidad - v1.0.1"
   git push origin main
   ```
4. **Espera la compilación** (~8-10 minutos)
   - Ve a: https://github.com/florenciaballonlp-create/Zentavo/actions
5. **Descarga el AAB firmado**
   - Click en el workflow completado
   - Descarga `Zentavo-Android-AAB-Signed`
6. **Sube a Google Play Console**
   - https://play.google.com/console
   - Producción > Crear nueva versión
   - Sube el archivo `app-release.aab`
   - Envía para revisión

## 📋 Significado de las Versiones

### versionCode
- Número entero que **siempre aumenta**
- Google Play lo usa para saber cuál es más nueva
- Se incrementa automáticamente con el script
- Ejemplo: 1, 2, 3, 4, 5...

### versionName
- Versión visible para los usuarios
- Formato: `MAJOR.MINOR.PATCH`
- Ejemplos:
  - `1.0.0` - Primera versión
  - `1.0.1` - Corrección de bugs
  - `1.1.0` - Nueva funcionalidad
  - `2.0.0` - Cambio importante/rediseño

## 📊 Guía de Versionado Semántico

| Tipo | Cuándo usar | Ejemplo |
|------|-------------|---------|
| **PATCH** | Correcciones de bugs, mejoras menores | 1.0.0 → 1.0.1 |
| **MINOR** | Nuevas funcionalidades, compatibles con anteriores | 1.0.1 → 1.1.0 |
| **MAJOR** | Cambios importantes, rediseño, incompatibilidades | 1.1.0 → 2.0.0 |

## ✅ Ventajas del Sistema

- ✅ **Simple**: Un solo comando para incrementar versión
- ✅ **Seguro**: Siempre incrementa correctamente
- ✅ **Automático**: GitHub Actions compila automáticamente
- ✅ **Trazabilidad**: Version.properties está en Git
- ✅ **Sin errores**: No más olvidos de incrementar versionCode

## ⚠️ Importante

- ⚠️ **NUNCA** edites `android/version.properties` manualmente
- ⚠️ **SIEMPRE** usa `increment-version.ps1`
- ⚠️ **NUNCA** uses el mismo `versionCode` dos veces
- ⚠️ Google Play rechazará versiones con versionCode duplicado o menor

## 🔧 Configuración Actual

```properties
versionCode=1
versionName=1.0.0
```

Primera versión de la app, lista para publicar.

## 📞 Siguientes Pasos

1. Descarga el AAB firmado de GitHub Actions
2. Prueba la APK en tu dispositivo
3. Crea cuenta en Google Play Console ($25 USD una vez)
4. Sube el AAB y completa la información de la app
5. Envía para revisión
6. Una vez aprobada, ¡tus usuarios podrán descargarla!

Para futuras actualizaciones, solo repite el "Flujo Completo de Actualización" arriba.
