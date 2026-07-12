# Worklog Build 107 - Zentavo

Fecha: 2026-07-12

## Objetivo de esta actualización
- Consolidar los cambios ya implementados (amistades mutuas por QR, chats, notas por evento, push y deep links) y preparar subida como nueva actualización.

## Cambios funcionales ya implementados
1. QR de amistad con vinculación mutua automática en nube cuando hay conectividad/Firebase disponible.
2. Aviso en pantalla corregido:
- Si hubo sincronización en nube: indica vinculación mutua automática.
- Si no hubo nube: indica que quedó local y que falta conexión para sincronizar.
3. Sincronización de amigos nube/local al abrir perfil.
4. Chat directo entre amigos (threads, envío, no leídos).
5. Chat por evento (threads, envío, no leídos).
6. Notas/blog por evento (crear, editar, fijar y resaltado por postId).
7. Push notifications para mensajes/notas (cliente + Cloud Functions).
8. Deep links desde push para destino directo/evento/nota.
9. Mock visuales y checklist operativo de deploy/rollback.

## Build
- Versionado actualizado a: `1.2.6+107` en `pubspec.yaml`.

## Validación técnica registrada
1. Problemas del editor en archivos modificados: sin errores reportados al momento de la validación previa.
2. No se pudo ejecutar `flutter analyze` en este entorno por ausencia del comando `flutter`.

## Readiness actual (antes de TestFlight abierta)
- Listo:
1. Flujo funcional de social/chat/notas/push a nivel código.
2. Navegación y payloads para deep links.
3. Checklist de despliegue documentado.

- Pendiente crítico:
1. Endurecer `firestore.rules` para producción (quitar bypass MVP sin auth).
2. Restringir acceso a `users/*/devices/*` para proteger tokens.
3. Configurar capacidades iOS Push Notifications + Background Modes (Remote notifications) y entitlements.
4. Verificar APNs en Firebase Console para el bundle iOS de release.
5. Pruebas E2E en dispositivos reales (foreground/background/app cerrada).

## Archivos clave involucrados
- `lib/profile_screen.dart`
- `lib/firebase_friends_service.dart`
- `lib/messages_screen.dart`
- `lib/direct_chat_service.dart`
- `lib/event_chat_service.dart`
- `lib/event_notes_service.dart`
- `lib/shared_events_screen.dart`
- `lib/main.dart`
- `lib/push_messaging_service.dart`
- `functions/index.js`
- `firestore.rules`
- `firestore.indexes.json`
- `docs/CHAT_NOTAS_PUSH_DEPLOY_CHECKLIST.md`
- `docs/chat-notes-preview.html`

## Estado para retomar
- Se deja preparado Build 107 con todos los avances acumulados.
- Próxima acción recomendada: hardening de seguridad + configuración iOS push y luego corrida de validación final para envío.
