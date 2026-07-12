# Release Final Runbook - Build 107

Fecha: 2026-07-12
Scope: cierre final para publicar chat/notas/push en iOS TestFlight y Google Play.

## Estado actual
- Build de app versionado: `1.2.6+107`.
- Código y docs publicados en GitHub:
  - Rama: `main`
  - Tag: `build-107`

## Gate 0: Seguridad (bloqueante)
Objetivo: sacar modo MVP sin auth antes de abrir release.

1. En `firestore.rules`:
- Desactivar bypass `mvpNoAuthEnabled`.
- Exigir `request.auth != null` para operaciones de social/chat/notas/devices.
- Permitir acceso sólo a participantes/miembros en cada colección.

2. Tokens de dispositivos:
- `users/{uid}/devices/{token}` sólo lectura/escritura para ese `uid` autenticado.

3. Deploy de reglas e índices:
- `firebase deploy --only firestore:rules,firestore:indexes`

Criterio de salida:
- Usuario no autenticado no puede leer/escribir chats/notas/devices.
- Usuario autenticado sólo ve recursos donde participa.

## Gate 1: iOS Push (bloqueante)
Objetivo: asegurar entrega FCM en dispositivos reales.

1. Xcode -> Runner -> Signing & Capabilities:
- Activar `Push Notifications`.
- Activar `Background Modes` con `Remote notifications`.
- Confirmar creación de entitlements con `aps-environment`.

2. Firebase Console:
- Cargar APNs key/cert para bundle id de release.

3. App runtime:
- Confirmar permiso de notificaciones aceptado.
- Confirmar token FCM persistido en `users/{uid}/devices/*`.

Criterio de salida:
- Push directo y de evento llegan en foreground/background/app cerrada.

## Gate 2: QA E2E (bloqueante)
Objetivo: validar flujos críticos en 2 dispositivos reales.

1. Amistad QR:
- Escaneo A->B crea vínculo mutuo sin segundo QR.
- Mensaje UI correcto con/sin nube.

2. Mensajes:
- Chat directo: envío/recepción/no leídos/mark-as-read.
- Chat evento: idem.

3. Notas evento:
- Crear, editar, fijar, abrir por push con `postId` resaltado.

4. Resiliencia:
- Sin conexión: fallback local de amistad y sincronización posterior.

Criterio de salida:
- Sin regresiones visuales ni errores bloqueantes.

## Gate 3: Build y distribución

### Android (AAB)
Precondición: Flutter instalado localmente o pipeline CI con workflow Android.

Comandos locales:
1. `flutter clean`
2. `flutter pub get`
3. `flutter build appbundle --release --build-name=1.2.6 --build-number=107`

Salida esperada:
- `build/app/outputs/bundle/release/app-release.aab`

### iOS (TestFlight)
Precondición: certificados/perfiles válidos + capacidades push configuradas.

Flujo sugerido:
1. `flutter build ipa --release --build-name=1.2.6 --build-number=107`
2. Subida con Transporter/Xcode Organizer.

## Gate 4: Publicación controlada
1. Subir TestFlight interno primero.
2. Monitorear 24-48h métricas de push/chat/notas.
3. Abrir rollout gradual en Google Play.

## Rollback
1. Mantener release anterior estable como fallback.
2. Si falla push/chat en producción:
- pausar rollout,
- revertir a tag estable anterior,
- corregir y relanzar con nuevo build.

## Evidencias mínimas para cerrar release
- Capturas de QA E2E.
- Registro de deploy de rules/indexes.
- Confirmación de push en iOS y Android (3 estados de app).
- AAB generado y validado.
- Build iOS procesado en App Store Connect.
