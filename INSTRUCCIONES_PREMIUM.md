# 🌟 Guía de Configuración Premium - In-App Purchases

## 📋 Resumen

La app ahora incluye un sistema de **suscripciones Premium** con 2 opciones de compra:

1. **Premium Mensual** - Acceso por 1 mes
2. **Premium Anual** - Acceso por 1 año (más popular)

## 🎁 Funciones Premium

Los usuarios Premium disfrutan de:

- ✅ **Sin Publicidad** - Experiencia completamente libre de anuncios
- ✅ **Backup en la Nube** - Sincronización de datos entre dispositivos
- ✅ **Análisis Avanzados** - Gráficos detallados y proyecciones
- ✅ **Múltiples Monedas** - Manejo de diferentes monedas
- ✅ **Categorías Personalizadas** - Categorías ilimitadas
- ✅ **Soporte Prioritario** - Atención personalizada

## 🔧 Configuración en Google Play Console

### Paso 1: Crear Productos In-App

1. Ve a **Google Play Console** → Tu app → **Monetización** → **Productos In-App**
2. Crea **2 productos** con estos IDs exactos:

#### Producto 1: Premium Mensual
- **ID de producto**: `premium_monthly`- **Nombre**: Premium Mensual
- **Descripción**: Acceso completo a todas las funciones Premium por 1 mes
- **Precio sugerido**: $4.99 USD

#### Producto 2: Premium Anual
- **ID de producto**: `premium_yearly`
- **Nombre**: Premium Anual
- **Descripción**: Acceso completo a todas las funciones Premium por 1 año. ¡Ahorra 40%!
- **Precio sugerido**: $49.99 USD (equivalente a $4.17/mes)

### Paso 2: Configurar Estado de Productos

1. Después de crear cada producto, actívalos cambiando su estado a **"Activo"**
2. Asegúrate de configurar los precios para todos los países donde quieras vender

### Paso 3: Probar Compras (Testing)

Para probar las compras sin gastar dinero real:

1. Ve a **Configuración** → **Licencias de prueba**
2. Agrega las cuentas de Gmail que usarás para probar
3. Las cuentas añadidas podrán hacer compras de prueba sin cargos reales

## 🍎 Configuración en App Store Connect (iOS)

### Paso 1: Crear In-App Purchases

1. Ve a **App Store Connect** → Tu app → **Funciones** → **Compras dentro de la app**
2. Haz clic en **+** para crear nuevos productos

#### Producto 1: Premium Mensual
- **Tipo de producto**: Compra no consumible (Non-Consumable)
- **ID de producto de referencia**: `premium_monthly`
- **Nombre**: Premium Mensual
- **Descripción**: Acceso completo por 1 mes
- **Precio**: Nivel 5 ($4.99 USD)

#### Producto 2: Premium Anual
- **Tipo de producto**: Compra no consumible (Non-Consumable)
- **ID de producto de referencia**: `premium_yearly`
- **Nombre**: Premium Anual
- **Descripción**: Acceso completo por 1 año
- **Precio**: Nivel 50 ($49.99 USD)

#### Producto 3: Premium Vitalicio
- **Tipo de producto**: Compra no consumible (Non-Consumable)
- **ID de producto de referencia**: `premium_lifetime`
- **Nombre**: Premium Vitalicio
- **Descripción**: Acceso permanente
- **Precio**: Nivel 100 ($99.99 USD
1. En **App Store Connect**, ve a **Usuarios y Acceso** → **Testers de Sandbox**
2. Crea cuentas de prueba
3. En tu dispositivo iOS:
   - Ve a **Ajustes** → **App Store** → **Cuenta de Sandbox**
   - Inicia sesión con tu cuenta de prueba
4. Las compras serán gratuitas en modo sandbox

## 📱 Uso en la App

### Acceder a Premium

Los usuarios pueden acceder a la pantalla Premium desde:
- **Menú Principal** → **⋮** (3 puntos) → **Premium** (con ícono dorado)

### Estados de Usuario

1. **Usuario Gratuito**:
   - Ve banners de publicidad
   - Menú muestra opción "Premium"
   - Puede acceder a funciones básicas

2. **Usuario Premium**:
   - Sin banners de publicidad
   - Acceso a todas las funciones
   - Opción "Premium" oculta del menú
   - Puede restaurar compras

### Restaurar Compras

Los usuarios pueden restaurar sus compras si:
- Reinstalaron la app
- Cambiaron de dispositivo
- Perdieron el estado premium

**Botón**: "¿Ya compraste? Restaurar compras" (en pantalla Premium)

## 💻 Detalles Técnicos

### Archivos Modificados

1. **`pubspec.yaml`**
   - Agregado: `in_app_purchase: ^3.2.0`

2. **`lib/premium_screen.dart`** (NUEVO)
   - Pantalla completa de Premium
   - Manejo de compras
   - UI de planes y funciones

3. **`lib/main.dart`**
   - Importado `premium_screen.dart`
   - Variable `_isPremium` para estado
   - Método `_checkPremiumStatus()`
   - Opción Premium en menú
   - Banners ocultos para usuarios Premium

### Almacenamiento Local

El estado Premium se guarda en SharedPreferences:

```dart
// Guardar estado premium
await prefs.setBool('is_premium', true);
await prefs.setString('premium_product_id', 'premium_yearly');
await prefs.setString('premium_purchase_date', DateTime.now().toIso8601String());

// Leer estado premium
bool isPremium = prefs.getBool('is_premium') ?? false;
```

### IDs de Productos

**IMPORTANTE**: Los IDs en el código **DEBEN** coincidir exactamente con los configurados en las tiendas:

```dart
static const String productIdMonthly = 'premium_monthly';
static const String productIdYearly = 'premium_yearly';
static const String productIdLifetime = 'premium_lifetime';
```

## 🚀 Proceso de Lanzamiento

### Checklist Pre-Lanzamiento

```

## ✨ Novedades Recientes

### Banner de Descuento Clickeable
La pantalla Premium ahora incluye un banner de descuento con el texto "Solo para los primeros 100 usuarios" y un botón "¡Aprovecha ahora!" que permite al usuario navegar rápidamente a la sección de planes.

### Planes Simplificados
Se redujeron los planes de 3 a 2 opciones para simplificar la decisión del usuario:
- **Mensual**: Para usuarios que desean probar el servicio primero
- **Anual**: Marcado como "MÁS POPULAR" con borde turquesa destacado ] Productos creados en App Store Connect
- [ ] IDs de productos verificados
- [ ] Precios configurados para todos los países
- [ ] Compras probadas en sandbox/test
- [ ] Políticas de privacidad actualizadas
- [ ] Términos de servicio actualizados
- [ ] App enviada para revisión

### Testing Recomendado

1. **Compra Mensual**
   - Verificar que se active Premium
   - Verificar que se oculten anuncios
   - Probar restauración

2. **Compra Anual**
   - Verificar precio y descuento mostrado
   - Verificar activación
   - Probar en diferentes dispositivos

3. **Compra Vitalicia**
   - Verificar badge "MÁS POPULAR"
   - Verificar que sea permanente
   - Probar reinstalación

## 📊 Proyecciones de Ingresos

Basado en diferentes tasas de conversión:

### Escenario Conservador (2% conversión)
- 1,000 usuarios activos
- 20 usuarios Premium
- Ingreso mensual: ~$100-200 USD

### Escenario Moderado (5% conversión)
- 1,000 usuarios activos
- 50 usuarios Premium
- Ingreso mensual: ~$250-500 USD

### Escenario Optimista (10% conversión)
- 1,000 usuarios activos
- 100 usuarios Premium
- Ingreso mensual: ~$500-1,000 USD

## ⚠️ Notas Importantes

1. **Plataformas Soportadas**:
   - ✅ Android (Google Play)
   - ✅ iOS (App Store)
   - ❌ Web (no soporta in-app purchases)
   - ❌ Windows/macOS/Linux (no soportado)

2. **Comisiones de Tiendas**:
   - Google Play: 15% (primeros $1M USD/año), luego 30%
   - App Store: 15% (primeros $1M USD/año), luego 30%

3. **Política de Reembolsos**:
   - Los usuarios pueden solicitar reembolsos directamente a Google/Apple
   - No puedes procesar reembolsos desde la app

4. **Verificación del Servidor** (Opcional pero Recomendado):
   - Considera implementar verificación de compras del lado del servidor
   - Previene piratería y compras falsas
   - Requiere backend adicional

## 🛠️ Solución de Problemas

### Problema: "Las compras no están disponibles"

**Solución**:
1. Verifica que los IDs de productos coincidan exactamente
2. Asegúrate de que los productos estén activados en la consola
3. Verifica que la app esté firmada correctamente
4. Confirma que la cuenta de prueba esté configurada

### Problema: "No se muestran los precios"

**Solución**:
1. Espera 24-48 horas después de crear los productos
2. Verifica la conexión a internet del dispositivo
3. Asegúrate de que los productos estén publicados
4. Revisa los logs de la consola para errores

### Problema: "No se puede restaurar la compra"

**Solución**:
1. Verifica que uses la misma cuenta de Google/Apple
2. Confirma que la compra original se completó exitosamente
3. Revisa que el producto sea "no consumible"
4. Intenta cerrar y abrir la app de nuevo

## 📞 Soporte

Para problemas con las compras:
- **Google Play**: [Soporte para Desarrolladores](https://support.google.com/googleplay/android-developer)
- **App Store**: [Soporte de App Store Connect](https://developer.apple.com/support/app-store-connect/)
- **Flutter**: [Documentación de in_app_purchase](https://pub.dev/packages/in_app_purchase)

---

¡Tu app ahora está lista para generar ingresos! 🎉💰
