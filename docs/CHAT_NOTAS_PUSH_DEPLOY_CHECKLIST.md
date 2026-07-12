# Checklist de deploy - Chat, Notas y Push

## 1. Pre-requisitos locales

- Tener Flutter y Firebase CLI instalados.
- Tener sesión iniciada en Firebase CLI:
  - `firebase login`
- Seleccionar proyecto Firebase (si no tienes `.firebaserc`):
  - `firebase use <project-id>`

## 2. Dependencias

### App Flutter

1. Desde la raiz del repo:
   - `flutter pub get`

### Cloud Functions

1. Entrar a la carpeta de funciones:
   - `cd functions`
2. Instalar paquetes:
   - `npm install`
3. Volver a la raiz:
   - `cd ..`

## 3. Deploy de Firestore

1. Reglas de seguridad:
   - `firebase deploy --only firestore:rules`
2. Indices:
   - `firebase deploy --only firestore:indexes`

## 4. Deploy de Functions (push)

1. Publicar funciones:
   - `firebase deploy --only functions`

Funciones incluidas:
- `onDirectMessageCreated`
- `onEventMessageCreated`
- `onEventNoteCreated`

## 5. Configuracion de plataforma para push

### iOS

- Verificar en Xcode (Runner target):
  - Signing & Capabilities > agregar `Push Notifications`
  - Signing & Capabilities > agregar `Background Modes`
  - En `Background Modes`, activar `Remote notifications`
- Verificar APNs key/cert configurada en Firebase Console para iOS.

### Android

- Verificar `google-services.json` correcto para el package app.
- Verificar permisos y config de FCM en `AndroidManifest` segun plantilla de `firebase_messaging`.

## 6. Validacion funcional (obligatoria)

### A. Chat directo

1. Usuario A envia mensaje a B.
2. Usuario B ve contador numerico en lista de mensajes.
3. Usuario B abre hilo y contador vuelve a 0.
4. Si B tiene app cerrada o en segundo plano, llega push y al tocar abre hilo directo.

### B. Chat de evento

1. Usuario A envia mensaje en evento.
2. Usuario B ve contador numerico en tab de eventos.
3. Push abre chat del evento correcto.

### C. Notas de evento

1. Usuario A crea nota.
2. Usuario B recibe push de nota.
3. Al tocar, abre notas del evento y resalta la nota destino.

## 7. Validacion de datos en Firestore

Revisar que se creen/actualicen:
- `direct_chats/*`
- `direct_chats/*/messages/*`
- `event_chats/*`
- `event_chats/*/messages/*`
- `event_notes/*`
- `event_notes/*/posts/*`
- `users/*/devices/*` (tokens push)

## 8. Rollback rapido

Si hay incidente:

1. Revertir functions a version previa y redeploy:
   - `firebase deploy --only functions`
2. Revertir reglas/indexes al commit previo y redeploy:
   - `firebase deploy --only firestore:rules,firestore:indexes`

## 9. Nota de seguridad MVP

El estado actual permite operacion social en modo MVP sin login obligatorio.
Para produccion robusta, migrar a reglas estrictas con autenticacion Firebase Auth y control por UID validado.
