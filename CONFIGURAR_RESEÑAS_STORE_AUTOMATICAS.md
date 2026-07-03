# Configurar reseñas automáticas (App Store + Google Play)

Este flujo actualiza `docs/assets/reviews.json` automáticamente desde las tiendas.

## 1) Variables del repositorio en GitHub

En GitHub: `Settings -> Secrets and variables -> Actions -> Variables`

Crear:

- `APPLE_APP_ID`: ID numérico de la app en App Store.
- `GOOGLE_PLAY_APP_ID`: package name de Android (por ejemplo `com.zentavo.app`).

Importante:

- La workflow falla con error claro si falta alguna de estas dos variables.

## 2) Workflow

Archivo incluido:

- `.github/workflows/store-reviews-sync.yml`

Se ejecuta:

- Diariamente (cron).
- Manualmente desde `Actions -> Sync Store Reviews -> Run workflow`.

Modo manual recomendado (sin tocar Variables):

- En `Run workflow`, completar `apple_app_id`.
- `google_play_app_id` ya viene con default `com.zentavo.control_gastos`.

Prioridad de valores:

- Si completas inputs manuales, esos valores tienen prioridad.
- Si no completas inputs, se usan `vars.APPLE_APP_ID` y `vars.GOOGLE_PLAY_APP_ID`.

## 3) Script

Archivos incluidos:

- `scripts/review-sync/update-reviews.mjs`
- `scripts/review-sync/package.json`

El script:

- Trae reseñas de App Store y Google Play en varios idiomas.
- Filtra reseñas vacías/cortas.
- Prioriza reseñas recientes y de rating >= 4.
- Actualiza `docs/assets/reviews.json`.

## 4) Publicación en web

Tu landing ya está lista para consumir `docs/assets/reviews.json`.
No hace falta tocar `docs/index.html` para nuevas reseñas.
