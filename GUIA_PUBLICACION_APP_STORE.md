# 🍎 Guía Completa: Publicar Zentavo en Apple App Store

## 📋 REQUISITOS PREVIOS

### 1. Hardware Necesario
- **Mac con macOS** (necesario obligatorio)
  - No se puede publicar en App Store desde Windows
  - Alternativa: Usar servicio en la nube como MacStadium o servicio CI/CD

### 2. Cuenta de Apple Developer
- **Costo:** $99 USD/año (renovación anual)
- **Registro:** https://developer.apple.com/programs/
- **Requiere:**
  - Apple ID
  - Método de pago válido
  - Verificación de identidad (puede tomar 1-2 días)

### 3. Software Necesario
- **Xcode** (última versión desde Mac App Store)
- **Flutter** instalado en Mac
- **CocoaPods** (`sudo gem install cocoapods`)

### 4. Información Necesaria
- ✅ Nombre de la app (único en App Store)
- ✅ URL de la política de privacidad
- ✅ Descripción de la app
- ✅ Screenshots (varios tamaños)
- ✅ Ícono de app (1024x1024 px)
- ✅ Palabras clave (máx. 100 caracteres)
- ✅ URL de soporte
- ✅ URL de marketing (opcional)

---

## 🚨 NOTA IMPORTANTE: LIMITACIÓN DE WINDOWS

**No puedes publicar en App Store desde Windows directamente.**

### Opciones:

#### Opción 1: Usar un Mac (Recomendado)
- Propio, prestado, o de un amigo
- Hackintosh (no recomendado, viola términos de Apple)

#### Opción 2: Servicios de Build en la Nube
- **Codemagic:** https://codemagic.io (gratis con límites)
- **Bitrise:** https://bitrise.io
- **App Center:** https://appcenter.ms

#### Opción 3: Contratar Desarrollador iOS
- Fiverr, Upwork, etc.
- Solo para compilar y subir a TestFlight

---

## 🖥️ PASO 1: CONFIGURAR PROYECTO EN MAC

### 1.1 Transferir Proyecto

```bash
# En Windows, comprimir proyecto
cd C:\Users\flore\control_gastos
# Excluir build, .dart_tool (están en .gitignore)

# En Mac, descomprimir y abrir
cd ~/Projects
unzip zentavo.zip
cd zentavo
```

### 1.2 Instalar Dependencias

```bash
# En Mac Terminal
flutter pub get
cd ios
pod install
cd ..
```

---

## 📱 PASO 2: CONFIGURAR IDENTIDAD Y FIRMA

### 2.1 Abrir Xcode

```bash
open ios/Runner.xcworkspace
```

### 2.2 Configurar Bundle Identifier

1. **Selecciona** el proyecto "Runner" en el navegador izquierdo
2. **Ve a** la pestaña "Signing & Capabilities"
3. **Bundle Identifier:** `com.zentavo.controlGastos`
   - Debe ser único global (revisa disponibilidad)
4. **Display Name:** Zentavo
5. **Team:** Selecciona tu equipo de Apple Developer
   - Si no aparece, inicia sesión: Xcode → Preferences → Accounts

### 2.3 Configurar Versión

En Xcode, archivo `ios/Runner/Info.plist`:

```xml
<key>CFBundleShortVersionString</key>
<string>1.3.0</string>
<key>CFBundleVersion</key>
<string>4</string>
```

O desde General tab en Xcode:
- **Version:** 1.3.0
- **Build:** 4

---

## 📝 PASO 3: CONFIGURAR APP EN APP STORE CONNECT

### 3.1 Acceder a App Store Connect

1. **URL:** https://appstoreconnect.apple.com
2. **Inicia sesión** con tu Apple ID de desarrollador
3. **Clic en:** "My Apps" (+)
4. **Clic en:** "New App"

### 3.2 Información de la App

- **Platforms:** iOS
- **Name:** Zentavo - Control de Gastos
  - Debe ser único en App Store
  - Máx. 30 caracteres
- **Primary Language:** Spanish (Spain) o tu idioma
- **Bundle ID:** com.zentavo.controlGastos
  - Debe coincidir con Xcode
- **SKU:** zentavo_2026 (identificador interno, cualquier string único)

**Clic en:** "Create"

---

## 📋 PASO 4: COMPLETAR INFORMACIÓN DE LA APP

### 4.1 App Information

#### Nombre
```
Zentavo - Control Financiero
```

#### Subtítulo (máx. 30 caracteres)
```
Gastos, Ahorros y Presupuestos
```

#### Categoría
- **Primary:** Finance
- **Secondary:** Productivity (opcional)

#### Privacidad
- **Privacy Policy URL:** https://zentavo.com/privacy
- **Términos de servicio URL:** (opcional)

### 4.2 Pricing and Availability

- **Price:** Free
- **Availability:** All countries or select specific
- **Pre-orders:** No (por ahora)

### 4.3 App Privacy

**Cuestionario obligatorio:**

1. **¿Recopilas datos de usuarios?**
   - Si tu app NO envía datos fuera del dispositivo: **No**
   - Si usas analytics/ads: **Sí** (especificar qué)

2. **Tipos de datos:**
   - Financial Information: Si guardas transacciones
   - User ID: Solo si usas autenticación
   - Device ID: Solo si usas analytics

3. **Propósito de recopilación:**
   - App Functionality
   - Analytics (si aplica)

### 4.4 App Review Information

- **Contact Information:**
  - First Name: Tu nombre
  - Last Name: Tu apellido
  - Phone: +57 XXX XXX XXXX
  - Email: soporte@zentavo.com

- **Notes for reviewer:**
```
Zentavo es una app de control de gastos personales.

Características principales:
- Registro de ingresos/egresos
- Presupuestos mensuales
- Gráficos de análisis
- Exportación de datos
- Soporte para múltiples monedas

Credenciales de prueba: No requiere cuenta/login.
La app funciona offline con datos almacenados localmente.

Para probar todas las funciones:
1. Agregar transacciones con el botón "+"
2. Ver gráficos en la pestaña de reportes
3. Configurar presupuesto en ajustes
4. Exportar datos desde el menú

Gracias por revisar Zentavo.
```

- **Attachment (opcional):** Screenshots adicionales o video demo

---

## 🎨 PASO 5: RECURSOS GRÁFICOS

### 5.1 App Icon (Obligatorio)
- **Tamaño:** 1024x1024 px
- **Formato:** PNG sin transparencia
- **Calidad:** Máxima resolución
- **Nota:** Apple añade bordes redondeados automáticamente

### 5.2 Screenshots (Obligatorios)

**iPhone 6.7" Display** (iPhone 14 Pro Max, 15 Pro Max):
- Resolución: 1290x2796 px
- Mínimo: 3 screenshots
- Máximo: 10 screenshots

**iPhone 6.5" Display** (iPhone 11 Pro Max, XS Max):
- Resolución: 1242x2688 px
- Mínimo: 3 screenshots

**Nota:** Puedes usar el mismo diseño y escalar

**Sugerencias de Screenshots:**
1. Pantalla principal con transacciones
2. Gráficos y análisis
3. Presupuestos y alertas
4. Exportación de reportes
5. Configuración de monedas
6. Tema oscuro/claro

### 5.3 Crear Screenshots en Mac

```bash
# Abrir simulador de Xcode
open -a Simulator

# Ejecutar app
flutter run

# Capturar screenshot
Cmd + S  (en Simulator)
# O desde menú: Device → Screenshot

# Las capturas se guardan en Desktop
```

### 5.4 App Preview (Opcional)
- Videos de 15-30 segundos
- Mismos tamaños que screenshots
- Herramienta: ScreenFlow, Camtasia, o QuickTime

---

## 🏗️ PASO 6: COMPILAR Y SUBIR A APP STORE

### 6.1 Limpiar y Compilar

```bash
# En Mac Terminal
cd ~/Projects/zentavo

# Limpiar
flutter clean

# Compilar para iOS
flutter build ios --release

# O compilar IPA directamente
flutter build ipa --release
```

### 6.2 Archivar en Xcode (Opción 1)

```bash
# Abrir Xcode
open ios/Runner.xcworkspace
```

1. **Selecciona:** Generic iOS Device (no simulator)
2. **Menú:** Product → Archive
3. **Espera** a que compile (5-15 minutos)
4. **Ventana de Organizer** se abrirá automáticamente

### 6.3 Distribuir a App Store

En Xcode Organizer:

1. **Selecciona** el archive recién creado
2. **Clic en:** "Distribute App"
3. **Selecciona:** "App Store Connect"
4. **Selecciona:** "Upload"
5. **Signing:** Automatically manage signing
6. **Review:** Revisa información
7. **Upload:** Espera (10-30 minutos)

### 6.4 Verificar en App Store Connect

1. **Ve a:** App Store Connect → My Apps → Zentavo
2. **Ve a:** TestFlight tab
3. **Verifica** que aparece el build (puede tardar 5-30 min)
4. **Estado:** "Processing" → "Ready to Submit"

---

## 🧪 PASO 7: TESTFLIGHT (OPCIONAL PERO RECOMENDADO)

### 7.1 Pruebas Internas

1. **Ve a:** TestFlight → Internal Testing
2. **Clic en:** Default Internal Group
3. **Agrega testers:** Emails de tu equipo (máx. 100)
4. **Los testers reciben:** Email con link de TestFlight
5. **Descargan:** TestFlight de App Store
6. **Prueban** tu app antes de publicar

### 7.2 Pruebas Externas (Opcional)

- Hasta 10,000 testers
- Requiere revisión de Apple (1-2 días)
- Útil para beta testing público

---

## 📤 PASO 8: ENVIAR A REVISIÓN

### 8.1 Seleccionar Build

1. **Ve a:** App Store → Version Information
2. **Clic en:** "Select a build before you submit"
3. **Selecciona** el build que subiste
4. **Clic en:** "Done"

### 8.2 Descripción de la App

#### App Description (Máx. 4000 caracteres)

```
🌟 Zentavo - Tu Control Financiero Personal

Toma el control total de tus finanzas de forma fácil, rápida y segura. Zentavo es la aplicación más completa para gestionar gastos, ingresos, ahorros y presupuestos.

✨ CARACTERÍSTICAS PRINCIPALES

💰 GESTIÓN FINANCIERA
• Registra ingresos y egresos al instante
• Categorías predefinidas e ilimitadas
• 16 monedas internacionales soportadas
• Conversión automática de divisas
• Presupuesto mensual con alertas
• Sin límite de transacciones

📊 ANÁLISIS INTELIGENTE
• Gráficos detallados por categoría
• Reportes mensuales y anuales
• Exportación: PDF, Excel, CSV, JSON
• Análisis predictivo con IA (Premium)
• Identificación de patrones

💳 GASTOS RECURRENTES
• Programa pagos automáticos mensuales
• Recordatorios de vencimientos
• Control de suscripciones
• Historial completo

🎯 AHORRO INTELIGENTE
• Meta de ahorro personalizada
• Seguimiento automático
• Ahorros en múltiples monedas
• Compra/venta de divisas integrada
• Proyecciones futuras

🔐 SEGURIDAD MÁXIMA
• Datos en tu dispositivo (privacidad total)
• Face ID / Touch ID
• Respaldo y restauración
• Sin registro ni login
• Compatible con iCloud (Premium)

🌍 MULTIIDIOMA
Español, English, Português, Italiano, 中文, 日本語

🎨 PERSONALIZACIÓN
• Modo claro y oscuro
• Temas de color
• Categorías personalizadas (Premium)

🆓 VERSIÓN PREMIUM
• Categorías ilimitadas
• Análisis avanzado con IA
• Respaldo automático iCloud
• Reportes sin límites
• Sin marca de agua
• Soporte prioritario

📱 MÁS FUNCIONES
• Eventos compartidos (gastos grupales)
• Códigos QR para compartir
• Tutorial interactivo
• FAQ y soporte integrado
• Interfaz moderna intuitiva

💡 IDEAL PARA
• Control de finanzas personales
• Ahorro familiar
• Estudiantes con presupuesto
• Freelancers y emprendedores
• Viajeros con múltiples monedas

🏆 POR QUÉ ZENTAVO
• Sin suscripciones ocultas
• Actualizaciones frecuentes
• Soporte en tu idioma
• Sin anuncios molestos
• Privacidad garantizada

📧 Contacto: soporte@zentavo.com

¡Descarga Zentavo y toma control de tu futuro financiero! 💪
```

#### Keywords (Máx. 100 caracteres total, separados por comas)

```
finanzas,gastos,presupuesto,ahorro,dinero,economía,control,ingresos,egresos,wallet
```

#### What's New (Versión 1.3.0)

```
🎉 Nueva Actualización 1.3.0

NOVEDADES:
• Servicio técnico integrado con preguntas frecuentes
• Compartir app mediante código QR
• Desglose detallado por monedas
• Mejora en conversión de divisas
• Nueva interfaz de soporte

MEJORAS:
• Optimización de rendimiento
• Corrección de errores menores
• Mejor experiencia de usuario

¡Gracias por usar Zentavo!
```

### 8.3 Rating

- **Content Rating:** 4+ (Todos)
- **Made for Kids:** No

### 8.4 Guardar y Enviar

1. **Revisa** toda la información
2. **Clic en:** "Save"
3. **Clic en:** "Submit for Review"
4. **Confirma** que todo está correcto

---

## ⏱️ PASO 9: ESPERAR REVISIÓN

### Tiempos de Revisión
- **Primera vez:** 2-7 días (promedio 48-72 horas)
- **Actualizaciones:** 1-3 días
- **Apelación:** Si rechazan, 1-2 días adicionales

### Estados de Revisión
1. **Waiting for Review:** En cola
2. **In Review:** Apple está revisando
3. **Pending Developer Release:** ¡Aprobada! Lista para publicar
4. **Ready for Sale:** Publicada en App Store

### Notificaciones
- Recibirás emails en cada cambio de estado
- Revisa App Store Connect regularmente

---

## ✅ APROBADA - PUBLICAR

Una vez aprobada:

1. **Manual:** Publica cuando quieras
2. **Automática:** Se publica inmediatamente

Para controlar:
- App Store Connect → Version → Version Release
- Selecciona: "Manually release this version"

---

## ❌ RECHAZOS COMUNES Y SOLUCIONES

### Rechazo: App Incompleta
**Causa:** Funciones que no funcionan, botones sin acción
**Solución:** Prueba exhaustivamente, elimina secciones incompletas

### Rechazo: Información Insuficiente
**Causa:** Descripción poco clara, screenshots confusos
**Solución:** Mejora descripción, agrega screenshots claros

### Rechazo: Violación de Privacidad
**Causa:** Permisos sin justificación, falta política privacidad
**Solución:** Justifica cada permiso en Info.plist, agrega política

### Rechazo: Diseño No Nativo
**Causa:** Interfaz muy básica o no iOS-like
**Solución:** Usa componentes nativos de Flutter (Cupertino)

### Rechazo: Contenido Mínimo
**Causa:** App muy simple con poco valor
**Solución:** Agrega más funcionalidades antes de publicar

### Rechazo: Permisos Innecesarios
**Causa:** Pide cámara/ubicación sin usar
**Solución:** Elimina permisos no usados del Info.plist

---

## 🔄 ACTUALIZACIONES FUTURAS

### Proceso de Actualización

1. **Modificar código** en tu proyecto
2. **Incrementar versión:**
   - Build Number: +1 (siempre)
   - Version: Según cambios (1.3.1, 1.4.0, 2.0.0)
3. **Compilar nuevo build**
4. **Subir a App Store Connect**
5. **Actualizar "What's New"**
6. **Submit for Review**

### Actualizaciones Automáticas
- Los usuarios reciben automático si tienen activado
- O manualmente desde App Store

---

## 💰 PAGOS (SI IMPLEMENTAS IN-APP PURCHASES)

### Para Premium Zentavo

1. **App Store Connect** → Features → In-App Purchases
2. **Create:** Auto-Renewable Subscription
3. **Product ID:** `com.zentavo.premium_monthly`
4. **Price:** $4.99 USD/mes (o tu precio)
5. **Localize** descripciones en idiomas
6. **Submit** para revisión (separado de la app)

### En Flutter

```dart
// Usar in_app_purchase package (ya está en dependencies)
import 'package:in_app_purchase/in_app_purchase.dart';

// Implementar lógica de compra
// Ver documentación: pub.dev/packages/in_app_purchase
```

---

## 📊 ANALYTICS Y SEGUIMIENTO

### App Store Connect Analytics

- Descarga diaria/semanal/mensual
- Países de descarga
- Retención de usuarios
- Crashes y errores

### Errores y Crashes

1. **Ve a:** App Analytics → Crashes
2. **Revisa** logs de errores
3. **Corrige** bugs críticos
4. **Sube** actualizaciones

---

## 💡 TIPS PARA ÉXITO EN APP STORE

### Optimización ASO (App Store Optimization)

1. **Keywords bien elegidas** (investiga competencia)
2. **Ícono atractivo y profesional**
3. **Screenshots con texto descriptivo**
4. **Video preview** (muy recomendado)
5. **Descripción clara y directa**
6. **Actualizaciones regulares** (muestra que está activo)

### Promoción

- Responde todas las reseñas
- Solicita calificaciones (in-app)
- Comparte en redes sociales
- Crea sitio web
- Blog con tips financieros

---

## ⚠️ COSTOS TOTALES

- **Apple Developer Program:** $99 USD/año
- **Mac:** Si no tienes (~$1000-3000 USD)
  - O servicio cloud: ~$30-50/mes
- **Herramientas opcionales:**
  - Diseño gráfico: $0-200 USD
  - Marketing: Variable

---

## 📞 SOPORTE APPLE

### App Store Connect Help
- https://developer.apple.com/support/
- Formulario de contacto en App Store Connect
- Teléfono (si eres miembro pagado)

### Recursos
- **WWDC Videos:** https://developer.apple.com/videos/
- **Human Interface Guidelines:** https://developer.apple.com/design/
- **App Store Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/

---

## ✅ CHECKLIST FINAL iOS

Antes de enviar a revisión:

- [ ] Build compilado sin errores
- [ ] Versión incrementada (Build + Version)
- [ ] Pruebas en simulador iOS
- [ ] Pruebas en dispositivo físico (recomendado)
- [ ] Descripción completa en App Store Connect
- [ ] Keywords optimizadas
- [ ] Screenshots de calidad (mínimo 3)
- [ ] Ícono 1024x1024 px
- [ ] Política de privacidad URL válida
- [ ] Información de contacto actualizada
- [ ] Notas para revisor completadas
- [ ] Categoría seleccionada
- [ ] Precio configurado
- [ ] Privacy questionnaire completado
- [ ] Todos los links funcionan
- [ ] App funciona sin crashes
- [ ] TestFlight testing realizado (opcional)

---

## 🎯 ALTERNATIVA SIN MAC

Si no tienes Mac, usa **Codemagic**:

1. **Registra** en https://codemagic.io
2. **Conecta** tu repo de GitHub
3. **Configura** workflow para iOS
4. **Agrega** credenciales de Apple Developer
5. **Build automático** en la nube
6. **Descarga** IPA o sube directo a App Store

Codemagic maneja todo el proceso de firma y distribución.

---

🎉 ¡Listo! Tu app estará en App Store en 2-7 días tras aprobación.
