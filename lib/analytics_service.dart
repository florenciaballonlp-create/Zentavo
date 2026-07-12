import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'localization.dart';

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
  final AppStrings? strings;

  const AnalyticsScreen({Key? key, this.strings}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _analytics = AnalyticsService();
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  AppStrings get _strings => widget.strings ?? AppStrings();

  String _tr({required String es, String? en, String? pt, String? it}) {
    switch (_strings.language) {
      case AppLanguage.english:
        return en ?? es;
      case AppLanguage.portuguese:
        return pt ?? es;
      case AppLanguage.italian:
        return it ?? es;
      case AppLanguage.chinese:
      case AppLanguage.japanese:
      case AppLanguage.spanish:
        return es;
    }
  }

  String _localizedFeatureName(String feature) {
    switch (feature) {
      case 'Transacciones':
        return _tr(es: 'Transacciones', en: 'Transactions', pt: 'Transações', it: 'Transazioni');
      case 'Eventos Compartidos':
        return _tr(es: 'Eventos Compartidos', en: 'Shared Events', pt: 'Eventos Compartilhados', it: 'Eventi Condivisi');
      case 'Gráficos':
        return _tr(es: 'Gráficos', en: 'Charts', pt: 'Gráficos', it: 'Grafici');
      case 'Informes':
        return _tr(es: 'Informes', en: 'Reports', pt: 'Relatórios', it: 'Report');
      case 'Gastos Fijos':
        return _tr(es: 'Gastos Fijos', en: 'Fixed Expenses', pt: 'Despesas Fixas', it: 'Spese Fisse');
      case 'Recomendaciones':
        return _tr(es: 'Recomendaciones', en: 'Recommendations', pt: 'Recomendações', it: 'Raccomandazioni');
      default:
        return feature;
    }
  }

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
    
    stats['most_used_feature'] = _localizedFeatureName(mostUsed);
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
        title: Text(_tr(es: 'Panel de Analíticas', en: 'Analytics Dashboard', pt: 'Painel de Analytics', it: 'Dashboard Analytics')),
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
                  title: Text(_tr(es: 'Limpiar Analíticas', en: 'Clear Analytics', pt: 'Limpar Analytics', it: 'Cancella Analytics')),
                  content: Text(_tr(es: '¿Estás seguro de borrar todos los datos de analíticas?', en: 'Are you sure you want to delete all analytics data?', pt: 'Tem certeza de que deseja excluir todos os dados de analytics?', it: 'Sei sicuro di voler eliminare tutti i dati analytics?')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(_strings.cancelar),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text(_tr(es: 'Borrar', en: 'Delete', pt: 'Excluir', it: 'Elimina')),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await _analytics.clearAnalytics();
                _loadStats();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_tr(es: 'Analíticas limpiadas', en: 'Analytics cleared', pt: 'Analytics limpo', it: 'Analytics pulito'))),
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
                  title: _tr(es: 'Resumen General', en: 'General Summary', pt: 'Resumo Geral', it: 'Riepilogo Generale'),
                  icon: Icons.analytics,
                  color: const Color(0xFF0EA5A4),
                  children: [
                    _buildStatRow(_tr(es: 'Aperturas de app', en: 'App opens', pt: 'Aberturas do app', it: 'Aperture app'), _stats['app_opened'] ?? 0),
                    _buildStatRow(_tr(es: 'Total de eventos', en: 'Total events', pt: 'Total de eventos', it: 'Eventi totali'), _stats['total_events'] ?? 0),
                    _buildStatRow(_tr(es: 'Días de uso', en: 'Days of use', pt: 'Dias de uso', it: 'Giorni di utilizzo'), _stats['days_since_first_open'] ?? 0),
                    if (_stats['first_open'] != null)
                      _buildStatRow(_tr(es: 'Primera apertura', en: 'First open', pt: 'Primeira abertura', it: 'Prima apertura'), _formatDate(_stats['first_open'])),
                    if (_stats['most_used_feature'] != null)
                      _buildStatRow(_tr(es: 'Función más usada', en: 'Most used feature', pt: 'Recurso mais usado', it: 'Funzione più usata'), _stats['most_used_feature']),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: _tr(es: 'Uso de Funciones', en: 'Feature Usage', pt: 'Uso de Recursos', it: 'Uso Funzioni'),
                  icon: Icons.dashboard,
                  color: const Color(0xFF22C55E),
                  children: [
                    _buildStatRow(_tr(es: 'Transacciones creadas', en: 'Created transactions', pt: 'Transações criadas', it: 'Transazioni create'), _stats['transactions_created'] ?? 0),
                    _buildStatRow(_tr(es: 'Eventos compartidos', en: 'Shared events', pt: 'Eventos compartilhados', it: 'Eventi condivisi'), _stats['eventos_compartidos_created'] ?? 0),
                    _buildStatRow(_tr(es: 'Vistas de gráficos', en: 'Chart views', pt: 'Visualizações de gráficos', it: 'Visualizzazioni grafici'), _stats['graficos_views'] ?? 0),
                    _buildStatRow(_tr(es: 'Vistas de informes', en: 'Report views', pt: 'Visualizações de relatórios', it: 'Visualizzazioni report'), _stats['informes_views'] ?? 0),
                    _buildStatRow(_tr(es: 'Gastos fijos', en: 'Fixed expenses', pt: 'Despesas fixas', it: 'Spese fisse'), _stats['gastos_fijos_views'] ?? 0),
                    _buildStatRow(_tr(es: 'Recomendaciones', en: 'Recommendations', pt: 'Recomendações', it: 'Raccomandazioni'), _stats['recomendaciones_views'] ?? 0),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: _tr(es: 'Conversión Premium', en: 'Premium Conversion', pt: 'Conversão Premium', it: 'Conversione Premium'),
                  icon: Icons.workspace_premium,
                  color: const Color(0xFFF59E0B),
                  children: [
                    _buildStatRow(_tr(es: 'Vistas de Premium', en: 'Premium views', pt: 'Visualizações do Premium', it: 'Visualizzazioni Premium'), _stats['premium_screen_views'] ?? 0),
                    _buildStatRow(
                      _tr(es: 'Tasa de conversión', en: 'Conversion rate', pt: 'Taxa de conversão', it: 'Tasso di conversione'),
                      '${(_stats['premium_conversion_rate'] ?? 0).toStringAsFixed(2)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: _tr(es: 'Otras Acciones', en: 'Other Actions', pt: 'Outras Ações', it: 'Altre Azioni'),
                  icon: Icons.more_horiz,
                  color: const Color(0xFF6366F1),
                  children: [
                    _buildStatRow(_tr(es: 'Exportaciones', en: 'Exports', pt: 'Exportações', it: 'Esportazioni'), _stats['exports'] ?? 0),
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
