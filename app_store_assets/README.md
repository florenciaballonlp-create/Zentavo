# 📱 Assets para App Store (iOS)

**Fecha:** 11 de marzo de 2026  
**App:** Zentavo - Control Financiero

---

## 📋 Checklist de Assets Requeridos

### ✅ Completados

- [x] Icono base (512×512) - `play_store_assets/zentavo_icon_512.png`
- [x] Screenshots Android (5 imágenes)
- [x] Logo splash screen

### ⏳ Pendientes para App Store

#### **1. Icono App Store (1024×1024px)**

**Especificaciones:**
- Tamaño: 1024 × 1024 píxeles
- Formato: PNG (sin transparencia)
- Espacio de color: sRGB o P3
- **Sin bordes redondeados** (iOS los agrega automáticamente)

**Archivo a crear:**
```
app_store_assets/icons/AppIcon-1024.png
```

**Cómo crearlo:**
Escala tu icono actual (`play_store_assets/zentavo_icon_512.png`) a 1024×1024px usando:
- Photoshop / GIMP: Image → Scale → 1024×1024
- Online: https://www.simpleimageresizer.com
- Canva: Redimensionar a 1024×1024

---

#### **2. Screenshots iPhone (Obligatorios)**

**iPhone 6.7" - iPhone 14 Pro Max / 15 Pro Max:**
- Tamaño: **1290 × 2796 píxeles** (portrait)
- Mínimo: 3 screenshots
- Máximo: 10 screenshots
- Formato: PNG o JPG

**Archivos a crear:**
```
app_store_assets/screenshots/iphone_6.7/
  01_dashboard.png
  02_graficos.png
  03_ahorros.png
  04_transacciones.png (opcional)
  05_gastos_fijos.png (opcional)
```

**Cómo obtenerlos:**

**Opción A: Simulador iOS (cuando tengas Mac)**
```bash
# En Mac con Xcode
flutter run -d "iPhone 15 Pro Max"
# Tomar screenshots: Cmd + S
# Ubicación: ~/Desktop/
```

**Opción B: Redimensionar desde Android**
Los screenshots de Android actuales son ~1080×2400px. Puedes escalarlos:

1. Abrir cada screenshot Android en editor de imagen
2. Redimensionar a 1290×2796px (agregar espacio vertical si es necesario)
3. Centrar contenido
4. Guardar como PNG

**Opción C: Usar Figma/Canva**
1. Crear frame 1290×2796px
2. Importar screenshots Android como referencia
3. Ajustar dimensiones
4. Exportar PNG

---

#### **3. Screenshots iPad (Opcionales pero recomendados)**

**iPad Pro 12.9" (3ra gen o posterior):**
- Tamaño: **2048 × 2732 píxeles** (portrait)
- Mínimo: 3 screenshots
- Formato: PNG o JPG

**Archivos a crear:**
```
app_store_assets/screenshots/ipad_12.9/
  01_dashboard.png
  02_graficos.png
  03_ahorros.png
```

**Nota:** Si no tienes iPad, puedes **NO subir** screenshots de iPad. App Store permite solo screenshots de iPhone.

---

## 🎯 Comparación: Play Store vs App Store

| Aspecto | Play Store (Android) | App Store (iOS) |
|---------|---------------------|-----------------|
| **Icono** | 512×512px | 1024×1024px |
| **Banner** | 1024×500px | ❌ No se usa |
| **Screenshots** | Flexible (~1080×2400) | Exactos (1290×2796) |
| **Min screenshots** | 2 | 3 |
| **Max screenshots** | 8 | 10 |
| **Video preview** | Sí (opcional) | Sí (opcional) |

---

## 📐 Tamaños Exactos por Dispositivo iOS

### **iPhone (Obligatorio - elige UNO):**

| Dispositivo | Tamaño (portrait) | Equivalente |
|-------------|------------------|-------------|
| **6.7" Display** | 1290 × 2796 | iPhone 14/15 Pro Max ⭐ |
| 6.5" Display | 1242 × 2688 | iPhone 11 Pro Max |
| 5.5" Display | 1242 × 2208 | iPhone 8 Plus |

**Recomendado:** Usa 6.7" (1290×2796) → Es el más moderno

### **iPad (Opcional):**

| Dispositivo | Tamaño (portrait) |
|-------------|------------------|
| **12.9" Display** | 2048 × 2732 ⭐ |
| 11" Display | 1668 × 2388 |

---

## 🛠️ Herramientas Recomendadas

### **Para Redimensionar Imágenes:**

**Online (Gratis):**
- https://www.simpleimageresizer.com
- https://www.befunky.com/create/resize-image/
- https://www.iloveimg.com/resize-image

**Software Desktop:**
- **Windows:** Paint 3D, GIMP (gratis)
- **Mac:** Preview (incluido), Pixelmator
- **Multiplataforma:** GIMP, Krita

### **Para Crear Screenshots Profesionales:**

**Mockup Generators:**
- https://mockuphone.com (agrega frame de iPhone)
- https://smartmockups.com (screenshots en dispositivos)
- https://previewed.app (mockups profesionales)

**Ejemplo de uso:**
1. Sube tu screenshot actual
2. Selecciona "iPhone 15 Pro Max"
3. Descarga imagen 1290×2796px con frame

---

## 📝 Plan de Acción

### **Ahora (Sin Mac todavía):**

1. **Escalar icono a 1024×1024:**
   - Toma: `play_store_assets/zentavo_icon_512.png`
   - Escala a: 1024×1024px
   - Guarda en: `app_store_assets/icons/AppIcon-1024.png`

2. **Preparar 3-5 screenshots:**
   - Usa screenshots Android de `play_store_assets/screenshots/`
   - Redimensiona a 1290×2796px
   - Agrega padding vertical si es necesario
   - Guarda en: `app_store_assets/screenshots/iphone_6.7/`

3. **Opcional: Mockups profesionales**
   - Usa mockuphone.com para agregar frames de iPhone
   - Hace que se vea más profesional

### **Cuando tengas Apple Developer ($99):**

4. **Crear App en App Store Connect:**
   - Ve a: https://appstoreconnect.apple.com
   - My Apps → + → New App
   - Bundle ID: `com.zentavo.controlgastos`
   - Sube todos los assets preparados

5. **Compilar con GitHub Actions (o Mac):**
   - Configura certificados de firma
   - GitHub compila IPA firmado
   - Subes a App Store Connect

6. **Enviar a revisión:**
   - Completa metadata (descripciones ya las tienes)
   - Add build (IPA)
   - Submit for Review
   - Espera 1-3 días

---

## 📊 Progreso Actual

### **Assets Listos:**
- ✅ Logo original
- ✅ Screenshots Android (base para iOS)
- ✅ Icono 512×512

### **Falta Crear:**
- [ ] Icono 1024×1024
- [ ] 3-5 Screenshots iPhone 1290×2796
- [ ] (Opcional) Screenshots iPad 2048×2732

### **Costo Total:**
- ✅ Assets: $0 (puedes hacerlos gratis)
- ⏳ Apple Developer: $99/año (cuando estés lista)
- ⏳ Mac en nube (opcional): $20-79/mes

---

## ✅ Siguiente Paso

**Opción 1: Crear assets ahora**
Te ayudo a redimensionar las imágenes actuales para iOS

**Opción 2: Esperar a tener Mac**
Compilas y tomas screenshots directamente en simulador iOS (más preciso)

**Opción 3: Continuar con Play Console**
Terminas Android primero, iOS cuando tengas $99 para Apple Developer

---

**¿Qué prefieres hacer ahora?**
