import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

/// Servicio de Analytics para trackear el uso de la app
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Eventos disponibles para trackear
  static const String eventAppOpened = 'app_opened';
  static const String eventTransactionCreated = 'transaction_created';
  static const String eventEventoCompartidoCreated = 'evento_compartido_created';
  static const String eventPremiumScreenViewed = 'premium_screen_viewed';
  static const String eventExportData = 'export_data';
  static const String eventGraficosViewed = 'graficos_viewed';
  static const String eventReportesViewed = 'informes_viewed';
  static const String eventGastosFijosViewed = 'gastos_fijos_viewed';
  static const String eventCategoriasPersonalizadasViewed = 'categorias_personalizadas_viewed';
  static const String eventRecomendacionesViewed = 'recomendaciones_viewed';
  static const String eventPresupuestoSet = 'presupuesto_set';
  static const String eventAhorroRegistrado = 'ahorro_registrado';
  static const String eventThemeChanged = 'theme_changed';
  static const String eventLanguageChanged = 'language_changed';
  static const String eventCurrencyChanged = 'currency_changed';
  static const String eventBackupCreated = 'backup_created';
  static const String eventBackupRestored = 'backup_restored';

  /// Propiedades de evento
  static const String propEventType = 'event_type';
  static const String propTransactionType = 'transaction_type'; // Ingreso o Egreso
  static const String propCategory = 'category';
  static const String propAmount = 'amount';
  static const String propSource = 'source'; // De dónde viene la acción
  static const String propIsPremium = 'is_premium';
  static const String propTimestamp = 'timestamp';

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    print('[ANALYTICS] Initialized');
  }

  /// Registrar un evento
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    if (!_initialized) await initialize();

    try {
      // Obtener eventos existentes
      final eventsJson = _prefs.getString('analytics_events') ?? '[]';
      final List<dynamic> events = jsonDecode(eventsJson);

      // Crear nuevo evento
      final event = {
        'event': eventName,
        'timestamp': DateTime.now().toIso8601String(),
        'properties': properties ?? {},
      };

      events.add(event);

      // Limitar a los últimos 1000 eventos para no ocupar mucho espacio
      if (events.length > 1000) {
        events.removeRange(0, events.length - 1000);
      }

      // Guardar
      await _prefs.setString('analytics_events', jsonEncode(events));

      // Incrementar contador global del evento
      final countKey = 'analytics_count_$eventName';
      final currentCount = _prefs.getInt(countKey) ?? 0;
      await _prefs.setInt(countKey, currentCount + 1);

      print('[ANALYTICS] Event tracked: $eventName ${properties != null ? properties.toString() : ""}');
    } catch (e) {
      print('[ANALYTICS] Error tracking event: $e');
    }
  }

  /// Obtener todos los eventos
  Future<List<Map<String, dynamic>>> getEvents() async {
    if (!_initialized) await initialize();

    try {
      final eventsJson = _prefs.getString('analytics_events') ?? '[]';
      final List<dynamic> events = jsonDecode(eventsJson);
      return events.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('[ANALYTICS] Error getting events: $e');
      return [];
    }
  }

  /// Obtener contador de un evento específico
  Future<int> getEventCount(String eventName) async {
    if (!_initialized) await initialize();
    return _prefs.getInt('analytics_count_$eventName') ?? 0;
  }

  /// Obtener estadísticas de uso
  Future<Map<String, dynamic>> getUsageStats() async {
    if (!_initialized) await initialize();

    final stats = <String, dynamic>{};

    // Contadores de eventos principales
    stats['app_opened'] = await getEventCount(eventAppOpened);
    stats['transactions_created'] = await getEventCount(eventTransactionCreated);
    stats['eventos_compartidos_created'] = await getEventCount(eventEventoCompartidoCreated);
    stats['premium_screen_views'] = await getEventCount(eventPremiumScreenViewed);
    stats['exports'] = await getEventCount(eventExportData);
    stats['graficos_views'] = await getEventCount(eventGraficosViewed);
    stats['informes_views'] = await getEventCount(eventReportesViewed);
    stats['gastos_fijos_views'] = await getEventCount(eventGastosFijosViewed);
    stats['recomendaciones_views'] = await getEventCount(eventRecomendacionesViewed);

    // Fecha de primera apertura
    final firstOpen = _prefs.getString('analytics_first_open');
    if (firstOpen != null) {
      stats['first_open'] = firstOpen;
      final firstOpenDate = DateTime.parse(firstOpen);
      final daysSinceFirstOpen = DateTime.now().difference(firstOpenDate).inDays;
      stats['days_since_first_open'] = daysSinceFirstOpen;
    }

    // Última apertura
    final lastOpen = _prefs.getString('analytics_last_open');
    if (lastOpen != null) {
      stats['last_open'] = lastOpen;
    }

    // Total de eventos
    final events = await getEvents();
    stats['total_events'] = events.length;

    return stats;
  }

  /// Obtener la feature más usada
  Future<String> getMostUsedFeature() async {
    final stats = await getUsageStats();
    
    final features = {
      'Transacciones': stats['transactions_created'] ?? 0,
      'Eventos Compartidos': stats['eventos_compartidos_created'] ?? 0,
      'Gráficos': stats['graficos_views'] ?? 0,
      'Informes': stats['informes_views'] ?? 0,
      'Gastos Fijos': stats['gastos_fijos_views'] ?? 0,
      'Recomendaciones': stats['recomendaciones_views'] ?? 0,
    };

    var maxFeature = 'Transacciones';
    var maxCount = 0;

    features.forEach((feature, count) {
      if (count > maxCount) {
        maxCount = count;
        maxFeature = feature;
      }
    });

    return maxFeature;
  }

  /// Registrar apertura de app
  Future<void> trackAppOpen() async {
    if (!_initialized) await initialize();

    await trackEvent(eventAppOpened);

    // Registrar primera apertura si no existe
    final firstOpen = _prefs.getString('analytics_first_open');
    if (firstOpen == null) {
      await _prefs.setString('analytics_first_open', DateTime.now().toIso8601String());
    }

    // Actualizar última apertura
    await _prefs.setString('analytics_last_open', DateTime.now().toIso8601String());
  }

  /// Limpiar datos de analytics (solo para desarrollo)
  Future<void> clearAnalytics() async {
    if (!_initialized) await initialize();
    
    await _prefs.remove('analytics_events');
    
    // Limpiar todos los contadores
    final keys = _prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith('analytics_count_')) {
        await _prefs.remove(key);
      }
    }
    
    print('[ANALYTICS] Analytics data cleared');
  }

  /// Obtener eventos de los últimos N días
  Future<List<Map<String, dynamic>>> getRecentEvents(int days) async {
    final allEvents = await getEvents();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    return allEvents.where((event) {
      final timestamp = DateTime.parse(event['timestamp']);
      return timestamp.isAfter(cutoffDate);
    }).toList();
  }

  /// Obtener eventos por nombre
  Future<List<Map<String, dynamic>>> getEventsByName(String eventName) async {
    final allEvents = await getEvents();
    return allEvents.where((event) => event['event'] == eventName).toList();
  }

  /// Obtener tasa de conversión a Premium (si hay analytics de compra)
  Future<double> getPremiumConversionRate() async {
    final appOpens = await getEventCount(eventAppOpened);
    final premiumViews = await getEventCount(eventPremiumScreenViewed);
    
    if (appOpens == 0) return 0.0;
    return (premiumViews / appOpens) * 100;
  }
}

/// Pantalla para mostrar estadísticas de analytics (solo para desarrollo/admin)
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _analytics = AnalyticsService();
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final stats = await _analytics.getUsageStats();
    final mostUsed = await _analytics.getMostUsedFeature();
    final conversionRate = await _analytics.getPremiumConversionRate();
    
    stats['most_used_feature'] = mostUsed;
    stats['premium_conversion_rate'] = conversionRate;
    
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Limpiar Analytics'),
                  content: const Text('¿Estás seguro de borrar todos los datos de analytics?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Borrar'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await _analytics.clearAnalytics();
                _loadStats();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Analytics limpiado')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCard(
                  title: 'Resumen General',
                  icon: Icons.analytics,
                  color: const Color(0xFF0EA5A4),
                  children: [
                    _buildStatRow('Aperturas de app', _stats['app_opened'] ?? 0),
                    _buildStatRow('Total de eventos', _stats['total_events'] ?? 0),
                    _buildStatRow('Días de uso', _stats['days_since_first_open'] ?? 0),
                    if (_stats['first_open'] != null)
                      _buildStatRow('Primera apertura', _formatDate(_stats['first_open'])),
                    if (_stats['most_used_feature'] != null)
                      _buildStatRow('Feature más usada', _stats['most_used_feature']),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'Uso de Features',
                  icon: Icons.dashboard,
                  color: const Color(0xFF22C55E),
                  children: [
                    _buildStatRow('Transacciones creadas', _stats['transactions_created'] ?? 0),
                    _buildStatRow('Eventos compartidos', _stats['eventos_compartidos_created'] ?? 0),
                    _buildStatRow('Vistas de gráficos', _stats['graficos_views'] ?? 0),
                    _buildStatRow('Vistas de informes', _stats['informes_views'] ?? 0),
                    _buildStatRow('Gastos fijos', _stats['gastos_fijos_views'] ?? 0),
                    _buildStatRow('Recomendaciones', _stats['recomendaciones_views'] ?? 0),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'Conversión Premium',
                  icon: Icons.workspace_premium,
                  color: const Color(0xFFF59E0B),
                  children: [
                    _buildStatRow('Vistas de Premium', _stats['premium_screen_views'] ?? 0),
                    _buildStatRow(
                      'Tasa de conversión',
                      '${(_stats['premium_conversion_rate'] ?? 0).toStringAsFixed(2)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'Otras Acciones',
                  icon: Icons.more_horiz,
                  color: const Color(0xFF6366F1),
                  children: [
                    _buildStatRow('Exportaciones', _stats['exports'] ?? 0),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }
}
