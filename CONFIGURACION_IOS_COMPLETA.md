# 🍎 Configuración Completa de iOS para Zentavo

**Fecha:** 11 de marzo de 2026  
**Bundle ID:** com.zentavo.controlgastos  
**Team ID:** 9PC7H336M6  
**Apple ID:** florenciaballonlp@gmail.com

---

## 📋 PASO 1: Configurar GitHub Secrets

Ve a tu repositorio Zentavo en GitHub y configura estos secrets:

**URL:** https://github.com/florenciaballonlp-create/Zentavo/settings/secrets/actions

### **Secrets a crear:**

Click en **"New repository secret"** para cada uno:

#### 1. APPLE_ID
```
florenciaballonlp@gmail.com
```

#### 2. APPLE_APP_SPECIFIC_PASSWORD
```
hneg-aqas-ugfk-owms
```

#### 3. MATCH_GIT_URL
```
https://github.com/florenciaballonlp-create/zentavo-certificates
```

#### 4. MATCH_PASSWORD
**Genera una contraseña segura (20+ caracteres):**
```
ZentavoMatch2026!SecureKey#iOS
```
⚠️ **IMPORTANTE:** Guarda esta contraseña en un lugar seguro. La necesitarás siempre para acceder a los certificados.

#### 5. MATCH_GIT_BASIC_AUTHORIZATION
**Genera un Personal Access Token de GitHub:**

1. Ve a: https://github.com/settings/tokens
2. Click **"Generate new token (classic)"**
3. Nombre: `Zentavo Match Certificates`
4. Scopes: Marca **"repo"** (todos los permisos de repositorio)
5. Click **"Generate token"**
6. Copia el token (ejemplo: `ghp_xxxxxxxxxxxxxxxxxxxx`)
7. Convierte a Base64:
   - En PowerShell ejecuta:
     ```powershell
     $token = "TU_TOKEN_AQUI"
     $base64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($token))
     Write-Host $base64
     ```
8. Usa el resultado como valor del secret

#### 6. TEAM_ID
```
9PC7H336M6
```

#### 7. APP_STORE_CONNECT_API_KEY_ID
**Lo obtendrás en el siguiente paso** (déjalo pendiente por ahora)

#### 8. APP_STORE_CONNECT_ISSUER_ID
**Lo obtendrás en el siguiente paso** (déjalo pendiente por ahora)

#### 9. APP_STORE_CONNECT_API_KEY_CONTENT
**Lo obtendrás en el siguiente paso** (déjalo pendiente por ahora)

---

## 📋 PASO 2: Crear App Store Connect API Key

1. Ve a: **https://appstoreconnect.apple.com/access/api**
2. Click **"+"** para crear nueva key
3. Configuración:
   ```
   Name: Zentavo GitHub Actions
   Access: App Manager
   ```
4. Click **"Generate"**
5. **Descarga el archivo** (.p8) - SOLO se puede descargar UNA VEZ
6. Anota:
   - **Key ID** (ejemplo: `ABC123DEFG`) → Secret `APP_STORE_CONNECT_API_KEY_ID`
   - **Issuer ID** (arriba de la lista, ejemplo: `12345678-...`) → Secret `APP_STORE_CONNECT_ISSUER_ID`
7. Abre el archivo .p8 con notepad y copia TODO el contenido:
   ```
   -----BEGIN PRIVATE KEY-----
   ...contenido completo...
   -----END PRIVATE KEY-----
   ```
   → Secret `APP_STORE_CONNECT_API_KEY_CONTENT`

---

## 📋 PASO 3: Crear App en App Store Connect

1. Ve a: **https://appstoreconnect.apple.com/apps**
2. Click **"+"** → **"New App"**
3. Configuración:
   ```
   Platform: iOS
   Name: Zentavo
   Primary Language: Spanish (Spain)
   Bundle ID: com.zentavo.controlgastos (selecciona del menú)
   SKU: zentavo-ios-2026 (identificador único interno)
   User Access: Full Access
   ```
4. Click **"Create"**

---

## 📋 PASO 4: Ejecutar Workflow para Generar Certificados

Una vez configurados TODOS los secrets (pasos 1-2), ejecuta el workflow:

1. Ve a: **https://github.com/florenciaballonlp-create/Zentavo/actions**
2. Selecciona **"📱 iOS Build"**
3. Click **"Run workflow"**
4. Selecciona branch **"main"**
5. Click **"Run workflow"** (botón verde)

### **Qué sucederá:**

1. **Primera ejecución:** Fastlane Match generará certificados y los subirá a `zentavo-certificates`
2. **Compilación:** Se generará el IPA firmado
3. **Subida:** Se subirá automáticamente a App Store Connect
4. **TestFlight:** Quedará disponible para revisión interna

### **Tiempo estimado:** 15-20 minutos

---

## 📋 PASO 5: Enviar a TestFlight para Revisión Externa

Después de que el workflow termine exitosamente:

1. Ve a: **https://appstoreconnect.apple.com/apps**
2. Selecciona **Zentavo**
3. Pestaña **"TestFlight"**
4. En **"Builds"** verás la nueva versión
5. Click en la versión → **"Submit for Review"**
6. Completa el formulario de revisión:
   ```
   Export Compliance: No (si no usas encriptación fuerte)
   Content Rights: Marca que tienes los derechos
   Advertising Identifier: No (si no lo usas)
   ```
7. Click **"Submit"**

### **Tiempo de aprobación:** 24-48 horas

---

## 📋 PASO 6: Instalar en iPhone y Tomar Screenshots

Una vez que Apple apruebe TestFlight:

1. En tu iPhone, instala **"TestFlight"** desde App Store
2. Abre la app TestFlight
3. Inicia sesión con tu Apple ID (florenciaballonlp@gmail.com)
4. Verás **Zentavo** disponible
5. Click **"Install"**
6. Abre Zentavo y toma screenshots perfectos:
   - Activa modo Premium con botón "Activar para pruebas"
   - Carga datos demo
   - Toma 5-6 screenshots en pantallas clave:
     * Dashboard
     * Gráficos
     * Multi-moneda
     * Categorías personalizadas
     * Ahorros
     * Transacciones

### **Cómo tomar screenshots en iPhone:**

- Presiona **Botón lateral + Botón de volumen arriba** simultáneamente
- Los screenshots se guardan en la app **Fotos**
- Transfierelos a tu PC (AirDrop, iCloud, etc.)

### **Dimensiones requeridas:** 1290×2796 (iPhone 6.7")

Si tu iPhone no es de ese tamaño exacto, los screenshots se ajustarán automáticamente en App Store Connect.

---

## 📋 PASO 7: Preparar Metadata en App Store Connect

Con los screenshots listos, completa la información:

1. Ve a: **https://appstoreconnect.apple.com/apps**
2. Selecciona **Zentavo** → **App Store** tab
3. Click **"+"** para crear nueva versión
4. Completa toda la metadata:
   - Name: **Zentavo - Control de Gastos**
   - Subtitle (30 chars): **Gestión financiera personal**
   - Description: [Usa la misma de Play Store]
   - Keywords: finanzas,gastos,ahorro,presupuesto,multi-moneda
   - Screenshots: Sube los 5-6 que tomaste
   - App Icon: 1024×1024 (usa el mismo logo.png escalado)
   - Privacy Policy URL: https://florenciaballonlp-create.github.io/Zentavo/
   - Category: Finance
   - Price: Free with In-App Purchases

5. **Review Information:**
   - Sign-in required: No
   - Demo account: No aplica
   - Notes: 
     ```
     Esta es una versión de revisión con modo desarrollador activado.
     Para acceder a funciones Premium: Menú → Premium → botón "Activar para pruebas".
     Datos de prueba: Menú → Cargar Datos Demo.
     ```

6. Click **"Save"**
7. Click **"Submit for Review"**

### **Tiempo de revisión:** 24-72 horas

---

## ✅ Checklist Completo

- [ ] Todos los GitHub Secrets configurados (9 en total)
- [ ] App Store Connect API Key generada y descargada
- [ ] App creada en App Store Connect
- [ ] Workflow ejecutado exitosamente
- [ ] IPA firmado generado
- [ ] TestFlight build subido
- [ ] TestFlight enviado a revisión externa
- [ ] TestFlight aprobado por Apple (24-48h)
- [ ] App instalada en iPhone vía TestFlight
- [ ] Screenshots tomados (5-6 imágenes)
- [ ] Metadata completada en App Store Connect
- [ ] App enviada a revisión final

---

## 🆘 Problemas Comunes

### **Error: "Match password incorrect"**
- Verifica que `MATCH_PASSWORD` sea exactamente la misma que usaste inicialmente
- Si es la primera vez, puede ser que el repo esté vacío (normal)

### **Error: "Invalid bundle identifier"**
- Asegúrate de haber registrado `com.zentavo.controlgastos` en developer.apple.com

### **Error: "No code signing identity found"**
- Primera ejecución: Match lo generará automáticamente
- Ejecuciones posteriores: Verifica que el token de GitHub tenga permisos de repo

### **Error al subir a TestFlight**
- Verifica que la API Key tenga rol "App Manager"
- Verifica que los 3 secrets de API Key estén correctos

---

## 📞 Siguiente Paso

Después de configurar todos los secrets, dime **"Listo con secrets"** y ejecutaré el workflow para generar los certificados y compilar el IPA.

**¿Alguna duda antes de empezar con los secrets?**
