# Release Go/No-Go - Build 107

Fecha: 2026-07-12
Owner: Zentavo
Build target: 1.2.6+107

## Decision Board

Estado final:
- [ ] GO
- [x] NO-GO

Regla:
- Si cualquier item bloqueante queda sin check, la decision es NO-GO.

## Gate A - Seguridad (bloqueante)

- [x] Regla strict-auth activa en Firestore (sin bypass MVP).
- [x] Solo usuarios autenticados pueden leer/escribir chats/notas/devices.
- [x] Tokens en users/{uid}/devices/* restringidos al owner.
- [ ] Secret leak mitigado: key revocada/rotada en Google Cloud.
- [ ] GitHub Secret Scanning alert cerrada como revoked.

Evidencia:
- Commit de hardening: e889496
- Commit remediacion secreto: 4fece28 (historial reescrito)

## Gate B - iOS Push (bloqueante)

- [x] Runner.entitlements creado con aps-environment.
- [x] UIBackgroundModes incluye remote-notification.
- [x] project.pbxproj tiene CODE_SIGN_ENTITLEMENTS y APS_ENVIRONMENT.
- [ ] En Xcode se visualiza Push Notifications capability activa.
- [ ] En Xcode se visualiza Background Modes > Remote notifications activo.
- [ ] APNs key/cert cargada y valida en Firebase Console para bundle release.

Evidencia:
- Commit iOS push config: 57f4f16

## Gate C - QA E2E (bloqueante)

- [ ] Prueba amistad QR A->B crea vinculacion mutua sin segundo QR.
- [ ] Mensaje UI correcto con nube disponible.
- [ ] Mensaje UI correcto con fallback local sin nube.
- [ ] Chat directo: envio/recepcion/no leidos/mark-as-read.
- [ ] Chat evento: envio/recepcion/no leidos/mark-as-read.
- [ ] Notas evento: crear/editar/fijar.
- [ ] Push abre destino correcto en:
  - [ ] foreground
  - [ ] background
  - [ ] app cerrada

## Gate D - Distribucion

### Android (AAB)
- [ ] AAB generado para 1.2.6+107.
- [ ] Subida a Google Play Console completada.
- [ ] Release track configurado (internal/testing/production segun plan).

### iOS (IPA/TestFlight)
- [ ] IPA de build 107 generado.
- [ ] Subida a App Store Connect completada.
- [ ] Build procesado y visible en TestFlight.

## Gate E - Operacion post-release

- [ ] Monitoreo de 24-48h sin incidentes de push/chat/notas.
- [ ] Sin errores criticos en analytics/logs.
- [ ] Plan de rollback documentado y probado.

## Resultado

Decision final:
- [ ] GO
- [x] NO-GO

Aprobado por:
- Producto: __________________
- QA: __________________
- Tech: __________________
- Fecha/Hora: __________________
