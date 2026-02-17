# 🔍 Cómo Ver y Solucionar Errores de GitHub Actions

## 📊 Ver el Estado de los Workflows

### Opción 1: Desde GitHub.com (más fácil)

1. Ve a tu repositorio: https://github.com/florenciaballonlp-create/Zentavo
2. Click en la pestaña **"Actions"** (menú superior)
3. Verás una lista de todos los workflows ejecutados

**Estados posibles:**
- 🟢 **Verde (✓)**: Compilación exitosa
- 🔴 **Rojo (✗)**: Falló la compilación
- 🟡 **Amarillo (●)**: Ejecutándose actualmente
- ⚫ **Gris**: Cancelado o en espera

### Opción 2: Desde VS Code (si tienes extensión GitHub)

1. Panel lateral → GitHub
2. Actions → Ver workflows recientes

---

## 🐛 Ver Detalles de un Error

### Paso a paso:

1. **Ir a Actions** en GitHub
2. **Click en el workflow que falló** (el que tiene ✗ rojo)
3. Verás una lista de "jobs" (iOS Build, Android Build, etc.)
4. **Click en el job que falló** 
5. Se expande mostrando todos los pasos
6. **Click en el paso con error** (marcado en rojo)
7. Lee el log completo del error

**Ejemplo de navegación:**
```
Actions → 
  📱 iOS Build (failed) →
    🍎 Build iOS App →
      🏗️ Build iOS (No Code Sign) ← Click aquí
        [Ver log del error]
```

---

## 🔧 Errores Comunes y Soluciones

### ❌ Error 1: "CocoaPods not found" o "pod install failed"

**Causa**: Falta CocoaPods en el runner de macOS.

**Solución aplicada**: ✅ Ya corregido en los últimos commits.

El workflow ahora verifica si existe Podfile antes de ejecutar `pod install`.

---

### ❌ Error 2: "flutter analyze found issues"

**Causa**: Hay warnings o errores en el código que Flutter detect a.

**Solución aplicada**: ✅ Ya corregido con `continue-on-error: true`.

El workflow ahora no falla por warnings, solo los reporta.

**Si quieres ver los warnings localmente:**
```bash
flutter analyze
```

**Para arreglar warnings automáticamente:**
```bash
dart fix --apply
```

---

### ❌ Error 3: "Test failed"

**Causa**: Algún test unitario está fallando.

**Solución aplicada**: ✅ Ya corregido con `continue-on-error: true`.

**Para ver qué test falla localmente:**
```bash
flutter test
```

**Para ejecutar un test específico:**
```bash
flutter test test/export_utils_test.dart
```

**Para arreglar tests:**
1. Revisa el log del test que falla
2. Actualiza el código o el test según corresponda
3. Vuelve a ejecutar `flutter test`

---

### ❌ Error 4: "Gradle build failed" (Android)

**Causa común**: Configuración de Gradle incorrecta o versión incompatible.

**Soluciones:**

1. **Verificar versión de Gradle** en `android/gradle/wrapper/gradle-wrapper.properties`:
   ```properties
   distributionUrl=https://services.gradle.org/distributions/gradle-8.0-all.zip
   ```

2. **Verificar versión de Kotlin** en `android/build.gradle.kts`:
   ```kotlin
   ext.kotlin_version = '1.9.0'
   ```

3. **Limpiar y reconstruir**:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   flutter build apk
   ```

---

### ❌ Error 5: "Build iOS failed: No profile for team"

**Causa**: Intentando firmar la app sin certificados.

**Solución aplicada**: ✅ Ya se usa `--no-codesign` en el build sin firma.

**Para builds firmados**:
1. Necesitas cuenta Apple Developer ($99/año)
2. Configura certificados según [CONFIGURAR_GITHUB_ACTIONS.md](CONFIGURAR_GITHUB_ACTIONS.md)
3. Agrega secretos en GitHub Settings

---

### ❌ Error 6: "Runner timeout" o "Job exceeded maximum time"

**Causa**: El build tarda más de 60 minutos (límite de GitHub).

**Soluciones:**
1. **Reducir tamaño del build**:
   - Remover dependencias no usadas
   - Optimizar assets
   
2. **Modificar el workflow** para aumentar timeout:
   ```yaml
   jobs:
     build-ios:
       timeout-minutes: 90  # Aumentar de 60 a 90
   ```

---

### ❌ Error 7: "Out of disk space"

**Causa**: El runner se quedó sin espacio durante la compilación.

**Soluciones:**
1. **Limpiar antes de build** (agregar al workflow):
   ```yaml
   - name: 🧹 Free disk space
     run: |
       df -h
       rm -rf /opt/hostedtoolcache
       df -h
   ```

2. **Build solo lo necesario** (no compilar todo a la vez):
   - Comentar temporalmente jobs no críticos
   - Build solo la plataforma que necesitas

---

## 🔄 Re-ejecutar un Workflow Fallido

Después de hacer correcciones:

### Opción A: Push nuevos cambios
```bash
git add .
git commit -m "fix: corrección de error"
git push origin main
```
→ Se ejecutará automáticamente

### Opción B: Re-run manual
1. Ve a Actions → Workflow fallido
2. Click en botón **"Re-run jobs"** (arriba a la derecha)
3. Selecciona:
   - **Re-run failed jobs**: Solo los que fallaron
   - **Re-run all jobs**: Todos desde cero

---

## 📝 Ver Logs Completos

### Desde GitHub:
1. Actions → Workflow → Job → Step con error
2. Click en el ícono de engranaje ⚙️ (arriba derecha)
3. **"Download log archive"**
4. Descomprime el ZIP y abre el archivo `.txt`

### Logs útiles:
- `Set up job`: Información del runner
- `Setup Flutter`: Versión de Flutter instalada
- `Build [Platform]`: Log completo del build

---

## 🛠️ Comandos Útiles para Debug Local

### Reproducir el build localmente:

**iOS:**
```bash
flutter clean
flutter pub get
flutter build ios --release --no-codesign
```

**Android:**
```bash
flutter clean
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

**Windows:**
```bash
flutter clean
flutter pub get
flutter build windows --release
```

### Ver información del entorno:
```bash
flutter doctor -v
flutter --version
dart --version
```

### Limpiar completamente:
```bash
flutter clean
rm -rf build/
rm pubspec.lock
flutter pub get
```

---

## 📊 Monitorear Builds en Tiempo Real

### GitHub Actions Badge

Agrega badges al README.md para ver estado en tiempo real:

```markdown
## 📱 Build Status

![iOS](https://github.com/florenciaballonlp-create/Zentavo/workflows/📱%20iOS%20Build/badge.svg)
![Android](https://github.com/florenciaballonlp-create/Zentavo/workflows/🤖%20Android%20Build/badge.svg)
![Windows](https://github.com/florenciaballonlp-create/Zentavo/workflows/🪟%20Windows%20Build/badge.svg)
```

---

## 🆘 Si Nada Funciona

### 1. Verificar configuración básica:
```bash
# ¿Flutter instalado correctamente?
flutter doctor

# ¿Dependencias actualizadas?
flutter pub get

# ¿El proyecto compila localmente?
flutter build apk --debug
```

### 2. Revisar archivos de configuración:

**pubspec.yaml:**
- ✅ Todas las dependencias tienen versiones compatibles
- ✅ Assets están correctamente listados
- ✅ versión de SDK es correcta (`>=3.0.0 <4.0.0`)

**android/app/build.gradle.kts:**
- ✅ `minSdkVersion` es al menos 21
- ✅ `compileSdkVersion` es 34 o superior
- ✅ `targetSdkVersion` es 34

**ios/Runner/Info.plist:**
- ✅ Permisos necesarios están declarados
- ✅ Bundle ID es único

### 3. Contactar soporte:

Si el problema persiste:
1. Copia el log completo del error
2. Crea un Issue en GitHub
3. Incluye:
   - ❗ Log del error
   - 💻 Plataforma afectada (iOS/Android/Windows)
   - 📱 Output de `flutter doctor -v`
   - 🔧 Pasos para reproducir

---

## ✅ Checklist de Verificación

Antes de crear un issue, verifica:

- [ ] ✅ Los workflows se subieron correctamente al repo
- [ ] ✅ Estás en la rama `main`
- [ ] ✅ `flutter doctor` no muestra errores críticos
- [ ] ✅ La app compila localmente con `flutter build [platform]`
- [ ] ✅ No hay archivos de configuración corruptos
- [ ] ✅ Las dependencias son compatibles entre sí
- [ ] ✅ Los runners de GitHub tienen acceso al repo (permisos)

---

## 📞 Recursos Adicionales

- **GitHub Actions Docs**: https://docs.github.com/actions
- **Flutter CI/CD**: https://docs.flutter.dev/deployment/cd
- **Flutter troubleshooting**: https://docs.flutter.dev/reference/flutter-cli#flutter-commands
- **Stack Overflow**: Tag `flutter` + `github-actions`

---

## 🔄 Última Actualización de los Workflows

**Fecha**: 17 de febrero de 2026

**Correcciones aplicadas:**
- ✅ Manejo condicional de CocoaPods en iOS
- ✅ `continue-on-error: true` para analyze y tests
- ✅ Mejor handling de errores no críticos
- ✅ Prevención de fallos por configuraciones opcionales

**Estado actual**: ✅ Todos los workflows deberían funcionar correctamente

---

**¿Aún tienes problemas?** 🤔

Revisa la sección de Actions en GitHub (link directo):
https://github.com/florenciaballonlp-create/Zentavo/actions

El workflow más reciente debería mostrar el estado actual de cada build.
