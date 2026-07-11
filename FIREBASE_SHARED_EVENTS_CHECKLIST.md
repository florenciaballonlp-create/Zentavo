# Firebase Shared Events Checklist

## 1) Dependencias Flutter
- Verificar en `pubspec.yaml` que existan:
  - `firebase_core`
  - `cloud_firestore`
- Ejecutar:
  - `flutter pub get`

## 2) Configuración Firebase del proyecto
- Crear proyecto en Firebase Console.
- Agregar app iOS y Android.
- Descargar archivos de configuración:
  - iOS: `GoogleService-Info.plist`
  - Android: `google-services.json`

## 3) Integración iOS
- Copiar `GoogleService-Info.plist` dentro de `ios/Runner/`.
- Asegurar que el plist esté incluido en el target Runner en Xcode.
- Ejecutar en `ios/`:
  - `pod install` (si aplica en tu entorno)

## 4) Integración Android
- Copiar `google-services.json` dentro de `android/app/`.
- Verificar plugin de Google services en Gradle (si no está).

## 5) Inicialización app
- Confirmar que `main.dart` inicializa Firebase cuando la flag esté activa:
  - `USE_FIREBASE_SHARED_EVENTS=true`
- Comando de ejemplo (debug):
  - `flutter run --dart-define=USE_FIREBASE_SHARED_EVENTS=true`

## 6) Reglas Firestore
- Archivo local: `firestore.rules`
- Archivo de config: `firebase.json`
- Deploy reglas (con Firebase CLI):
  - `firebase deploy --only firestore:rules`

## 7) Prueba E2E entre dos teléfonos
- Dispositivo A:
  - Crear evento compartido.
  - Compartir código corto.
- Dispositivo B:
  - Unirse con código corto.
  - Confirmar que evento aparece en lista.
- Validar sync:
  - A agrega gasto y participante.
  - B confirma que ve los cambios.
  - B elimina un gasto.
  - A confirma actualización.

## 8) Fallback sin Firebase
- Si la flag está desactivada o Firebase no inicia:
  - Compartir y unirse por token `ZENTAVO_EVT:...`
  - El flujo local debe seguir funcionando.

## 9) Checklist de release
- Revisar que las reglas desplegadas coincidan con `firestore.rules`.
- Probar en build release con la flag activa.
- Confirmar que no hay errores en logs de Firestore.
