# 🔓 Modo Desarrollador - Acceso Premium Ilimitado

## ¿Qué es el Modo Desarrollador?

El **Modo Desarrollador** te permite tener acceso completo a todas las funciones Premium de Zentavo sin necesidad de realizar ninguna compra. Es perfecto para:
- ✅ Desarrollo y testing
- ✅ Tu uso personal
- ✅ Demostrar todas las funcionalidades sin restricciones

## 🚀 Cómo Activar/Desactivar

### Para TU versión personal (con Premium gratis):

1. Abre el archivo `lib/main.dart`
2. Busca la línea 36 (aproximadamente):
   ```dart
   const bool kDeveloperMode = true;  // ✅ Premium ACTIVADO
   ```
3. Mantén `true` para tener acceso Premium ilimitado
4. Compila: `flutter build windows --release`

### Para la versión pública (requiere compra):

1. Abre el archivo `lib/main.dart`
2. Cambia a:
   ```dart
   const bool kDeveloperMode = false;  // ❌ Premium requiere compra
   ```
3. Compila: `flutter build windows --release`

## 📋 Funciones Premium Desbloqueadas

Con `kDeveloperMode = true`, tienes acceso a:

### 💰 Gestión Financiera Avanzada
- ✨ **Eventos Compartidos Ilimitados** - Crea todos los eventos que necesites
- 💳 **Solicitudes de Pago** - Solicita y rastrea pagos con un toque
- 📱 **Códigos QR de Pago** - Genera QR codes para recibir pagos
- 🔗 **Deep Links** - Integración con Mercado Pago, PayPal, Venmo, Cash App, Zelle

### 🎨 Personalización
- 📂 **Categorías Personalizadas Ilimitadas** - Crea tus propias categorías
- 💱 **Múltiples Monedas** - 16+ monedas con conversión automática

### 📊 Análisis y Reportes
- 🤖 **Análisis con IA** - Predicciones y recomendaciones personalizadas
- 📈 **Gráficos Avanzados** - Visualización detallada de tus finanzas
- 📄 **Exportación Anual** - Reportes PDF/Excel de todo el año

### 🌟 Experiencia Premium
- 🚫 **Sin Publicidad** - Interfaz completamente limpia
- ☁️ **Backup en la Nube** - Sincroniza datos en todos tus dispositivos
- 🎯 **Soporte Prioritario** - Respuesta en menos de 24 horas

## ⚠️ Importante

- **NO subas el código con `kDeveloperMode = true` a la tienda de aplicaciones**
- **NO compartas builds de desarrollador con usuarios finales**
- Siempre verifica que esté en `false` antes de publicar una versión pública

## 🔄 Versiones Rápidas

### Compilar Versión Desarrollador
```bash
# Asegúrate que kDeveloperMode = true
flutter build windows --release
flutter build apk --release
```

### Compilar Versión Pública
```bash
# Asegúrate que kDeveloperMode = false
flutter build windows --release
flutter build apk --release
flutter build appbundle --release
```

## 🛠️ Troubleshooting

### ¿No se activa Premium?
1. Verifica que `kDeveloperMode = true`
2. Limpia el build: `flutter clean`
3. Recompila: `flutter build windows --release`

### ¿Quiero volver a la versión normal?
1. Cambia `kDeveloperMode = false`
2. Recompila la app
3. Opcional: Borra datos de la app para limpiar el estado Premium guardado

## 📝 Notas Técnicas

El modo desarrollador funciona de la siguiente manera:

1. Al iniciar la app, se llama a `_checkPremiumStatus()`
2. Si `kDeveloperMode == true`:
   - Activa automáticamente `_isPremium = true`
   - Guarda el estado en SharedPreferences
   - Desbloquea todas las funciones Premium
3. Si `kDeveloperMode == false`:
   - Verifica la compra real del usuario
   - Requiere compra para activar Premium

---

**Versión**: 1.2.0  
**Última actualización**: Febrero 2026  
**Desarrollado con** ❤️ **para facilitar tu testing y uso personal**
