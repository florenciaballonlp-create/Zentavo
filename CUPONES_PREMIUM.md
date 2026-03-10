# 🎁 Sistema de Cupones Premium

## ¿Qué son los cupones?

Los **cupones de descuento** te permiten regalar acceso Premium a familiares, amigos o hacer promociones especiales sin necesidad de que pasen por el proceso de compra.

## 🎯 Tipos de Cupones

### 1. Cupones Ilimitados (Valor: -1 días)
Premium sin fecha de expiración. Ideal para:
- 👨‍👩‍👧‍👦 Regalar a familiares
- 🎁 Premios especiales
- 👥 Empleados o colaboradores

**Cupones actuales:**
- `FAMILIA2026` - Para familiares
- `REGALO2026` - Para regalar
- `AMIGO2026` - Para amigos
- `ZENTAVO2026` - Cupón especial tuyo

### 2. Cupones Anuales (365 días)
Premium válido por un año. Ideal para:
- 🎉 Promociones anuales
- 🎊 Ofertas especiales
- 📢 Campañas de marketing

**Cupones actuales:**
- `PROMO365` - Promoción anual
- `ANUAL2026` - Año completo

### 3. Cupones de Prueba (30 días)
Premium temporal para probar. Ideal para:
- 🧪 Testing
- 📝 Reviews
- 🎥 Demos

**Cupones actuales:**
- `PRUEBA30` - Prueba de 30 días
- `TEST30` - Prueba de 30 días

## 📝 Cómo Agregar Nuevos Cupones

### Opción 1: Editar el código

1. Abre `lib/premium_screen.dart`
2. Busca el mapa `_validCoupons` (línea ~50)
3. Agrega tu cupón:

```dart
static const Map<String, int> _validCoupons = {
  // Tus cupones existentes...
  
  // Agregar nuevo cupón aquí:
  'NAVIDAD2026': 365,  // 1 año
  'REGALO_MAMA': -1,   // Ilimitado
  'PROMO15DIAS': 15,   // 15 días
};
```

4. Recompila la app

### Opción 2: Valores permitidos

- **-1**: Premium ilimitado (sin expiración)
- **Número positivo**: Días de Premium (ej: 30, 90, 365)

## 🎁 Cómo Usar un Cupón

### Para el usuario:

1. Abre la app Zentavo
2. Ve a la pantalla Premium (⭐ Premium)
3. Scroll hacia abajo
4. Haz clic en **"¿Tienes un cupón de descuento?"**
5. Ingresa el código (ej: `FAMILIA2026`)
6. Clic en **"Canjear"**
7. ✅ ¡Premium activado!

### Características:

- ✅ Cada cupón solo se puede usar **una vez por dispositivo**
- ✅ El sistema valida que el cupón exista
- ✅ No se puede reutilizar un cupón ya canjeado
- ✅ Los cupones no son sensibles a mayúsculas/minúsculas

## 📊 Información que se Guarda

Cuando se canjea un cupón, la app guarda:

```json
{
  "is_premium": true,
  "premium_source": "coupon",
  "premium_coupon": "FAMILIA2026",
  "premium_plan": "Ilimitado (Cupón)" // o "365 días (Cupón)",
  "premium_expiration": "2027-02-19T10:30:00.000Z", // Solo si no es ilimitado
  "used_coupons": ["FAMILIA2026", "OTRO_CUPON"]
}
```

## 🔒 Seguridad

### Limitaciones actuales:
- ⚠️ Los cupones están hardcodeados en el código
- ⚠️ El historial de cupones usados es local (por dispositivo)
- ⚠️ Si el usuario desinstala la app, puede reusar el cupón

### Para mayor seguridad (futuro):
- 💡 Implementar validación de cupones en servidor
- 💡 Base de datos de cupones usados global
- 💡 Generación dinámica de cupones únicos
- 💡 Límite de usos por cupón

## 🎨 Personalización

### Cambiar mensajes de éxito/error

Edita los métodos en `premium_screen.dart`:
- `_validateAndApplyCoupon()` - Mensaje de error
- `_activatePremiumWithCoupon()` - Mensaje de éxito

### Cambiar diseño del diálogo

Edita el método `_showCouponDialog()` en `premium_screen.dart`

## 📱 Ejemplos de Uso

### Caso 1: Regalo Familiar
```
Tú: "Mira mamá, te regalo Premium de Zentavo"
Mamá: "¿Cómo lo activo?"
Tú: "Descarga la app, ve a Premium y usa el cupón: FAMILIA2026"
Mamá: "¡Ya está! Dice Premium Ilimitado activado 🎉"
```

### Caso 2: Promoción en Redes
```
Tweet: "🎉 ¡Sorteo! Los primeros 10 en comentar ganan Premium por 1 año
       Cupón: PROMO365"
       
Usuario: *Ingresa cupón*
App: "¡Felicidades! Premium activado por 365 días"
```

### Caso 3: Prueba a Amigo
```
Amigo: "¿Zentavo es buena?"
Tú: "¡Pruébala! Usa el cupón TEST30 para 30 días gratis"
Amigo: *Prueba por 30 días*
Amigo: "¡Me encantó! Voy a comprarlo"
```

## 🚀 Mejores Prácticas

### ✅ Hacer:
- Crear cupones con nombres memorables
- Usar códigos cortos y fáciles de escribir
- Documentar para qué es cada cupón
- Usar MAYÚSCULAS para consistencia

### ❌ Evitar:
- Cupones muy largos o complejos
- Nombres confusos o genéricos
- Compartir cupones ilimitados públicamente sin control
- Olvidar quitar cupones de prueba en producción

## 📈 Tracking (Futuro)

Ideas para implementar:

```dart
// Guardar analytics de cupones
{
  'coupon_redeemed': {
    'coupon_code': 'FAMILIA2026',
    'redemption_date': '2026-02-19',
    'user_id': 'abc123',
    'source': 'mobile_app'
  }
}
```

## 🎯 Estrategias de Cupones

### Para Crecimiento:
- `NUEVA_CUENTA30` - Para nuevos usuarios
- `REFERIDO365` - Para usuarios referidos
- `INSTAGRAM50` - Para seguidores de Instagram

### Para Retención:
- `REGRESA90` - Para usuarios inactivos
- `LEAL2026` - Para usuarios antiguos
- `FEEDBACK365` - Por dejar review

### Para Marketing:
- `BLACK2026` - Black Friday
- `CYBER2026` - Cyber Monday
- `NAVIDAD2026` - Navidad
- `ANIO_NUEVO` - Año Nuevo

## 🛠️ Troubleshooting

### "Cupón inválido"
- ✅ Verifica que el cupón esté en el mapa `_validCoupons`
- ✅ Revisa que no haya errores de escritura
- ✅ Confirma que estés usando la última versión de la app

### "Cupón ya usado"
- ℹ️ Cada cupón solo se puede usar una vez por instalación
- 💡 Solución: Crear un nuevo cupón o desinstalar/reinstalar (borra datos)

### No aparece botón de cupones
- ✅ Verifica que estés en la pantalla Premium
- ✅ Asegúrate de hacer scroll hasta el final
- ✅ Recompila la app

## 📞 Soporte

Si un familiar o amigo tiene problemas con el cupón:

1. Verifica que el cupón esté activo en el código
2. Confirma que no lo haya usado antes
3. Guíalos paso a paso por la app
4. Como último recurso, usa el modo desarrollador para activarles Premium directamente

---

**Versión**: 1.2.0  
**Última actualización**: Febrero 2026  
**Cupones activos**: 10 cupones disponibles  
**Desarrollado con** ❤️ **para compartir Premium con quien quieras**
