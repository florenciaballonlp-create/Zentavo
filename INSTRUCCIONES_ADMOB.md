# 📱 Configuración de Google AdMob - Instrucciones

## ✅ Estado Actual

Tu app ya tiene **banners de publicidad integrados** usando IDs de prueba de Google AdMob.

**Banners visibles en:**
- ✅ Pestaña de Transacciones (parte inferior)
- ✅ Pestaña de Ahorros (parte inferior)

## 🎯 Próximos Pasos para Monetizar

### 1. Crear Cuenta de AdMob

1. Ve a [https://admob.google.com](https://admob.google.com)
2. Inicia sesión con tu cuenta de Google
3. Acepta los términos y condiciones
4. Completa la información de pago (necesitas esto para recibir tus ganancias)

### 2. Registrar tu App

**Para Android:**
1. En AdMob, haz clic en "Apps" → "Add App"
2. Selecciona "Android"
3. Nombre de la app: `Zentavo`
4. Package name: `com.example.control_gastos` (verificar en AndroidManifest.xml)
5. AdMob te dará un **App ID** como: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`

**Para iOS:**
1. En AdMob, haz clic en "Apps" → "Add App"
2. Selecciona "iOS"
3. Nombre de la app: `Zentavo`
4. Bundle ID: verificar en Info.plist
5. AdMob te dará un **App ID**

### 3. Crear Unidades de Anuncios

**Banner para Transacciones:**
1. Selecciona tu app en AdMob
2. Haz clic en "Ad units" → "Add ad unit"
3. Selecciona "Banner"
4. Nombre: "Banner Transacciones"
5. Copia el **Ad Unit ID** generado (ej: `ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY`)

**Banner para Ahorros:**
1. Repite el proceso
2. Nombre: "Banner Ahorros"
3. Copia el **Ad Unit ID**

### 4. Reemplazar IDs de Prueba por IDs Reales

#### Archivo: `lib/main.dart`

**Línea ~288 - App ID de AdMob en Android:**
```dart
// AndroidManifest.xml línea 36
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="TU_APP_ID_ANDROID_AQUI"/>
```

**Línea ~295 - Banner Transacciones:**
```dart
_bannerAdTransacciones = BannerAd(
  adUnitId: Platform.isAndroid
      ? 'TU_AD_UNIT_ID_ANDROID_BANNER_TRANSACCIONES' // ⬅️ Reemplazar aquí
      : 'TU_AD_UNIT_ID_IOS_BANNER_TRANSACCIONES',    // ⬅️ Reemplazar aquí
```

**Línea ~312 - Banner Ahorros:**
```dart
_bannerAdAhorros = BannerAd(
  adUnitId: Platform.isAndroid
      ? 'TU_AD_UNIT_ID_ANDROID_BANNER_AHORROS'  // ⬅️ Reemplazar aquí
      : 'TU_AD_UNIT_ID_IOS_BANNER_AHORROS',     // ⬅️ Reemplazar aquí
```

#### Archivo: `android/app/src/main/AndroidManifest.xml` (línea 36)
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="TU_APP_ID_ANDROID_AQUI"/>
```

#### Archivo: `ios/Runner/Info.plist` (línea 51)
```xml
<key>GADApplicationIdentifier</key>
<string>TU_APP_ID_IOS_AQUI</string>
```

### 5. Recompilar la App

Después de reemplazar los IDs:

**Android:**
```bash
flutter build apk --release
```

**iOS (requiere Mac):**
```bash
flutter build ipa --release
```

## 💰 Estimación de Ingresos

Los ingresos dependen de:
- **CPM** (costo por mil impresiones): $0.50 - $3.00 en Latinoamérica
- **CTR** (tasa de clics): 1-3% promedio
- **Usuarios activos diarios**

**Ejemplo:**
- 1,000 usuarios diarios
- 5 vistas de banner por usuario = 5,000 impresiones
- CPM de $1.50 = **$7.50 USD/día** ≈ **$225 USD/mes**

## 🚀 Próximos Pasos Recomendados

1. **Agregar anuncios intersticiales** (pantalla completa entre acciones)
2. **Agregar anuncios con recompensa** (usuario ve video para desbloquear funciones premium)
3. **Implementar Firebase Analytics** para rastrear el comportamiento de usuarios
4. **A/B testing** de posiciones de banners para maximizar ingresos

## ⚠️ Notas Importantes

- **NO hagas clic en tus propios anuncios** - Google puede banear tu cuenta
- Los **IDs de prueba** actuales solo muestran anuncios de demostración, no generan ingresos
- Necesitas **mínimo 100 USD** acumulados para recibir el primer pago
- La aprobación de AdMob puede tomar 24-48 horas

## 📞 Recursos

- [Documentación oficial AdMob](https://developers.google.com/admob)
- [Políticas de AdMob](https://support.google.com/admob/answer/6128543)
- [Centro de ayuda AdMob](https://support.google.com/admob)

---

**¿Necesitas ayuda?** Después de crear tu cuenta de AdMob y obtener los IDs, avísame y actualizaré el código con tus IDs reales.
