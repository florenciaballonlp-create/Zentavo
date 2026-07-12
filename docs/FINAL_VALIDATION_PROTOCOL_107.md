# Final Validation Protocol - Build 107

Fecha: 2026-07-12
Build objetivo: 1.2.6+107
Estado inicial: NO-GO (seguridad cerrada)

## Objetivo
Cerrar los pendientes bloqueantes para pasar a GO y habilitar subida final a TestFlight/Google Play.

## Precondiciones
- Repo actualizado en main.
- Reglas de Firestore endurecidas ya publicadas en código.
- Credenciales de API restringidas y clave comprometida revocada.

## Bloque 1 - iOS Push real (bloqueante)

1. En Xcode, abrir Runner y verificar capabilities:
- Push Notifications: ON
- Background Modes: ON
- Remote notifications: ON

2. En Firebase Console:
- APNs key/cert cargada para bundle de release.
- Confirmar proyecto correcto: zentavo-ae381.

3. Prueba funcional de push en iPhone real:
- Foreground: llega notificación local/visible.
- Background: llega push y abre destino correcto.
- App cerrada: llega push, tap abre thread/nota correcta.

Criterio de salida del bloque:
- 3/3 estados validados sin fallo.

## Bloque 2 - QA E2E social (bloqueante)

1. Amistad por QR:
- Escaneo A->B crea vínculo mutuo sin segundo QR.
- Mensaje correcto con nube disponible.
- Mensaje correcto con fallback local sin nube.

2. Chat directo:
- Envío, recepción, contador de no leídos y mark-as-read.

3. Chat de evento:
- Envío, recepción, no leídos y limpieza al abrir thread.

4. Notas de evento:
- Crear, editar, fijar y abrir destino por push con resaltado.

Criterio de salida del bloque:
- Todos los flujos completos sin bloqueo funcional.

## Bloque 3 - Distribución build 107 (bloqueante)

### Android
1. Generar AAB release 107.
2. Subir a Play Console (internal/testing).
3. Verificar procesamiento correcto del artefacto.

### iOS
1. Generar IPA release 107.
2. Subir a App Store Connect.
3. Confirmar estado procesado en TestFlight.

Criterio de salida del bloque:
- AAB e IPA procesados y visibles en sus consolas.

## Bloque 4 - Go/No-Go final

1. Abrir checklist maestro y marcar pendientes:
- docs/RELEASE_GO_NO_GO_107.md

2. Si todo bloqueante está en check:
- Marcar GO
- Registrar aprobadores y fecha/hora

3. Si falta un bloqueante:
- Mantener NO-GO
- Registrar causa y próximo intento

## Evidencias mínimas a adjuntar
- Capturas de pruebas push (foreground/background/cerrada)
- Capturas de QA E2E
- Captura de build procesado en TestFlight
- Captura de AAB procesado en Play Console
