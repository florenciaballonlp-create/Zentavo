import 'localization.dart';

/// Servicio de conversión de divisas con tasas de cambio actualizadas
/// Las tasas están basadas en 1 USD como referencia
class CurrencyExchangeService {
  // Tasas de cambio actualizadas al 19 de febrero de 2026
  // Todas las tasas están en relación a 1 USD
  static const Map<String, double> _exchangeRates = {
    'usd': 1.0,           // Dólar estadounidense (base)
    'eur': 0.92,          // Euro
    'gbp': 0.79,          // Libra esterlina
    'mxn': 17.12,         // Peso mexicano
    'ars': 850.50,        // Peso argentino
    'clp': 950.00,        // Peso chileno
    'brl': 5.15,          // Real brasileño
    'inr': 83.25,         // Rupia india
    'jpy': 149.50,        // Yen japonés
    'cad': 1.35,          // Dólar canadiense
    'aud': 1.54,          // Dólar australiano
    'chf': 0.88,          // Franco suizo
    'cny': 7.24,          // Yuan chino
    'sek': 10.85,         // Corona sueca
    'nok': 10.65,         // Corona noruega
    'zar': 19.15,         // Rand sudafricano
  };

  /// Convierte un monto de una moneda a otra
  /// [amount] Monto a convertir
  /// [from] Moneda origen
  /// [to] Moneda destino
  /// Retorna el monto convertido
  static double convert({
    required double amount,
    required AppCurrency from,
    required AppCurrency to,
  }) {
    if (from == to) return amount;

    final fromCode = from.toString().split('.').last.toLowerCase();
    final toCode = to.toString().split('.').last.toLowerCase();

    final fromRate = _exchangeRates[fromCode] ?? 1.0;
    final toRate = _exchangeRates[toCode] ?? 1.0;

    // Convertir a USD primero, luego a la moneda destino
    final amountInUSD = amount / fromRate;
    final convertedAmount = amountInUSD * toRate;

    return convertedAmount;
  }

  /// Obtiene la tasa de cambio entre dos monedas
  /// Retorna cuántas unidades de [to] equivalen a 1 unidad de [from]
  static double getExchangeRate({
    required AppCurrency from,
    required AppCurrency to,
  }) {
    return convert(amount: 1.0, from: from, to: to);
  }

  /// Formatea un texto mostrando la conversión entre monedas
  /// Ejemplo: "100.00 USD = 92.00 EUR"
  static String formatConversion({
    required double amount,
    required AppCurrency from,
    required AppCurrency to,
  }) {
    final converted = convert(amount: amount, from: from, to: to);
    return '${from.formatAmount(amount)} = ${to.formatAmount(converted)}';
  }

  /// Verifica si una moneda está soportada
  static bool isSupported(AppCurrency currency) {
    final code = currency.toString().split('.').last.toLowerCase();
    return _exchangeRates.containsKey(code);
  }

  /// Obtiene todas las tasas de cambio desde una moneda base
  /// Útil para mostrar una tabla de conversión
  static Map<AppCurrency, double> getAllRatesFrom(AppCurrency baseCurrency) {
    final rates = <AppCurrency, double>{};
    for (var currency in AppCurrency.values) {
      if (currency != baseCurrency) {
        rates[currency] = getExchangeRate(from: baseCurrency, to: currency);
      }
    }
    return rates;
  }

  /// Obtiene el nombre del código de moneda (para debugging)
  static String getCurrencyCode(AppCurrency currency) {
    return currency.toString().split('.').last.toUpperCase();
  }

  /// Calcula el monto total en la moneda principal desde múltiples monedas
  /// [amounts] Mapa de moneda -> monto
  /// [mainCurrency] Moneda a la que convertir todo
  static double calculateTotalInMainCurrency({
    required Map<AppCurrency, double> amounts,
    required AppCurrency mainCurrency,
  }) {
    double total = 0.0;
    amounts.forEach((currency, amount) {
      total += convert(amount: amount, from: currency, to: mainCurrency);
    });
    return total;
  }

  /// Formatea un desglose con conversión
  /// Ejemplo: 
  /// "100.00 USD (principal)
  ///  50.00 EUR → 54.35 USD
  ///  Total: 154.35 USD"
  static String formatBreakdownWithConversion({
    required double mainAmount,
    required AppCurrency mainCurrency,
    required Map<AppCurrency, double> foreignAmounts,
  }) {
    final buffer = StringBuffer();
    
    // Monto principal
    buffer.writeln('${mainCurrency.formatAmount(mainAmount)} (${_getLabel(mainCurrency, true)})');
    
    // Montos extranjeros con conversión
    double totalConverted = mainAmount;
    foreignAmounts.forEach((currency, amount) {
      if (amount != 0) {
        final converted = convert(amount: amount, from: currency, to: mainCurrency);
        totalConverted += converted;
        buffer.writeln('${currency.formatAmount(amount)} → ${mainCurrency.formatAmount(converted)}');
      }
    });
    
    // Total
    if (foreignAmounts.isNotEmpty) {
      buffer.writeln('─────────────');
      buffer.write('Total: ${mainCurrency.formatAmount(totalConverted)}');
    }
    
    return buffer.toString().trim();
  }

  static String _getLabel(AppCurrency currency, bool isMain) {
    if (isMain) return 'principal';
    return currency.name.split(' - ')[0];
  }

  /// Obtiene un mensaje legible sobre la tasa de cambio
  /// Ejemplo: "1 USD = 0.92 EUR"
  static String getExchangeRateMessage({
    required AppCurrency from,
    required AppCurrency to,
  }) {
    final rate = getExchangeRate(from: from, to: to);
    return '1 ${getCurrencyCode(from)} = ${to.formatAmount(rate)}';
  }

  /// Actualiza las tasas de cambio (placeholder para implementación futura con API)
  /// En una versión futura, esto llamará a una API real como:
  /// - https://api.exchangerate-api.com/v4/latest/USD
  /// - https://openexchangerates.org/api/latest.json
  /// - https://api.fixer.io/latest
  static Future<bool> updateExchangeRates() async {
    // TODO: Implementar llamada a API real
    // Por ahora usamos tasas fijas
    return Future.value(true);
  }

  /// Obtiene la fecha de última actualización (placeholder)
  static DateTime getLastUpdateDate() {
    // En una implementación real, esto se guardaría en SharedPreferences
    return DateTime(2026, 2, 19);
  }
}
