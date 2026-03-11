# 📱 Instrucciones para Publicación en App Store (iOS)

**Fecha:** 11 de marzo de 2026  
**App:** Zentavo - Control Financiero  
**Versión para revisión:** 1.2.0 (build 3)

---

## ⚠️ REQUISITO CRÍTICO: Necesitas una Mac

**❌ No puedes compilar iOS desde Windows**

Para publicar en App Store **obligatoriamente necesitas**:
- 💻 Una Mac (MacBook, iMac, Mac Mini)
- 🍎 macOS 12.0 o superior
- 📱 Xcode 14.0 o superior (gratis desde App Store)
- 👤 Apple Developer Account ($99 USD/año)

### **Alternativas si no tienes Mac:**

**Opción A: Alquilar un Mac en la nube** (Recomendado)
- **MacStadium**: $59-79/mes (https://www.macstadium.com)
- **MacinCloud**: $20-50/mes (https://macincloud.com)
- Te dan acceso remoto a una Mac real con Xcode
- Puedes compilar, firmar y enviar a App Store

**Opción B: Codemagic CI/CD** (Más fácil, automatizado)
- Servicio de compilación automática en la nube
- 500 minutos gratis/mes (suficiente para varias compilaciones)
- Conectas tu repo de GitHub
- Codemagic compila iOS automáticamente
- Tutorial: https://docs.codemagic.io/flutter/

**Opción C: Usar Mac de amigo/familiar**
- Solo necesitas Mac para compilar (15-20 minutos)
- Puedes subir a App Store desde ahí
- No necesitas tenerlo permanentemente

**Opción D: Esperar y publicar solo Android**
- Zentavo puede estar en Play Store primero
- Más adelante consigues Mac para iOS
- Muchas apps empiezan solo en una plataforma

---

## 🎯 Proceso Completo (Cuando tengas Mac)

### **Paso 1: Configurar Apple Developer Account**

1. **Registrarse en Apple Developer Program:**
   - Ve a: https://developer.apple.com/programs/
   - Click "Enroll"
   - Costo: $99 USD/año (renovación automática)
   - Requiere: Apple ID + método de pago

2. **Crear App ID en Developer Portal:**
   - Ve a: https://developer.apple.com/account
   - Certificates, IDs & Profiles → Identifiers → +
   - Bundle ID: `com.zentavo.controlgastos` (cambiar desde actual)
   - Capabilities: In-App Purchase, Push Notifications

3. **Crear App en App Store Connect:**
   - Ve a: https://appstoreconnect.apple.com
   - My Apps → + → New App
   - Plataform: iOS
   - Name: Zentavo - Control Financiero
   - Bundle ID: Selecciona el creado arriba
   - SKU: zentavo-ios-2026 (identificador único interno)

---

### **Paso 2: Preparar Assets para App Store**

#### **Iconos Requeridos (1024×1024px):**
```
Icon-App-1024x1024.png → Para App Store (PNG, sin transparencia)
```

Puedes usar el mismo logo de Play Store (`play_store_assets/zentavo_icon_512.png`) escalado a 1024×1024.

#### **Screenshots Obligatorios:**

**iPhone 6.7" (iPhone 14 Pro Max):**
- Mínimo: 3 screenshots
- Tamaño: 1290 × 2796 px
- Formato: PNG o JPG

**iPad Pro 12.9" (3ra gen):**
- Mínimo: 3 screenshots
- Tamaño: 2048 × 2732 px
- Formato: PNG o JPG

**Nota:** Puedes usar las mismas pantallas de Play Store, solo necesitas cambiar el tamaño.

---

### **Paso 3: Actualizar Configuración iOS**

**Archivo: `ios/Runner.xcodeproj/project.pbxproj`**

Cambiar Bundle Identifier de `com.example.controlGastos` a `com.zentavo.controlgastos`:

1. Abrir Xcode
2. Runner → Target "Runner" → General
3. Bundle Identifier: `com.zentavo.controlgastos`

**Archivo: `ios/Runner/Info.plist`**

Verificar que tenga:
```xml
<key>CFBundleDisplayName</key>
<string>Zentavo</string>

<key>NSFaceIDUsageDescription</key>
<string>Usamos Face ID o Touch ID para proteger el acceso a tus datos financieros.</string>
```

---

### **Paso 4: Compilar Archive (.ipa)**

**Desde la Mac con Xcode:**

1. **Conectar cuenta de Apple Developer en Xcode:**
   ```
   Xcode → Settings → Accounts → + → Add Apple ID
   ```

2. **Configurar Signing:**
   ```
   Runner target → Signing & Capabilities
   Team: Selecciona tu equipo
   Marca "Automatically manage signing"
   ```

3. **Compilar en terminal:**
   ```bash
   cd control_gastos
   flutter clean
   flutter build ios --release
   ```

4. **Crear Archive en Xcode:**
   ```
   Product → Destination → Any iOS Device (arm64)
   Product → Archive
   Espera 5-10 minutos
   ```

5. **Subir a App Store Connect:**
   ```
   Window → Organizer → Archives
   Selecciona el archive → Distribute App
   App Store Connect → Upload
   Espera validación (5-15 minutos)
   ```

**Alternativa desde terminal (también en Mac):**
```bash
flutter build ipa --release
open build/ios/archive/Runner.xcarchive
```

---

### **Paso 5: Completar Metadata en App Store Connect**

1. **Ve a App Store Connect:**
   https://appstoreconnect.apple.com

2. **My Apps → Zentavo → Prepare for Submission**

3. **Información de la App:**

**Nombre:**
```
Zentavo - Control Financiero
```

**Subtitle (30 caracteres):**
```
Gastos, Ahorros y Presupuestos
```

**Descripción (4000 caracteres máx):**
```
Zentavo es tu compañero financiero inteligente diseñado para ayudarte a tomar el control total de tus finanzas personales de manera simple, rápida y efectiva.

🎯 ¿QUÉ PUEDES HACER CON ZENTAVO?

💰 CONTROL DE GASTOS E INGRESOS
Registra todas tus transacciones en segundos. Categoriza automáticamente tus gastos e ingresos para tener una visión clara de tu flujo de dinero. Visualiza gráficos intuitivos que te muestran exactamente dónde va tu dinero cada mes.

📊 PRESUPUESTOS INTELIGENTES
Establece presupuestos mensuales personalizados por categoría. Recibe alertas automáticas cuando te acerques al límite. Controla tus hábitos de gasto con notificaciones que te ayudan a mantenerte en el camino correcto.

💵 MULTI-MONEDA (Premium)
¿Viajas frecuentemente o manejas diferentes divisas? Zentavo soporta 16 monedas internacionales con conversión automática. Perfecto para freelancers, viajeros y cualquiera que maneje finanzas en múltiples monedas.

🎨 CATEGORÍAS PERSONALIZABLES (Premium)
Crea categorías completamente adaptadas a tu estilo de vida. Personaliza emojis, nombres y colores. Organiza tus finanzas exactamente como tú las entiendes.

🏦 CUENTAS DE AHORRO Y METAS
Define objetivos financieros realistas. Crea múltiples cuentas de ahorro para diferentes propósitos (vacaciones, emergencias, compras grandes). Mira tu progreso en tiempo real hacia cada meta.

🔄 GASTOS FIJOS RECURRENTES
Programa gastos que se repiten mensualmente (alquiler, suscripciones, servicios). La app los registra automáticamente. Nunca más olvides un pago recurrente.

📈 REPORTES DETALLADOS Y EXPORTACIÓN (Premium)
Genera reportes completos en Excel con todos tus datos. Análisis mensual, trimestral o anual. Perfecto para declaraciones de impuestos o análisis financiero profundo.

🌍 6 IDIOMAS DISPONIBLES
- Español
- English
- Português
- Italiano
- 中文 (Chino)
- 日本語 (Japonés)

🎨 DISEÑO MODERNO Y PERSONALIZABLE
- Tema claro y oscuro
- Interfaz intuitiva y fluida
- Gráficos visuales atractivos
- Navegación rápida

🔒 SEGURIDAD Y PRIVACIDAD
- Protección biométrica (Face ID / Touch ID)
- Todos los datos se guardan localmente en tu dispositivo
- Sin registro ni inicio de sesión
- Tus datos financieros son 100% privados

✨ FUNCIONES DESTACADAS

✅ Sin registro ni login necesario
✅ Interfaz limpia y moderna
✅ Gráficos interactivos con análisis automático
✅ Eventos compartidos para gastos grupales
✅ Soporte para múltiples monedas
✅ Respaldo y exportación de datos
✅ Sin publicidad intrusiva (versión Premium)
✅ Actualizaciones regulares con nuevas funciones

💎 ZENTAVO PREMIUM

Desbloquea todo el potencial:
• Gestión multi-moneda ilimitada
• Categorías personalizadas sin límites
• Exportación completa a Excel
• Recomendaciones financieras automáticas
• Sin anuncios publicitarios
• Soporte prioritario

Compra única de $4.99 USD. Sin suscripciones mensuales.

📱 IDEAL PARA:

👤 Personas que quieren controlar gastos personales
💑 Parejas que comparten finanzas
🎓 Estudiantes con presupuesto ajustado
💼 Freelancers con ingresos variables
🌎 Viajeros que manejan múltiples monedas
👨‍👩‍👧‍👦 Familias que planifican ahorros

🚀 EMPIEZA HOY A TOMAR CONTROL DE TUS FINANZAS

Descarga Zentavo ahora mismo y comienza a transformar tu relación con el dinero. Simple, poderoso y completamente privado.

¿Tienes preguntas o sugerencias? Contáctanos en:
📧 florencia.ballon.lp@gmail.com
🌐 https://florenciaballonlp-create.github.io/Zentavo/
```

**Keywords (100 caracteres):**
```
gastos,finanzas,presupuesto,ahorro,dinero,cuenta,ingresos,multi moneda,control,economía
```

**Promotional Text (170 caracteres):**
```
¡Nueva función de multi-moneda! Gestiona tus finanzas en 16 divisas diferentes. Ideal para viajeros y freelancers. Versión Premium a $4.99 USD.
```

**Support URL:**
```
https://florenciaballonlp-create.github.io/Zentavo/
```

**Marketing URL (opcional):**
```
https://github.com/florenciaballonlp-create/Zentavo
```

**Privacy Policy URL:**
```
https://florenciaballonlp-create.github.io/Zentavo/
```

---

### **Paso 6: Configurar Pricing & Availability**

**Precio:**
- Marca: **Free** (Gratis)

**In-App Purchases:**
- Configura "Zentavo Premium" como IAP (In-App Purchase)
- Precio: $4.99 USD
- Tipo: Non-Consumable (compra única)

**Availability:**
- Selecciona: **All Countries** (todos los países)

---

### **Paso 7: Agregar App Review Information**

**Instrucciones para Revisión (COPIA ESTO):**

```
ACCESO A ZENTAVO:
La aplicación no requiere login ni registro. Se abre directamente.

AUTENTICACIÓN BIOMÉTRICA:
Si aparece solicitud de Face ID/Touch ID, presionar "Continuar sin verificar" 
para acceder sin autenticación.

ACCESO A FUNCIONES PREMIUM:
Esta es una versión de revisión con acceso Premium para evaluación completa.

Para activar Premium:
1. Menú ⋮ (esquina superior derecha)
2. Seleccionar "⭐ Premium"
3. Desplazar hasta el final
4. Presionar botón "Activar para pruebas"
5. Confirmar en diálogo

FUNCIONES PREMIUM A EVALUAR:
• Multi-moneda: Menú → "Monedas Múltiples"
• Categorías personalizadas: Menú → "Mis Categorías"
• Recomendaciones: Menú → "Recomendaciones Financieras"
• Exportar datos: Disponible en "Gráficos e Informes"
• Sin anuncios: Los banners desaparecen al activar Premium

DATOS DE PRUEBA:
Menú → "📸 Cargar Datos Demo" para ver la app con datos realistas 
(20 transacciones, presupuestos, ahorros).

NOTA: El botón "Activar para pruebas" solo existe en esta versión de revisión.
La versión pública requerirá compra real mediante In-App Purchase.
```

**Demo Account Required:**
- Marca: **NO**

**Contact Information:**
```
First Name: Florencia
Last Name: Ballon
Phone: +54 [tu teléfono]
Email: florencia.ballon.lp@gmail.com
```

---

### **Paso 8: Age Rating & Content**

**Age Rating:**
- Selecciona: **4+ (Everyone)**
- No contiene violencia, temas para adultos, apuestas

**Content Rights:**
- Marca: "I have all necessary rights"

---

### **Paso 9: Enviar a Revisión**

1. En App Store Connect, selecciona tu app
2. Version → 1.2.0 → Prepare for Submission
3. Sube screenshots (3-5 por cada tamaño de dispositivo)
4. Completa toda la metadata
5. Agrega el build compilado (aparece después de subirlo desde Xcode)
6. Click **"Submit for Review"**

**Tiempo de revisión:** 1-3 días (más rápido que Android)

---

## 📋 Checklist Completo

### **Pre-requisitos:**
- [ ] Mac con Xcode instalado (o Mac en la nube)
- [ ] Apple Developer Account ($99/año)
- [ ] Bundle ID configurado
- [ ] Certificados de firma configurados

### **Assets:**
- [ ] Icono 1024×1024px
- [ ] 3-5 screenshots iPhone 6.7" (1290×2796)
- [ ] 3-5 screenshots iPad 12.9" (2048×2732)

### **Configuración:**
- [ ] Bundle ID cambiado de `com.example` a `com.zentavo`
- [ ] Info.plist actualizado con descripciones
- [ ] Versión 1.2.0 (build 3) verificada
- [ ] Signing configurado en Xcode

### **Compilación:**
- [ ] Archive creado exitosamente
- [ ] IPA subido a App Store Connect
- [ ] Build aparece en "Activity" tab

### **Metadata en App Store Connect:**
- [ ] Nombre y subtítulo agregados
- [ ] Descripción completa (hasta 4000 chars)
- [ ] Keywords agregados (100 chars)
- [ ] Screenshots subidos
- [ ] Support URL y Privacy Policy URL agregadas
- [ ] Instrucciones de revisión copiadas
- [ ] Precio: Gratis + IAP configurado ($4.99)

### **Envío:**
- [ ] Build seleccionado
- [ ] Toda metadata completada
- [ ] Clicked "Submit for Review"

---

## 🎯 Comparación: Play Store vs App Store

| Aspecto | Play Store (Android) | App Store (iOS) |
|---------|---------------------|-----------------|
| **Costo inicial** | $25 USD (único) | $99 USD/año |
| **Compilación** | Desde Windows ✅ | Mac requerida ❌ |
| **Revisión** | 3-7 días | 1-3 días |
| **Rechazo típico** | Menos estricto | Más estricto |
| **Revenue share** | 15% (primeros $1M) | 15% (primeros $1M) |
| **Actualizaciones** | Más rápidas | Más lentas |

---

## 🚀 Estrategia Recomendada

### **Fase 1: Solo Android (AHORA)**
- ✅ Ya casi lista en Play Store
- ✅ No requiere Mac
- ✅ Más económico ($25 vs $99)
- ✅ Puedes empezar a recibir feedback

### **Fase 2: iOS después (1-2 meses)**
- Una vez tengas usuarios en Android
- Validada la app con reviews
- Puedes invertir $99 en Apple Developer
- Alquilas Mac en la nube por 1 mes ($50-79)
- Compilas y subes a App Store

---

## 💡 Consejos para App Store Review

**Cosas que Apple RECHAZA frecuentemente:**
- Apps que no funcionan completamente
- Funciones no accesibles durante revisión
- Crasheos o bugs evidentes
- Descripciones engañosas
- Solicitar reviews dentro de la app
- Enlaces rotos

**Cosas que Apple APRUEBA:**
- Apps con versión de prueba para revisión ✅
- Instrucciones claras de acceso ✅
- Todas las funciones accesibles ✅
- Privacy policy clara ✅
- IAP implementado correctamente ✅

---

## 📞 Solución de Problemas

**P: No tengo Mac, ¿puedo usar un Hackintosh?**
R: Técnicamente sí, pero Apple no lo permite oficialmente. Mejor usar Mac en la nube o pedir prestado uno.

**P: ¿Puedo compilar iOS en GitHub Actions gratis?**
R: Sí, GitHub Actions tiene runners macOS gratuitos. Pero necesitas configurar CI/CD complejo.

**P: ¿Cuánto cuesta mantener app en App Store?**
R: $99 USD/año obligatorio. Si no pagas, tu app desaparece.

**P: ¿Puedo publicar solo en Play Store?**
R: ¡Sí! Muchas apps empiezan solo en Android. iOS puede esperar.

---

## ✅ Resumen

**Para publicar en App Store necesitas:**
1. 💻 **Mac** (o alquiler Mac en la nube)
2. 💳 **$99 USD/año** (Apple Developer)
3. ⏱️ **1-2 días** (compilación + metadata)
4. 📱 **Screenshots de iOS** (puedes reusar de Android)

**Recomendación:**
Termina primero Play Store (casi lista), y cuando tengas acceso a Mac, haces iOS después.

---

**¿Tienes Mac o necesitas guía para alquilar uno en la nube?**
