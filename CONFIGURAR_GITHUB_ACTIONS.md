# 🚀 Configuración de GitHub Actions para Zentavo

## ✅ ¿Qué se Ha Configurado?

Se han creado 3 workflows automáticos en `.github/workflows/`:

1. **ios-build.yml** - Compila la app para iOS (macOS runner)
2. **android-build.yml** - Compila APK y AAB para Android
3. **windows-build.yml** - Compila ejecutable para Windows

## 📱 Compilación Automática

### ¿Cuándo se ejecutan?

Los workflows se ejecutan automáticamente cuando:
- ✅ Haces `git push` a la rama `main`
- ✅ Modificas archivos en `lib/`, `ios/`, `android/`, `windows/` o `assets/`
- ✅ Modificas `pubspec.yaml`
- ✅ También puedes ejecutarlos manualmente desde GitHub

### Compilaciones Actuales (Sin Firma)

**Estado actual:** ✅ Funcionando de inmediato

Los workflows ya están listos para compilar:
- **iOS**: IPA sin firmar (Runner.app)
- **Android**: APK y AAB sin firmar
- **Windows**: ZIP con ejecutable

**¿Dónde descargar?**
1. Ve a tu repo: https://github.com/florenciaballonlp-create/Zentavo
2. Click en "Actions" (arriba)
3. Selecciona el workflow más reciente
4. Scroll abajo hasta "Artifacts"
5. Descarga los archivos compilados

---

## 🔐 Configuración para Apps Firmadas (Play Store / App Store)

Para publicar en tiendas oficiales, necesitas configurar certificados.

### 📱 iOS (App Store)

#### Requisitos Previos:
1. **Cuenta Apple Developer** ($99 USD/año): https://developer.apple.com
2. **Certificados y Provisioning Profile**

#### Pasos para Obtener Certificados:

**Opción A: Usando Fastlane Match (Recomendado)**
```bash
# Instala Fastlane
sudo gem install fastlane

# Navega a la carpeta iOS
cd ios

# Inicializa Match (guarda certificados en repo privado)
fastlane match init

# Genera certificados de distribución
fastlane match appstore
```

**Opción B: Manualmente desde Xcode**
1. Abre Xcode (necesitas una Mac o servicio cloud)
2. Ve a Preferences → Accounts
3. Agrega tu Apple ID
4. Manage Certificates → Create "Apple Distribution"
5. Exporta el certificado como `.p12`

#### Configurar Secretos en GitHub:

1. Ve a tu repo → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Agrega estos secretos:

| Nombre del Secreto | Descripción | Cómo Obtenerlo |
|-------------------|-------------|----------------|
| `IOS_CERTIFICATE_BASE64` | Certificado de distribución | `base64 -i certificate.p12` |
| `IOS_CERTIFICATE_PASSWORD` | Contraseña del certificado | La que usaste al exportar |
| `IOS_PROVISIONING_PROFILE_BASE64` | Provisioning profile | `base64 -i profile.mobileprovision` |
| `KEYCHAIN_PASSWORD` | Contraseña temporal | Cualquier contraseña segura |

**Ejemplo de comandos:**
```bash
# En Mac/Linux
base64 -i MyCertificate.p12 | pbcopy  # Copia al portapapeles
base64 -i MyProfile.mobileprovision | pbcopy

# En Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("MyCertificate.p12")) | Set-Clipboard
```

### 🤖 Android (Google Play Store)

#### Requisitos Previos:
1. **Cuenta Google Play Console** (una sola vez $25 USD)
2. **Keystore para firmar apps**

#### Generar Keystore:

```bash
# Genera un nuevo keystore (guarda la contraseña segura)
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Ejemplo de respuesta:
# Enter keystore password: TU_PASSWORD_SEGURO
# Re-enter new password: TU_PASSWORD_SEGURO
# What is your first and last name? Zentavo App
# ...
```

#### Configurar Secretos en GitHub:

1. Repo → Settings → Secrets → Actions → New secret
2. Agrega:

| Nombre del Secreto | Valor |
|-------------------|-------|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Contraseña del keystore |
| `ANDROID_KEY_PASSWORD` | Contraseña de la key (puede ser igual) |
| `ANDROID_KEY_ALIAS` | `upload` (o el alias que usaste) |

**Comandos:**
```bash
# En Mac/Linux
base64 -i upload-keystore.jks | pbcopy

# En Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

#### Configurar build.gradle:

El archivo `android/app/build.gradle.kts` ya debe estar configurado, pero verifica que tenga:

```kotlin
// En signingConfigs, antes de buildTypes:
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

---

## 🔄 Uso de los Workflows

### Ejecución Manual:

1. Ve a GitHub → Actions
2. Selecciona el workflow (iOS Build, Android Build, etc.)
3. Click en "Run workflow"
4. Selecciona la rama `main`
5. Click "Run workflow"

### Ejecución Automática:

Simplemente haz push a `main`:
```bash
git add .
git commit -m "feat: nueva funcionalidad"
git push origin main
```

GitHub Actions se ejecutará automáticamente y en 5-15 minutos tendrás:
- ✅ iOS: IPA sin firmar (o firmado si configuraste secretos)
- ✅ Android: APK + AAB
- ✅ Windows: ZIP con ejecutable

---

## 📥 Descargar Builds

### Desde GitHub:
1. Repo → Actions → Click en el workflow ejecutado
2. Scroll abajo → "Artifacts"
3. Descarga:
   - `Zentavo-iOS-unsigned.ipa`
   - `Zentavo-Android-APK.apk`
   - `Zentavo-Windows-x64.zip`

### Instalación:

**iOS (sin firma):**
- Solo para pruebas en dispositivos con jailbreak
- Para distribución normal, necesitas firmar

**Android:**
```bash
# Instalar APK en dispositivo conectado
adb install app-release.apk
```

**Windows:**
1. Descomprime el ZIP
2. Ejecuta `zentavo.exe`

---

## 🎯 Próximos Pasos

### Para Publicar en Tiendas:

1. **App Store (iOS)**:
   - Configura los secretos de certificación
   - El workflow generará IPA firmado
   - Sube a App Store Connect manualmente o con Fastlane

2. **Google Play (Android)**:
   - Configura el keystore
   - El workflow generará AAB firmado
   - Sube a Google Play Console

3. **Microsoft Store (Windows)**:
   - Necesitas cuenta de Microsoft Partner
   - Empaqueta con MSIX
   - Sube manualmente

---

## 🐛 Solución de Problemas

### ❌ "iOS build failed"
**Posibles causas:**
- CocoaPods versión incorrecta
- Certificados expirados
- Provisioning profile inválido

**Solución:**
- Revisa los logs en Actions
- Verifica que los secretos estén correctos
- Regenera certificados si es necesario

### ❌ "Android signing failed"
**Posibles causas:**
- Keystore password incorrecto
- Alias inválido
- Archivo keystore corrupto

**Solución:**
- Verifica los secretos en GitHub
- Regenera el keystore con los comandos de arriba
- Convierte correctamente a base64

### ❌ "Windows build out of memory"
**Causa:** Compilación muy pesada

**Solución:**
- Ya configurado con `continue-on-error: true`
- Descarga y compila localmente si persiste

---

## 📊 Estado de los Workflows

Puedes ver el estado en tiempo real en:
https://github.com/florenciaballonlp-create/Zentavo/actions

**Badges para tu README:**
```markdown
![iOS Build](https://github.com/florenciaballonlp-create/Zentavo/workflows/📱%20iOS%20Build/badge.svg)
![Android Build](https://github.com/florenciaballonlp-create/Zentavo/workflows/🤖%20Android%20Build/badge.svg)
![Windows Build](https://github.com/florenciaballonlp-create/Zentavo/workflows/🪟%20Windows%20Build/badge.svg)
```

---

## ✅ Checklist de Configuración

### Inmediato (Ya funciona):
- [x] Compilación iOS sin firmar
- [x] Compilación Android sin firmar
- [x] Compilación Windows
- [x] Descarga de artifacts

### Para Producción (Requiere configuración):
- [ ] Cuenta Apple Developer ($99/año)
- [ ] Certificados iOS configurados
- [ ] Secretos iOS en GitHub
- [ ] Keystore Android generado
- [ ] Secretos Android en GitHub
- [ ] IPA firmado para App Store
- [ ] AAB firmado para Play Store

---

## 💡 Consejos

1. **Guarda tus certificados seguros**: Nunca los subas al repo
2. **Usa secretos de GitHub**: Más seguro que archivos en el repo
3. **Documenta tus passwords**: Guárdalos en un password manager
4. **Prueba en local primero**: Antes de confiar en el CI/CD
5. **Monitorea los workflows**: Revisa los logs si algo falla

---

## 📞 Recursos Adicionales

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Fastlane iOS**: https://docs.fastlane.tools/
- **Android Signing**: https://developer.android.com/studio/publish/app-signing
- **Flutter CI/CD**: https://docs.flutter.dev/deployment/cd

---

**¡Listo!** Ahora cada vez que hagas push a `main`, GitHub compilará automáticamente tu app para iOS, Android y Windows. 🚀
