# Firebase Shared Events - Quick Test (10 min)

## Objetivo
Validar en dos dispositivos que el flujo por codigo corto funciona y sincroniza cambios.

## Precondiciones
- Build con flag activa:
  - `--dart-define=USE_FIREBASE_SHARED_EVENTS=true`
- Reglas desplegadas desde `firestore.rules`.
- Ambos dispositivos con la misma version de app.

## Escenario A (alta y union)
1. Dispositivo A: crear evento compartido.
2. Dispositivo A: compartir codigo corto (6 caracteres).
3. Dispositivo B: unirse con ese codigo.
4. Resultado esperado:
   - El evento aparece en B con nombre, presupuesto y participantes.

## Escenario B (sync de cambios)
1. Dispositivo A: agregar un gasto.
2. Dispositivo B: abrir/reabrir detalle del evento.
3. Resultado esperado:
   - B ve el gasto nuevo.
4. Dispositivo B: eliminar ese gasto.
5. Dispositivo A: abrir/reabrir detalle del evento.
6. Resultado esperado:
   - A ya no ve el gasto eliminado.

## Escenario C (participantes)
1. Dispositivo A: agregar participante.
2. Dispositivo B: abrir/reabrir detalle.
3. Resultado esperado:
   - B ve el nuevo participante.

## Escenario D (fallback)
1. Ejecutar build sin flag o con Firebase no inicializado.
2. Resultado esperado:
   - El codigo corto no une entre dispositivos.
   - El token `ZENTAVO_EVT:...` sigue permitiendo importar evento.

## Criterio de salida
- Todos los resultados esperados cumplen sin crash ni duplicados de evento.
