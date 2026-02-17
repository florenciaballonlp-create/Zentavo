import 'package:shared_preferences/shared_preferences.dart';

/// Utilidad para activar/desactivar Premium en modo desarrollo
/// SOLO PARA TESTING - Eliminar en producción
class PremiumTestHelper {
  
  /// Activa Premium sin realizar una compra real
  /// Útil para probar funciones Premium durante el desarrollo
  static Future<void> activatePremiumForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);
    await prefs.setString('premium_product_id', 'premium_lifetime');
    await prefs.setString('premium_purchase_date', DateTime.now().toIso8601String());
    print('✅ Premium activado para testing');
  }

  /// Desactiva Premium
  static Future<void> deactivatePremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_premium');
    await prefs.remove('premium_product_id');
    await prefs.remove('premium_purchase_date');
    print('❌ Premium desactivado');
  }

  /// Verifica el estado Premium actual
  static Future<bool> checkPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool('is_premium') ?? false;
    print('📊 Estado Premium: ${isPremium ? "ACTIVO" : "INACTIVO"}');
    return isPremium;
  }

  /// Muestra información detallada del Premium
  static Future<void> showPremiumInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool('is_premium') ?? false;
    final productId = prefs.getString('premium_product_id');
    final purchaseDate = prefs.getString('premium_purchase_date');
    
    print('=== INFORMACIÓN PREMIUM ===');
    print('Estado: ${isPremium ? "✅ ACTIVO" : "❌ INACTIVO"}');
    if (isPremium) {
      print('Producto: $productId');
      print('Fecha de compra: $purchaseDate');
    }
    print('========================');
  }
}

// EJEMPLO DE USO EN CONSOLA DE DESARROLLO:
//
// Para activar Premium:
// await PremiumTestHelper.activatePremiumForTesting();
//
// Para desactivar Premium:
// await PremiumTestHelper.deactivatePremium();
//
// Para verificar estado:
// await PremiumTestHelper.checkPremiumStatus();
//
// Para ver información completa:
// await PremiumTestHelper.showPremiumInfo();
