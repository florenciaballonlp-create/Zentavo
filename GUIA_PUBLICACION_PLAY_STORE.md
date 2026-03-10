# 📱 Guía Completa: Publicar Zentavo en Google Play Store

## 📋 REQUISITOS PREVIOS

### 1. Cuenta de Google Play Console
- Costo: $25 USD (pago único)
- Registro: https://play.google.com/console/signup
- Verifica tu identidad y acepta los términos

### 2. Información Necesaria
- ✅ Correo de contacto
- ✅ Política de privacidad (URL pública)
- ✅ Descripción de la app (varios idiomas recomendado)
- ✅ Screenshots (mínimo 2, máximo 8)
- ✅ Ícono de alta resolución (512x512 px)
- ✅ Gráfico destacado (1024x500 px)

---

## 🔐 PASO 1: CREAR KEYSTORE (Firma de la App)

### Opción A: Usando Línea de Comandos

Ejecuta en PowerShell:

```powershell
# Navega a la carpeta de tu proyecto
cd C:\Users\flore\control_gastos\android

# Crea el keystore (archivo de firma)
keytool -genkey -v -keystore zentavo-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias zentavo-key
```

**Te pedirá:**
1. **Contraseña del keystore**: Elige una segura (ej: ZentavoKey2026!)
2. **Nombre y apellido**: Zentavo Team
3. **Unidad organizativa**: Development
4. **Organización**: Zentavo
5. **Ciudad**: Tu ciudad
6. **Estado/Provincia**: Tu estado
7. **Código de país**: CO (o tu país)
8. **Contraseña del alias**: Misma del keystore o diferente

**⚠️ IMPORTANTE:** 
- Guarda las contraseñas en un lugar seguro
- Haz backup del archivo .jks
- Si pierdes esto, NO podrás actualizar tu app nunca más

---

## 📝 PASO 2: CONFIGURAR key.properties

Crea el archivo `android/key.properties`:

```properties
storePassword=TU_CONTRASEÑA_KEYSTORE
keyPassword=TU_CONTRASEÑA_ALIAS
keyAlias=zentavo-key
storeFile=zentavo-release-key.jks
```

**⚠️ NO subas este archivo a Git** (ya está en .gitignore)

---

## 🔄 PASO 3: ACTUALIZAR VERSIÓN

Edita `android/version.properties`:

```properties
versionCode=4
versionName=1.3.0
```

**Nota:** 
- `versionCode` debe incrementarse SIEMPRE (+1 en cada actualización)
- `versionName` es la versión visible (1.3.0, 1.3.1, etc.)

---

## 🏗️ PASO 4: COMPILAR AAB (Android App Bundle)

```powershell
# Limpia compilaciones anteriores
flutter clean

# Compila el AAB firmado
flutter build appbundle --release

# El archivo estará en:
# build/app/outputs/bundle/release/app-release.aab
```

**¿Por qué AAB y no APK?**
- Google Play requiere AAB desde agosto 2021
- Tamaño de descarga optimizado (Google genera APKs específicos)
- Mejor compresión y rendimiento

---

## 📤 PASO 5: CREAR APLICACIÓN EN PLAY CONSOLE

1. **Accede a:** https://play.google.com/console
2. **Clic en:** "Crear aplicación"
3. **Completa:**

### Información Básica
- **Nombre de la app:** Zentavo - Control de Gastos
- **Idioma predeterminado:** Español (España) o tu idioma
- **Tipo de aplicación:** App
- **Gratis o de pago:** Gratis
- **Declaraciones:**
  - ☑️ He leído las políticas
  - ☑️ Declaro que esta app cumple con las leyes de EE.UU.

4. **Clic en:** "Crear aplicación"

---

## 📋 PASO 6: COMPLETAR INFORMACIÓN DE LA APP

### 6.1 Ficha de Play Store

**Descripción corta** (máx. 80 caracteres):
```
Control total de tus finanzas: gastos, ingresos, ahorros y presupuestos
```

**Descripción completa** (máx. 4000 caracteres):
```
🌟 Zentavo - Tu Control Financiero Personal 🌟

Toma el control de tus finanzas de manera fácil, rápida y efectiva con Zentavo, 
la app más completa para gestionar tus gastos, ingresos y ahorros.

✨ CARACTERÍSTICAS PRINCIPALES:

💰 GESTIÓN FINANCIERA COMPLETA
• Registra ingresos y egresos en segundos
• Categorías predefinidas e ilimitadas
• Soporte para 16 monedas internacionales
• Conversión automática entre divisas
• Presupuesto mensual con alertas inteligentes

📊 ANÁLISIS Y REPORTES
• Gráficos detallados de gastos por categoría
• Reportes mensuales, trimestrales y anuales
• Exportación en PDF, Excel, CSV y JSON
• Análisis predictivo con IA (Premium)
• Identificación de patrones de gasto

💳 GASTOS FIJOS Y RECURRENTES
• Programa pagos mensuales automáticos
• Recordatorios de vencimientos
• Control de suscripciones
• Historial completo

🎯 AHORROS INTELIGENTES
• Meta de ahorro personalizable
• Seguimiento automático del progreso
• Ahorros en múltiples monedas
• Compra y cambio de divisas integrado
• Proyecciones de ahorro futuro

🔐 SEGURIDAD Y PRIVACIDAD
• Datos almacenados localmente en tu dispositivo
• Protección con huella digital o PIN
• Respaldo y restauración de datos
• Sin recopilación de información personal
• Compatible con Google Drive (Premium)

🌍 MULTIIDIOMA
• Español, Inglés, Portugués, Italiano, Chino y Japonés
• Interfaz adaptable a tu idioma

🎨 PERSONALIZACIÓN
• Modo claro y oscuro
• 16 monedas soportadas
• Categorías personalizadas (Premium)
• Temas de color

🆓 VERSIÓN PREMIUM
• Categorías ilimitadas personalizadas
• Análisis avanzado con IA
• Respaldo automático en la nube
• Reportes detallados sin límites
• Exportación sin marca de agua
• Soporte prioritario

📱 FUNCIONES ADICIONALES
• Eventos compartidos para gastos grupales
• Códigos QR para compartir
• Tutorial interactivo
• FAQ y soporte técnico integrado
• Sin anuncios molestos

🏆 ¿POR QUÉ ZENTAVO?
• Interfaz intuitiva y moderna
• Sin suscripciones ocultas
• Actualizaciones constantes
• Soporte técnico en español
• Desarrollado pensando en Latinoamérica

💡 IDEAL PARA:
• Personas que quieren controlar sus finanzas
• Familias que buscan ahorrar
• Estudiantes que gestionan su presupuesto
• Freelancers y emprendedores
• Viajeros que manejan múltiples monedas

📧 CONTACTO:
soporte@zentavo.com

¡Descarga Zentavo hoy y comienza a tomar control de tu futuro financiero! 💪
```

### 6.2 Recursos Gráficos

**Necesitas crear:**

1. **Ícono de la aplicación** (512x512 px, PNG)
   - Sin transparencia
   - Debe ser legible en tamaños pequeños

2. **Gráfico destacado** (1024x500 px, PNG/JPG)
   - Imagen promocional principal
   - Aparece en la cabecera de Play Store

3. **Screenshots de teléfono** (mínimo 2):
   - Resolución: 1080x1920 px (o similar)
   - Captura pantallas principales de la app
   - Recomendado: 4-8 screenshots

4. **Screenshots de tablet** (opcional, pero recomendado):
   - Resolución: 2048x1536 px o mayor

**Sugerencias de Screenshots:**
1. Pantalla principal con transacciones
2. Gráficos de gastos por categoría
3. Pantalla de ahorros
4. Pantalla de presupuesto
5. Pantalla de reportes/exportación
6. Configuración de monedas
7. Tema oscuro

### 6.3 Categorización

- **Categoría de aplicación:** Finanzas
- **Etiquetas:** finanzas personales, presupuesto, ahorros, control de gastos

---

## 🔒 PASO 7: CONFIGURAR PRIVACIDAD Y SEGURIDAD

### 7.1 Política de Privacidad
**Debes crear y alojar una política de privacidad**

Ejemplo de contenido básico:

```markdown
# Política de Privacidad de Zentavo

Última actualización: 10 de marzo de 2026

## Información que Recopilamos
Zentavo NO recopila, almacena ni transmite información personal. 
Todos los datos se guardan localmente en tu dispositivo.

## Almacenamiento de Datos
- Los datos financieros se almacenan en tu dispositivo
- Puedes hacer respaldo manual en la nube de tu elección
- No tenemos acceso a tus datos

## Permisos
- Almacenamiento: Para guardar tus datos localmente
- Cámara: Solo si usas escaneo de QR (opcional)
- Biometría: Para proteger tu app (opcional)

## Contacto
soporte@zentavo.com
```

**Aloja en:**
- GitHub Pages gratis
- Tu sitio web
- Servicios como Privacy Policy Generator

**URL de ejemplo:** https://zentavo.com/privacy

### 7.2 Cuestionario de Seguridad de Datos

En Play Console responde:
- ¿Recopilas datos? **No** (si es verdad)
- ¿Compartes datos? **No**
- ¿Los datos están cifrados? **Sí** (si usas SharedPreferences cifradas)
- ¿Los usuarios pueden solicitar eliminación? **Sí** (desinstalando la app)

---

## 📦 PASO 8: SUBIR EL AAB

1. **Ve a:** "Producción" → "Crear versión nueva"
2. **Sube:** `build/app/outputs/bundle/release/app-release.aab`
3. **Notas de la versión:**
```
Versión 1.3.0 - ¡Nueva actualización!

NOVEDADES:
• Servicio técnico integrado con FAQ
• Compartir app mediante código QR
• Desglose detallado por monedas
• Mejoras de interfaz y rendimiento

CORRECCIONES:
• Optimización general de la app
• Correcciones menores de bugs
```

4. **Revisa y publica**

---

## ✅ PASO 9: COMPLETAR REVISIÓN PRE-LANZAMIENTO

### Clasificación de Contenido
1. **Completa el cuestionario IARC**
2. **Categoría:** Finanzas
3. **Violencia/Temas maduros:** Ninguno
4. **Obtendrás:** Clasificación para todos (E para Everyone)

### Audiencia Objetivo
- **Audiencia principal:** Mayores de 13 años
- **Contenido infantil:** No

### Aplicaciones de Noticias
- ¿Es una app de noticias? **No**

---

## 🚀 PASO 10: ENVIAR A REVISIÓN

1. **Revisa toda la información**
2. **Clic en:** "Revisar versión"
3. **Verifica lista de verificación** (debe estar todo verde ✅)
4. **Clic en:** "Iniciar lanzamiento en producción"

### Tiempos de Revisión
- **Primera vez:** 3-7 días
- **Actualizaciones:** 1-3 días
- **Revisión acelerada:** Si es urgente, solicítala

---

## 📊 PASO 11: SEGUIMIENTO POST-PUBLICACIÓN

### Panel de Play Console
Monitorea:
- 📈 Descargas diarias
- ⭐ Calificaciones y reseñas
- 🐛 Informes de errores (Crashlytics)
- 💬 Comentarios de usuarios

### Responde a Reseñas
- Lee comentarios
- Responde dudas
- Agradece feedback positivo
- Soluciona problemas reportados

---

## 🔄 ACTUALIZACIONES FUTURAS

Para actualizar la app:

1. Modifica el código
2. Incrementa `versionCode` en version.properties
3. Actualiza `versionName` según el tipo de cambio
4. Compila nuevo AAB: `flutter build appbundle --release`
5. Sube a Play Console en "Producción" → "Crear versión nueva"
6. Escribe notas de la versión
7. Publica

---

## ❌ POSIBLES RECHAZOS Y SOLUCIONES

### Rechazo por Política de Privacidad
**Solución:** Sube una política de privacidad clara y accesible

### Rechazo por Permisos
**Solución:** Justifica cada permiso en la descripción

### Rechazo por Contenido Engañoso
**Solución:** Asegúrate que screenshots y descripción sean precisos

### Rechazo por Funcionalidad Incompleta
**Solución:** Prueba toda la app, no debe tener secciones sin implementar

---

## 📞 SOPORTE

### Play Console Help
https://support.google.com/googleplay/android-developer

### Contacto Directo
- Chat en vivo en Play Console
- Formularios de contacto
- Centro de ayuda

---

## ✅ CHECKLIST FINAL

Antes de publicar, verifica:

- [ ] AAB compilado correctamente
- [ ] Versión actualizada (versionCode y versionName)
- [ ] Keystore guardado de forma segura (backup)
- [ ] Descripción completa en Play Console
- [ ] Screenshots de calidad (mínimo 2)
- [ ] Ícono 512x512 px
- [ ] Gráfico destacado 1024x500 px
- [ ] Política de privacidad alojada y enlazada
- [ ] Cuestionario de seguridad de datos completado
- [ ] Clasificación de contenido completada
- [ ] App testeada en diferentes dispositivos
- [ ] Sin errores de compilación
- [ ] Información de contacto actualizada

---

🎉 ¡Listo! Tu app estará disponible en Play Store en pocos días.
