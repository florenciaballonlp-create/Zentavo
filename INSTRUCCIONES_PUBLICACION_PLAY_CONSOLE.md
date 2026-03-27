# 📱 Instrucciones para Publicación en Play Console

**Fecha:** 10 de marzo de 2026  
**App:** Zentavo - Control Financiero  
**Versión para revisión:** 1.2.0 (código 7)

---

## ⚠️ IMPORTANTE: Estrategia de Publicación en 2 Pasos

### **Paso 1: Versión de Revisión (v1.2.0) - Para Google**

✅ **Esta es la versión actual del AAB que subirás ahora**

**Características especiales para revisión:**
- `kDeveloperMode = true` → Google puede acceder a Premium gratis
- Botón "Continuar sin verificar" → Google puede saltar biometría
- Botón "Activar para pruebas" → Activa Premium sin pagar

**Archivo:**
```
build/app/outputs/bundle/release/app-release.aab
Tamaño: 54.7 MB
```

### **Paso 2: Versión de Producción (v1.2.1) - Para Usuarios**

⏳ **Después de que Google apruebe (en 3-7 días)**

Cambiarás una línea de código y subirás actualización:
```dart
const bool kDeveloperMode = false; // ← Cambiar a false
```

Esto eliminará:
- El botón "Activar para pruebas" (usuarios deberán comprar)
- El acceso Premium gratuito

Los usuarios verán la versión limpia sin opciones de desarrollo.

---

## 📝 Instrucciones para Play Console

### **1. Sección: "Algunas funciones están restringidas"**

✅ **Marca:** SÍ, mi app tiene funciones restringidas

**Copia y pega esto en el campo de instrucciones (VERSIÓN CORTA - 500 caracteres):**

```
ACCESO A ZENTAVO: No requiere login. Si aparece biometría, click "Continuar sin verificar". PREMIUM: Menú ⋮→Premium→botón "Activar para pruebas" (al final). Funciones: Multi-moneda (Menú⋮→Monedas), Categorías (Menú⋮→Mis Categorías), Gráficos (Menú⋮→Gráficos). Datos demo: Menú⋮→Cargar Datos Demo. Versión de revisión con acceso Premium gratuito mediante botón de prueba. Versión pública requerirá compra via Google Play Billing.
```

**Caracteres: 458/500** ✅

---

**VERSIÓN EXTENDIDA (para referencia interna, NO copiar en Play Console):**

```
ACCESO COMPLETO A ZENTAVO - VERSIÓN DE REVISIÓN
================================================

ESTA ES UNA VERSIÓN ESPECIAL CON ACCESO PREMIUM PARA REVISIÓN DE GOOGLE.

1. INSTALACIÓN Y APERTURA:
   • Instalar y abrir la aplicación Zentavo
   • Si aparece tutorial/onboarding, completar o hacer click en "Saltar"

2. AUTENTICACIÓN BIOMÉTRICA (OPCIONAL):
   • Si aparece pantalla "Acceso protegido" con solicitud de huella digital
   • Hacer click en el botón "Continuar sin verificar" en la parte inferior
   • La app se abrirá sin necesidad de autenticación
   • (La biometría es 100% opcional y se puede desactivar en Configuración)

3. ACTIVAR PREMIUM PARA REVISIÓN COMPLETA:
   
   Opción A - Activación Automática:
   Esta versión de revisión tiene acceso Premium activado por defecto.
   
   Opción B - Activación Manual (si es necesario):
   • Abrir menú ⋮ (esquina superior derecha)
   • Seleccionar "⭐ Premium"
   • Desplazar hasta el FINAL de la pantalla Premium
   • Hacer click en el botón verde "Activar para pruebas"
   • Confirmar en el diálogo
   • ✅ Premium quedará activado sin necesidad de pago
   
   NOTA: El botón "Activar para pruebas" solo aparece en esta versión de revisión.

4. FUNCIONES PREMIUM PARA EVALUAR:
   Una vez Premium activado:
   
   • Multi-moneda: Menú ⋮ → "Monedas Múltiples"
     (Agregar transacciones en USD, EUR, GBP, etc.)
   
   • Categorías personalizadas: Menú ⋮ → "Mis Categorías"
     (Crear categorías propias con emojis personalizados)
   
   • Recomendaciones financieras: Menú ⋮ → "Recomendaciones Financieras"
     (Consejos automáticos basados en gastos)
   
   • Sin anuncios: Los banners publicitarios desaparecen completamente
   
   • Exportar datos: Disponible en "Gráficos e Informes"
     (Exportar a Excel con todos los datos)

5. FUNCIONES BÁSICAS (SIEMPRE DISPONIBLES SIN PREMIUM):
   
   • Agregar ingresos: Botón flotante VERDE (esquina inferior)
   • Agregar egresos: Botón flotante ROJO (esquina inferior)
   • Ver gráficos: Menú ⋮ → "Gráficos e Informes"
   • Configurar presupuesto: Menú ⋮ → "Presupuesto Mensual"
   • Ahorros y metas: Pestaña "Ahorros" (barra superior)
   • Gastos fijos recurrentes: Menú ⋮ → "Transacciones Fijas"
   • Eventos compartidos: Pestaña "Eventos Compartidos"
   • Cambiar idioma: Menú ⋮ → "Configuración" → "Idioma"
   • Cambiar tema: Menú ⋮ → "Configuración" → "Tema"

6. DATOS DE PRUEBA PARA EVALUACIÓN MÁS COMPLETA (OPCIONAL):
   
   • Menú ⋮ → "📸 Cargar Datos Demo" (aparece en color naranja)
   • Esto llena automáticamente la app con:
     - 20 transacciones variadas
     - 3 presupuestos de ejemplo
     - 2 cuentas de ahorro
     - 3 gastos fijos
   • Permite evaluar gráficos, reportes y funciones con datos realistas

RESUMEN:
========
• NO se requiere login, registro ni credenciales
• Biometría es OPCIONAL (botón "Continuar sin verificar")
• Premium se activa con botón "Activar para pruebas" (sin pago)
• Todas las funciones Premium y básicas son accesibles
• Datos de prueba disponibles con un click

IMPORTANTE PARA GOOGLE:
Esta es una versión especial de revisión. La versión pública para usuarios 
finales NO incluirá el botón "Activar para pruebas" y requerirá compra real 
de Premium a través de Google Play Billing.
```

---

### **2. Sección: "Credenciales para pruebas"**

✅ **Marca:** No se necesitan credenciales

O si hay un campo de texto:

```
No se requieren credenciales.
La app no tiene sistema de login.
El acceso Premium se activa con el botón "Activar para pruebas" incluido 
en esta versión de revisión (ver instrucciones arriba).
```

---

### **3. Sección: "Permitir que Android utilice las credenciales"**

✅ **Marca:** No proporcionar credenciales

**Razón:**
- No hay sistema de autenticación
- No hay backend ni servidor
- Todo funciona localmente en el dispositivo

---

## 📋 Checklist Pre-Envío

Antes de hacer click en "Enviar para revisión":

- [x] AAB compilado con modo desarrollador activado
- [x] Botón "Continuar sin verificar" agregado
- [x] Instrucciones copiadas en Play Console
- [ ] Todos los assets subidos (icono, banner, screenshots)
- [ ] Descripciones agregadas en español
- [ ] Política de privacidad URL agregada
- [ ] Categoría seleccionada: "Finanzas"
- [ ] Clasificación de contenido completada
- [ ] Precio: "Gratis" (con compras dentro de la app)

---

## 🔄 Plan Post-Aprobación

### **Una vez que Google apruebe (3-7 días):**

**Opción A: Dejar como está (RECOMENDADO INICIALMENTE)**
- Los primeros usuarios también tendrán acceso al botón de prueba
- Puedes ver reviews y feedback antes de quitar el botón
- Si hay bugs, mejor que usuarios puedan probar Premium gratis

**Opción B: Subir versión 1.2.1 limpia (1-2 semanas después)**

1. Editar `lib/main.dart`:
   ```dart
   const bool kDeveloperMode = false; // Cambiar a false
   ```

2. Incrementar versión en `android/version.properties`:
   ```
   versionCode=8
   versionName=1.2.1
   ```

3. Recompilar:
   ```bash
   flutter build appbundle --release
   ```

4. Subir a Play Console como "Actualización"

5. Google aprobará en 1-3 días (más rápido que primera vez)

6. Usuarios verán versión limpia donde deben comprar Premium

---

## 🎯 Ventajas de Este Enfoque

### **Por qué usar modo desarrollador en v1.2.0:**

✅ Google puede revisar TODAS las funciones Premium  
✅ No hay riesgo de rechazo por "contenido no accesible"  
✅ Validación completa de la app  
✅ Más rápida la aprobación  

### **Por qué actualizar después a v1.2.1:**

✅ Usuarios reales deben pagar (generas ingresos)  
✅ Versión profesional limpia  
✅ No hay confusión con botones de "prueba"  
✅ Cumples con políticas de monetización  

---

## 📞 Preguntas Frecuentes

**P: ¿Google se dará cuenta del modo desarrollador?**  
R: Sí, por eso las instrucciones lo mencionan explícitamente. Es completamente válido y común proporcionar una versión de revisión con acceso de prueba.

**P: ¿Puedo dejar modo desarrollador activado para siempre?**  
R: No recomendado. Los usuarios podrían compartir el truco y nadie compraría Premium. Actualiza después de 1-2 semanas.

**P: ¿Qué pasa si Google rechaza la app?**  
R: Lee el motivo, corrige, y vuelve a enviar. El modo desarrollador NO es motivo de rechazo si lo explicas.

**P: ¿Cuánto tarda la segunda revisión (v1.2.1)?**  
R: Actualizaciones son más rápidas: 1-3 días vs 3-7 días de la primera.

**P: ¿Los usuarios que descarguen v1.2.0 perderán Premium en v1.2.1?**  
R: Si activaron Premium con el botón de prueba en v1.2.0, lo perderán al actualizar a v1.2.1. Esto es normal y esperado.

---

## ✅ Archivo Listo para Subir

**Ubicación del AAB:**
```
C:\Users\flore\control_gastos\build\app\outputs\bundle\release\app-release.aab
```

**Características:**
- Versión: 1.2.0
- Código: 7
- Tamaño: 54.7 MB
- Firmado con: zentavo-release-key.jks
- Modo desarrollador: ✅ ACTIVADO
- Botón saltar biometría: ✅ INCLUIDO

**✅ ¡Listo para subir a Play Console ahora!**

---

## 🚀 Siguiente Paso

**Ve a Play Console y:**
1. Sección "Producción" → "Crear nueva versión"
2. Sube el AAB de `build/app/outputs/bundle/release/`
3. Copia las instrucciones de este documento donde corresponda
4. Completa todos los campos requeridos
5. Click "Enviar para revisión"
6. ¡Espera 3-7 días! 🎉

**Documenta el keystore (crítico):**
```
Archivo: android/zentavo-release-key.jks
Contraseña: Argentina2025!
⚠️ NO PERDER - Sin este archivo no podrás actualizar la app nunca más
```

---

**¿Dudas sobre algún paso? ¡Pregunta antes de subir!**
