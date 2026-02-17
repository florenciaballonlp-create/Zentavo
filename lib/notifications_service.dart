import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Servicio de notificaciones locales (versión simplificada)
class NotificationsService {
  static final NotificationsService _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  bool _initialized = false;

  /// IDs de notificaciones predefinidas
  static const int dailyReminderNotificationId = 1;
  static const int budgetAlertNotificationId = 2;
  static const int weeklyReportNotificationId = 3;
  static const int monthlyReportNotificationId = 4;
  static const int eventoCompartidoNotificationId = 5;

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    print('[NOTIFICATIONS] Initialized (simplified)');
  }

  /// Solicitar permisos de notificación
  Future<bool> requestPermissions() async {
    return true;
  }

  /// Verificar si las notificaciones están habilitadas
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }

  /// Habilitar/deshabilitar notificaciones
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    print('[NOTIFICATIONS] Notifications ${enabled ? "enabled" : "disabled"}');
  }

  /// Mostrar notificación inmediata (stub)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('[NOTIFICATIONS] Would show: $title - $body');
  }

  /// Programar recordatorio diario
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await initialize();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_reminder_hour', hour);
    await prefs.setInt('daily_reminder_minute', minute);
    print('[NOTIFICATIONS] Daily reminder scheduled at $hour:$minute');
  }

  /// Cancelar recordatorio diario
  Future<void> cancelDailyReminder() async {
    print('[NOTIFICATIONS] Daily reminder cancelled');
  }

  /// Programar informe semanal
  Future<void> scheduleWeeklyReport({
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    print('[NOTIFICATIONS] Weekly report scheduled');
  }

  /// Programar informe mensual
  Future<void> scheduleMonthlyReport({
    required int day,
    required int hour,
    required int minute,
  }) async {
    print('[NOTIFICATIONS] Monthly report scheduled');
  }

  /// Alerta de presupuesto excedido
  Future<void> showBudgetAlert({
    required String category,
    required double percentage,
  }) async {
    await showNotification(
      id: budgetAlertNotificationId,
      title: '⚠️ Alerta de Presupuesto',
      body: 'Has gastado el ${percentage.toStringAsFixed(0)}% de tu presupuesto en $category',
      payload: 'budget_alert',
    );
  }

  /// Notificación de evento compartido
  Future<void> showEventoCompartidoNotification({
    required String eventName,
    required String message,
  }) async {
    await showNotification(
      id: eventoCompartidoNotificationId,
      title: '🎉 $eventName',
      body: message,
      payload: 'evento_compartido',
    );
  }

  /// Programar todas las notificaciones configuradas
  Future<void> scheduleAllNotifications() async {
    print('[NOTIFICATIONS] All notifications scheduled');
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    print('[NOTIFICATIONS] All notifications cancelled');
  }
}

/// Pantalla de configuración de notificaciones
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  final _notificationsService = NotificationsService();
  bool _notificationsEnabled = false;
  bool _dailyReminderEnabled = false;
  bool _weeklyReportEnabled = false;
  bool _monthlyReportEnabled = false;
  bool _budgetAlertsEnabled = false;
  bool _emailNewsletterEnabled = false;
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final enabled = await _notificationsService.areNotificationsEnabled();
    final dailyHour = prefs.getInt('daily_reminder_hour') ?? 20;
    final dailyMinute = prefs.getInt('daily_reminder_minute') ?? 0;
    
    setState(() {
      _notificationsEnabled = enabled;
      _dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? false;
      _weeklyReportEnabled = prefs.getBool('weekly_report_enabled') ?? false;
      _monthlyReportEnabled = prefs.getBool('monthly_report_enabled') ?? false;
      _budgetAlertsEnabled = prefs.getBool('budget_alerts_enabled') ?? true;
      _emailNewsletterEnabled = prefs.getBool('email_newsletter_enabled') ?? false;
      _dailyReminderTime = TimeOfDay(hour: dailyHour, minute: dailyMinute);
      _loading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    await _notificationsService.setNotificationsEnabled(value);
    setState(() => _notificationsEnabled = value);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Notific aciones activadas' : 'Notificaciones desactivadas'),
        ),
      );
    }
  }

  Future<void> _toggleDailyReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', value);
    
    if (value) {
      await _notificationsService.scheduleDailyReminder(
        hour: _dailyReminderTime.hour,
        minute: _dailyReminderTime.minute,
      );
    } else {
      await _notificationsService.cancelDailyReminder();
    }
    
    setState(() => _dailyReminderEnabled = value);
  }

  Future<void> _selectDailyReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dailyReminderTime,
    );
    
    if (time != null) {
      setState(() => _dailyReminderTime = time);
      
      if (_dailyReminderEnabled) {
        await _notificationsService.scheduleDailyReminder(
          hour: time.hour,
          minute: time.minute,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Las notificaciones push están en desarrollo. Por ahora puedes configurar tus preferencias.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Habilitar Notificaciones'),
                  subtitle: const Text('Recibe recordatorios y alertas'),
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: const Color(0xFF0EA5A4),
                ),
                const Divider(),
                
                if (_notificationsEnabled) ...[
                  ListTile(
                    leading: const Icon(Icons.alarm, color: Color(0xFF0EA5A4)),
                    title: const Text('Recordatorio Diario'),
                    subtitle: Text(
                      _dailyReminderEnabled
                          ? 'Todos los días a las ${_dailyReminderTime.format(context)}'
                          : 'Desactivado',
                    ),
                    trailing: Switch(
                      value: _dailyReminderEnabled,
                      onChanged: _toggleDailyReminder,
                      activeColor: const Color(0xFF0EA5A4),
                    ),
                  ),
                  
                  if (_dailyReminderEnabled)
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 72, right: 16),
                      title: const Text('Hora del recordatorio'),
                      trailing: TextButton(
                        onPressed: _selectDailyReminderTime,
                        child: Text(
                          _dailyReminderTime.format(context),
                          style: const TextStyle(color: Color(0xFF0EA5A4)),
                        ),
                      ),
                    ),
                  
                  const Divider(),
                  
                  SwitchListTile(
                    secondary: const Icon(Icons.calendar_today, color: Color(0xFF0EA5A4)),
                    title: const Text('Informe Semanal'),
                    subtitle: const Text('Domingos a las 20:00'),
                    value: _weeklyReportEnabled,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('weekly_report_enabled', value);
                      if (value) {
                        await _notificationsService.scheduleWeeklyReport(
                          weekday: 7,
                          hour: 20,
                          minute: 0,
                        );
                      }
                      setState(() => _weeklyReportEnabled = value);
                    },
                    activeColor: const Color(0xFF0EA5A4),
                  ),
                  
                  SwitchListTile(
                    secondary: const Icon(Icons.calendar_month, color: Color(0xFF0EA5A4)),
                    title: const Text('Informe Mensual'),
                    subtitle: const Text('Primer día del mes a las 9:00'),
                    value: _monthlyReportEnabled,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('monthly_report_enabled', value);
                      if (value) {
                        await _notificationsService.scheduleMonthlyReport(
                          day: 1,
                          hour: 9,
                          minute: 0,
                        );
                      }
                      setState(() => _monthlyReportEnabled = value);
                    },
                    activeColor: const Color(0xFF0EA5A4),
                  ),
                  
                  const Divider(),
                  
                  SwitchListTile(
                    secondary: const Icon(Icons.warning_amber, color: Color(0xFFF59E0B)),
                    title: const Text('Alertas de Presupuesto'),
                    subtitle: const Text('Avisos cuando gastes más del 80%'),
                    value: _budgetAlertsEnabled,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('budget_alerts_enabled', value);
                      setState(() => _budgetAlertsEnabled = value);
                    },
                    activeColor: const Color(0xFFF59E0B),
                  ),
                  
                  const Divider(),
                ],
                
                // Opción de newsletter disponible siempre (no requiere notificaciones activadas)
                SwitchListTile(
                  secondary: const Icon(Icons.email, color: Color(0xFF0EA5A4)),
                  title: const Text('Novedades por Email'),
                  subtitle: const Text('Recibe actualizaciones y consejos financieros'),
                  value: _emailNewsletterEnabled,
                  onChanged: (value) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('email_newsletter_enabled', value);
                    setState(() => _emailNewsletterEnabled = value);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? '✅ Te suscribiste a las novedades por email'
                                : '❌ Te diste de baja de las novedades',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  activeColor: const Color(0xFF0EA5A4),
                ),
                
                if (_notificationsEnabled) ...[
                  
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _notificationsService.showNotification(
                          id: 999,
                          title: '🎉 Notificación de Prueba',
                          body: 'Las notificaciones están funcionando correctamente',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notificación de prueba enviada (solo en consola por ahora)')),
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Enviar Notificación de Prueba'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5A4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
