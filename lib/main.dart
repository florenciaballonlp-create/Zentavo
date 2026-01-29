import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'export_utils.dart';
import 'localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_auth/local_auth.dart';
import 'splash_screen.dart';

void main() => runApp(const ExpenseApp());

class ExpenseApp extends StatefulWidget {
  const ExpenseApp({super.key});

  @override
  State<ExpenseApp> createState() => _ExpenseAppState();
}

class _ExpenseAppState extends State<ExpenseApp> {
  late Future<ThemeMode> _themeModeFuture;

  @override
  void initState() {
    super.initState();
    _themeModeFuture = _loadThemeMode();
  }

  Future<ThemeMode> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode') ?? 'system';
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
    }
    await prefs.setString('themeMode', modeString);
    setState(() {
      _themeModeFuture = _loadThemeMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeMode>(
      future: _themeModeFuture,
      builder: (context, snapshot) {
        final themeMode = snapshot.data ?? ThemeMode.system;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Zentavo',
          themeMode: themeMode,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF10B981),
            useMaterial3: true,
            brightness: Brightness.light,
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xFF10B981),
            useMaterial3: true,
            brightness: Brightness.dark,
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              color: const Color(0xFF1E1E1E),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          home: SplashScreen(
            nextScreen: HomePage(onThemeModeChanged: _setThemeMode),
          ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final Function(ThemeMode)? onThemeModeChanged;

  const HomePage({super.key, this.onThemeModeChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Lista de transacciones dinámica
  final List<Map<String, dynamic>> _transacciones = [];

  // Controladores para leer lo que escribes en el formulario
  final _tituloController = TextEditingController();
  final _montoController = TextEditingController();
  final _justificacionController = TextEditingController();
  final _ahorroController = TextEditingController();

  final FocusNode _tituloFocus = FocusNode();
  final FocusNode _montoFocus = FocusNode();
  final FocusNode _justificacionFocus = FocusNode();
  
  late String _tipoSeleccionado;
  late String _categoriaSeleccionada;
  late SharedPreferences _prefs;
  late AppLanguage _appLanguage = AppLanguage.spanish;
  late AppCurrency _appCurrency = AppCurrency.usd;
  late AppStrings _strings = AppStrings(language: AppLanguage.spanish);
  late String _currentThemeMode = 'system';
  
  // Control de mes seleccionado
  late DateTime _mesSeleccionado;
  
  // Presupuesto mensual
  double _presupuestoMensual = 0;
  bool _notificacionEnviada = false;
  late FlutterLocalNotificationsPlugin _notificaciones;
  
  // Control de ahorros
  List<Map<String, dynamic>> _registrosAhorros = [];
  late TabController _tabController;

  // Biometría
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _authChecked = false;

  // Control de gastos fijos
  List<Map<String, dynamic>> _gastosFijos = [];
  final _nombreGastoController = TextEditingController();
  final _montoGastoFijoController = TextEditingController();
  late int _diaVencimientoSeleccionado;

  // Mapa de categorías con iconos
  static const Map<String, String> _categorias = {
    'Comida': '🍔',
    'Transporte': '🚗',
    'Diversión': '🎮',
    'Salud': '🏥',
    'Servicios': '💡',
    'Utilidades': '📱',
    'Vivienda': '🏠',
    'Educación': '📚',
    'Otro': '❓',
  };

  Future<void> _autenticarConBiometria() async {
    if (kIsWeb) {
      setState(() {
        _isAuthenticated = true;
        _authChecked = true;
      });
      return;
    }

    bool supported = false;
    bool canCheck = false;
    try {
      supported = await _localAuth.isDeviceSupported();
    } catch (_) {}
    try {
      canCheck = await _localAuth.canCheckBiometrics;
    } catch (_) {}

    if (!supported && !canCheck) {
      setState(() {
        _isAuthenticated = true;
        _authChecked = true;
      });
      return;
    }

    bool success = false;
    try {
      success = await _localAuth.authenticate(
        localizedReason: 'Verifica tu identidad con biometría o código del dispositivo',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isAuthenticated = success;
        _authChecked = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _autenticarConBiometria();
    _mesSeleccionado = DateTime(DateTime.now().year, DateTime.now().month);
    _diaVencimientoSeleccionado = 1;
    _inicializarNotificaciones();
    _cargarTransacciones();
    _verificarYEnviarRecordatorios();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _montoController.dispose();
    _justificacionController.dispose();
    _ahorroController.dispose();
    _nombreGastoController.dispose();
    _montoGastoFijoController.dispose();
    _tituloFocus.dispose();
    _montoFocus.dispose();
    _justificacionFocus.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarTransacciones() async {
    _prefs = await SharedPreferences.getInstance();
    final String? datosGuardados = _prefs.getString('transacciones');
    
    // Cargar idioma y moneda
    final String languageCode = _prefs.getString('app_language') ?? 'spanish';
    _appLanguage = AppLanguage.values.firstWhere(
      (lang) => lang.toString().split('.').last == languageCode,
      orElse: () => AppLanguage.spanish,
    );
    
    final String currencyCode = _prefs.getString('app_currency') ?? 'usd';
    _appCurrency = AppCurrency.values.firstWhere(
      (curr) => curr.toString().split('.').last == currencyCode,
      orElse: () => AppCurrency.usd,
    );
    
    _strings = AppStrings(language: _appLanguage);
    
    // Cargar tema actual
    final themeModeString = _prefs.getString('themeMode') ?? 'system';
    _currentThemeMode = themeModeString;
    
    // Cargar presupuesto mensual
    _presupuestoMensual = _prefs.getDouble('presupuesto_mensual') ?? 0.0;
    _notificacionEnviada = false;
    
    // Cargar registros de ahorros
    final String? ahorrosGuardados = _prefs.getString('ahorros_historicos');
    if (ahorrosGuardados != null) {
      try {
        final List<dynamic> decoded = jsonDecode(ahorrosGuardados);
        setState(() {
          _registrosAhorros = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      } catch (e) {
        print('Error al cargar ahorros: $e');
      }
    }

    // Cargar gastos fijos
    final String? gastosFijosGuardados = _prefs.getString('gastos_fijos');
    if (gastosFijosGuardados != null) {
      try {
        final List<dynamic> decoded = jsonDecode(gastosFijosGuardados);
        setState(() {
          _gastosFijos = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      } catch (e) {
        print('Error al cargar gastos fijos: $e');
      }
    }
    
    if (datosGuardados != null) {
      try {
        final List<dynamic> decoded = jsonDecode(datosGuardados);
        setState(() {
          _transacciones.clear();
          _transacciones.addAll(
            decoded.map((item) => Map<String, dynamic>.from(item)).toList(),
          );
        });
        _verificarPresupuesto();
      } catch (e) {
        print('Error al cargar transacciones: $e');
      }
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(_strings.temaDialogo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(_strings.seguirSistema),
                secondary: const Icon(Icons.brightness_auto),
                value: 'system',
                groupValue: _currentThemeMode,
                onChanged: (v) async {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentThemeMode = 'system';
                  });
                  if (widget.onThemeModeChanged != null) {
                    widget.onThemeModeChanged!(ThemeMode.system);
                  }
                },
              ),
              RadioListTile<String>(
                title: Text(_strings.modoClaro),
                secondary: const Icon(Icons.light_mode),
                value: 'light',
                groupValue: _currentThemeMode,
                onChanged: (v) async {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentThemeMode = 'light';
                  });
                  if (widget.onThemeModeChanged != null) {
                    widget.onThemeModeChanged!(ThemeMode.light);
                  }
                },
              ),
              RadioListTile<String>(
                title: Text(_strings.modoOscuro),
                secondary: const Icon(Icons.dark_mode),
                value: 'dark',
                groupValue: _currentThemeMode,
                onChanged: (v) async {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentThemeMode = 'dark';
                  });
                  if (widget.onThemeModeChanged != null) {
                    widget.onThemeModeChanged!(ThemeMode.dark);
                  }
                },
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(_strings.cerrar))],
        );
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(_strings.idiomaTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<AppLanguage>(
                title: const Text('Español'),
                secondary: const Text('🇪🇸'),
                value: AppLanguage.spanish,
                groupValue: _appLanguage,
                onChanged: (v) async {
                  Navigator.of(context).pop();
                  if (v != null) {
                    await _prefs.setString('app_language', v.toString().split('.').last);
                    setState(() {
                      _appLanguage = v;
                      _strings = AppStrings(language: _appLanguage);
                    });
                  }
                },
              ),
              RadioListTile<AppLanguage>(
                title: const Text('English'),
                secondary: const Text('🇺🇸'),
                value: AppLanguage.english,
                groupValue: _appLanguage,
                onChanged: (v) async {
                  Navigator.of(context).pop();
                  if (v != null) {
                    await _prefs.setString('app_language', v.toString().split('.').last);
                    setState(() {
                      _appLanguage = v;
                      _strings = AppStrings(language: _appLanguage);
                    });
                  }
                },
              ),
              RadioListTile<AppLanguage>(
                title: const Text('Português'),
                secondary: const Text('🇧🇷'),
                value: AppLanguage.portuguese,
                groupValue: _appLanguage,
                onChanged: (v) async {
                  Navigator.of(context).pop();
                  if (v != null) {
                    await _prefs.setString('app_language', v.toString().split('.').last);
                    setState(() {
                      _appLanguage = v;
                      _strings = AppStrings(language: _appLanguage);
                    });
                  }
                },
              ),
              RadioListTile<AppLanguage>(
                title: const Text('Italiano'),
                secondary: const Text('🇮🇹'),
                value: AppLanguage.italian,
                groupValue: _appLanguage,
                onChanged: (v) async {
                  Navigator.of(context).pop();
                  if (v != null) {
                    await _prefs.setString('app_language', v.toString().split('.').last);
                    setState(() {
                      _appLanguage = v;
                      _strings = AppStrings(language: _appLanguage);
                    });
                  }
                },
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(_strings.cerrar))],
        );
      },
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(_strings.monedaTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppCurrency.values.length,
              itemBuilder: (ctx, idx) {
                final currency = AppCurrency.values[idx];
                return RadioListTile<AppCurrency>(
                  title: Text(currency.name),
                  value: currency,
                  groupValue: _appCurrency,
                  onChanged: (v) async {
                    Navigator.of(context).pop();
                    if (v != null) {
                      await _prefs.setString('app_currency', v.toString().split('.').last);
                      setState(() {
                        _appCurrency = v;
                      });
                    }
                  },
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(_strings.cerrar))],
        );
      },
    );
  }

  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(_strings.configuracion),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book),
                title: const Text('Manual de uso'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _showManualScreen();
                },
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: Text(_strings.tema),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _showThemeDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(_strings.idioma),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _showLanguageDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.currency_exchange),
                title: Text(_strings.moneda),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _showCurrencyDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Compartir App'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _compartirApp();
                },
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(_strings.cerrar))],
        );
      },
    );
  }

  void _compartirApp() {
    final String mensaje = '''
🌟 ¡Descubre Zentavo! 🌟

Una app completa para controlar tus gastos y ahorros:

✅ Registra ingresos y egresos fácilmente
💰 Presupuesto mensual con alertas
📊 Gráficos y reportes detallados
💳 Control de gastos fijos
🔐 Protección con biometría
📈 Seguimiento automático de ahorros
📄 Exporta en PDF, Excel, CSV y más

¡Toma el control de tus finanzas hoy!
''';
    
    Share.share(mensaje, subject: 'Zentavo - Control de Gastos');
  }

  void _showManualScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManualScreen(strings: _strings),
      ),
    );
  }

  void _inicializarNotificaciones() {
    _notificaciones = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    _notificaciones.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    ).then((_) {
      print('Notificaciones inicializadas correctamente');
    }).catchError((e) {
      print('Error al inicializar notificaciones: $e');
    });
  }

  void _verificarPresupuesto() {
    if (_presupuestoMensual <= 0) return;

    final DateTime ahora = DateTime.now();
    final List<Map<String, dynamic>> egresosDelMes = _transacciones
        .where((t) {
          final String? fechaStr = t['fecha'];
          if (fechaStr == null) return false;
          final DateTime fechaTransaccion = DateTime.parse(fechaStr);
          return t['tipo'] == 'egreso' &&
              fechaTransaccion.year == ahora.year &&
              fechaTransaccion.month == ahora.month;
        })
        .toList();

    double totalEgresos = 0;
    for (var egreso in egresosDelMes) {
      totalEgresos += (egreso['monto'] as num).toDouble();
    }

    if (totalEgresos > _presupuestoMensual && !_notificacionEnviada) {
      _notificacionEnviada = true;
      final double excedente = totalEgresos - _presupuestoMensual;
      _enviarNotificacion(excedente);
    } else if (totalEgresos <= _presupuestoMensual) {
      _notificacionEnviada = false;
    }
  }

  Future<void> _enviarNotificacion(double excedente) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'presupuesto_channel',
      'Presupuesto',
      channelDescription: 'Notificaciones de presupuesto excedido',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    final String mensaje = _strings.presupuestoExcedidoMsg(
      _appCurrency.formatAmount(excedente),
    );

    try {
      await _notificaciones.show(
        id: 0,
        title: _strings.presupuestoExcedido,
        body: mensaje,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      print('Error al enviar notificación: $e');
    }
  }

  void _showPresupuestoDialog() {
    final TextEditingController presupuestoController =
        TextEditingController(text: _presupuestoMensual.toString());

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(_strings.definirPresupuesto),
          content: TextField(
            controller: presupuestoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _strings.montoPresupuesto,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_strings.cerrar),
            ),
            ElevatedButton(
              onPressed: () {
                final double nuevoPresupuesto =
                    double.tryParse(presupuestoController.text) ?? 0;
                _setPresupuesto(nuevoPresupuesto);
                Navigator.of(context).pop();
              },
              child: Text(_strings.presupuestoOk),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setPresupuesto(double monto) async {
    setState(() {
      _presupuestoMensual = monto;
      _notificacionEnviada = false;
    });
    await _prefs.setDouble('presupuesto_mensual', monto);
    _verificarPresupuesto();
  }

  void _showReportesDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Reportes'),
          content: const Text('Selecciona el formato de reporte'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_strings.cerrar),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(_strings.reportePDF),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final transaccionesMes = _obtenerTransaccionesMes();
                  final pdfBytes = await exportMonthlyReportPdf(
                    month: _mesSeleccionado,
                    transactions: transaccionesMes,
                    ingresos: _calcularIngresos(),
                    egresos: _calcularEgresos(),
                  );
                  
                  final dir = await getTemporaryDirectory();
                  final monthStr = '${_mesSeleccionado.month.toString().padLeft(2, '0')}-${_mesSeleccionado.year}';
                  final filePath = p.join(dir.path, 'Reporte_$monthStr.pdf');
                  final file = File(filePath);
                  await file.writeAsBytes(pdfBytes);
                  
                  await Share.shareXFiles([XFile(file.path)], text: 'Reporte Mensual $monthStr');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_strings.generandoReporte)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al generar PDF: $e')),
                  );
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.table_chart),
              label: Text(_strings.reporteExcel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final transaccionesMes = _obtenerTransaccionesMes();
                  final excelBytes = await exportMonthlyReportExcel(
                    month: _mesSeleccionado,
                    transactions: transaccionesMes,
                    ingresos: _calcularIngresos(),
                    egresos: _calcularEgresos(),
                  );
                  
                  final dir = await getTemporaryDirectory();
                  final monthStr = '${_mesSeleccionado.month.toString().padLeft(2, '0')}-${_mesSeleccionado.year}';
                  final filePath = p.join(dir.path, 'Reporte_$monthStr.xlsx');
                  final file = File(filePath);
                  await file.writeAsBytes(excelBytes);
                  
                  await Share.shareXFiles([XFile(file.path)], text: 'Reporte Mensual $monthStr');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_strings.generandoReporte)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al generar Excel: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Color _getBalanceCardColor(double balance, List<Map<String, dynamic>> egresosDelMes) {
    if (_presupuestoMensual > 0) {
      double totalEgresos = 0;
      for (var egreso in egresosDelMes) {
        totalEgresos += (egreso['monto'] as num).toDouble();
      }
      if (totalEgresos > _presupuestoMensual) {
        return const Color(0xFFFFEBEE); // Rojo muy claro si se excede presupuesto
      }
    }
    return balance >= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
  }

  Color _getBalanceTextColor(double balance, List<Map<String, dynamic>> egresosDelMes) {
    if (_presupuestoMensual > 0) {
      double totalEgresos = 0;
      for (var egreso in egresosDelMes) {
        totalEgresos += (egreso['monto'] as num).toDouble();
      }
      if (totalEgresos > _presupuestoMensual) {
        return const Color(0xFFC62828); // Rojo intenso si se excede presupuesto
      }
    }
    return balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);
  }

  // Obtener egresos del mes seleccionado
  double _calcularEgresosMesSeleccionado() {
    return _obtenerTransaccionesMes()
        .where((t) => t['tipo'] == 'Egreso')
        .fold(0, (sum, item) => sum + (item['monto'].abs() as double));
  }

  // Obtener color de la barra de progreso según el porcentaje gastado
  Color _getProgressBarColor(double porcentajeGastado) {
    if (porcentajeGastado <= 50) {
      return const Color(0xFF10B981); // Verde
    } else if (porcentajeGastado <= 85) {
      return const Color(0xFFF59E0B); // Naranja
    } else {
      return const Color(0xFFEF4444); // Rojo
    }
  }

  // Métodos para ahorros - calcula balance automáticamente por mes
  Future<void> _guardarRegistroAhorros() async {
    try {
      final String datosJSON = jsonEncode(_registrosAhorros);
      await _prefs.setString('ahorros_historicos', datosJSON);
    } catch (e) {
      print('Error al guardar ahorros: $e');
    }
  }

  void _actualizarAhorrosDelMes() {
    // Calcular balance del mes seleccionado
    double ingresos = 0;
    double egresos = 0;

    for (var t in _transacciones) {
      final fechaStr = t['fecha'];
      if (fechaStr != null) {
        try {
          final fecha = DateTime.parse(fechaStr);
          if (fecha.year == _mesSeleccionado.year && fecha.month == _mesSeleccionado.month) {
            if (t['tipo'] == 'Ingreso') {
              ingresos += (t['monto'] as num).toDouble();
            } else {
              egresos += (t['monto'].abs() as num).toDouble();
            }
          }
        } catch (e) {
          print('Error al parsear fecha: $e');
        }
      }
    }

    final balance = ingresos - egresos;
    final mesKey = '${_mesSeleccionado.year}-${_mesSeleccionado.month.toString().padLeft(2, '0')}';

    // Buscar si ya existe un registro para este mes
    final indexExistente = _registrosAhorros.indexWhere((r) => r['mes'] == mesKey);

    if (indexExistente >= 0) {
      // Actualizar registro existente
      setState(() {
        _registrosAhorros[indexExistente] = {
          'mes': mesKey,
          'monto': balance,
          'fecha': DateTime.now().toIso8601String(),
        };
      });
    } else if (balance != 0) {
      // Crear nuevo registro si hay balance
      setState(() {
        _registrosAhorros.add({
          'mes': mesKey,
          'monto': balance,
          'fecha': DateTime.now().toIso8601String(),
        });
      });
    }

    _guardarRegistroAhorros();
  }

  double _calcularAhorrosTotales() {
    return _registrosAhorros.fold(0, (sum, item) => sum + (item['monto'] as num).toDouble());
  }

  DateTime _obtenerFechaAhorro(Map<String, dynamic> ahorro) {
    if (ahorro['fecha'] != null) {
      try {
        return DateTime.parse(ahorro['fecha']);
      } catch (e) {
        return DateTime(1970);
      }
    }
    if (ahorro['mes'] != null) {
      final partes = (ahorro['mes'] as String).split('-');
      final anio = int.tryParse(partes[0]) ?? 1970;
      final mes = int.tryParse(partes[1]) ?? 1;
      return DateTime(anio, mes, 1);
    }
    return DateTime(1970);
  }

  void _registrarExtraccionAhorro(String motivo) {
    final monto = double.tryParse(_ahorroController.text) ?? 0.0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido para extraer')),
      );
      return;
    }

    setState(() {
      _registrosAhorros.add({
        'tipo': 'extraccion',
        'monto': -monto,
        'fecha': DateTime.now().toIso8601String(),
        'nota': motivo,
      });
    });

    _guardarRegistroAhorros();
    _ahorroController.clear();
    Navigator.of(context).pop();
  }

  void _mostrarDialogoExtraccionAhorro() {
    _ahorroController.clear();
    final motivoController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Extracción de ahorro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _ahorroController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto a extraer',
                  border: const OutlineInputBorder(),
                  hintText: '${_appCurrency.symbol}0.00',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_strings.cancelar),
            ),
            ElevatedButton(
              onPressed: () => _registrarExtraccionAhorro(motivoController.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Extraer'),
            ),
          ],
        );
      },
    ).then((_) => motivoController.dispose());
  }

  // ===== MÉTODOS PARA GASTOS FIJOS =====
  
  Future<void> _guardarGastosFijos() async {
    try {
      final String datosJSON = jsonEncode(_gastosFijos);
      await _prefs.setString('gastos_fijos', datosJSON);
    } catch (e) {
      print('Error al guardar gastos fijos: $e');
    }
  }

  void _agregarGastoFijoDesdeEgreso(String nombre, double monto, int diaVencimiento) {
    if (nombre.isEmpty || monto <= 0) return;

    final diaSeguro = diaVencimiento.clamp(1, 31);

    setState(() {
      _gastosFijos.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'nombre': nombre,
        'monto': monto,
        'diaVencimiento': diaSeguro,
        'frecuencia': 'mensual',
        'activo': true,
        'recordatorioActivado': true,
      });
    });

    _guardarGastosFijos();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gasto fijo "$nombre" agregado correctamente')),
    );
  }

  void _agregarGastoFijo() {
    final nombre = _nombreGastoController.text;
    final monto = double.tryParse(_montoGastoFijoController.text) ?? 0.0;
    
    if (nombre.isEmpty || monto <= 0 || _diaVencimientoSeleccionado < 1 || _diaVencimientoSeleccionado > 31) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos correctamente')),
      );
      return;
    }

    setState(() {
      _gastosFijos.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'nombre': nombre,
        'monto': monto,
        'diaVencimiento': _diaVencimientoSeleccionado,
        'frecuencia': 'mensual',
        'activo': true,
        'recordatorioActivado': true,
      });
    });

    _guardarGastosFijos();
    _nombreGastoController.clear();
    _montoGastoFijoController.clear();
    _diaVencimientoSeleccionado = 1;
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gasto fijo "$nombre" agregado correctamente')),
    );
  }

  void _editarGastoFijo(int index) {
    final nombre = _nombreGastoController.text;
    final monto = double.tryParse(_montoGastoFijoController.text) ?? 0.0;
    
    if (nombre.isEmpty || monto <= 0) {
      return;
    }

    setState(() {
      _gastosFijos[index]['nombre'] = nombre;
      _gastosFijos[index]['monto'] = monto;
      _gastosFijos[index]['diaVencimiento'] = _diaVencimientoSeleccionado;
    });

    _guardarGastosFijos();
    _nombreGastoController.clear();
    _montoGastoFijoController.clear();
    _diaVencimientoSeleccionado = 1;
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gasto fijo "$nombre" actualizado')),
    );
  }

  void _eliminarGastoFijo(int index) {
    final nombreEliminado = _gastosFijos[index]['nombre'];
    setState(() {
      _gastosFijos.removeAt(index);
    });
    _guardarGastosFijos();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gasto fijo "$nombreEliminado" eliminado')),
    );
  }

  void _mostrarDialogoGastoFijo({int? index}) {
    _nombreGastoController.clear();
    _montoGastoFijoController.clear();
    _diaVencimientoSeleccionado = 1;

    if (index != null) {
      final gastoFijo = _gastosFijos[index];
      _nombreGastoController.text = gastoFijo['nombre'] ?? '';
      _montoGastoFijoController.text = gastoFijo['monto'].toString();
      _diaVencimientoSeleccionado = gastoFijo['diaVencimiento'] ?? 1;
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(index == null ? 'Nuevo Gasto Fijo' : 'Editar Gasto Fijo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nombreGastoController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre (ej. Alquiler, Internet)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _montoGastoFijoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Día de vencimiento: $_diaVencimientoSeleccionado'),
                        ),
                        Slider(
                          value: _diaVencimientoSeleccionado.toDouble(),
                          min: 1,
                          max: 31,
                          divisions: 30,
                          label: _diaVencimientoSeleccionado.toString(),
                          onChanged: (value) {
                            setState(() {
                              _diaVencimientoSeleccionado = value.toInt();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_strings.cancelar),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (index == null) {
                      _agregarGastoFijo();
                    } else {
                      _editarGastoFijo(index);
                    }
                  },
                  child: Text(index == null ? 'Agregar' : 'Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _verificarYEnviarRecordatorios() async {
    final ahora = DateTime.now();
    
    for (var gastoFijo in _gastosFijos) {
      if (gastoFijo['recordatorioActivado'] != true || gastoFijo['activo'] != true) {
        continue;
      }

      final diaVencimiento = gastoFijo['diaVencimiento'];
      final diaRecordatorio = diaVencimiento - 1; // Un día antes

      // Si es el día del recordatorio
      if (ahora.day == diaRecordatorio || (diaRecordatorio < 1 && ahora.day == DateTime(ahora.year, ahora.month + 1, 0).day)) {
        await _enviarRecordatorioGasto(gastoFijo);
      }
    }
  }

  Future<void> _enviarRecordatorioGasto(Map<String, dynamic> gastoFijo) async {
    try {
      final nombre = gastoFijo['nombre'] ?? 'Gasto';
      final monto = _appCurrency.formatAmount(gastoFijo['monto'] as double);
      final diaVencimiento = gastoFijo['diaVencimiento'];

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'gastos_fijos_channel',
        'Recordatorio de Gastos Fijos',
        channelDescription: 'Notificaciones de gastos fijos próximos a vencer',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notificaciones.show(
        id: gastoFijo['id'].hashCode % 100000,
        title: '⏰ Recordatorio de Gasto Fijo',
        body: '$nombre vence el día $diaVencimiento - Monto: $monto',
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      print('Error al enviar recordatorio de gasto fijo: $e');
    }
  }

  Future<void> _guardarTransacciones() async {
    try {
      // Asegurarse de que _prefs está inicializado
      if (!_isPrefsInitialized()) {
        _prefs = await SharedPreferences.getInstance();
      }
      final String datosJSON = jsonEncode(_transacciones);
      await _prefs.setString('transacciones', datosJSON);
    } catch (e) {
      print('Error al guardar transacciones: $e');
    }
  }

  bool _isPrefsInitialized() {
    try {
      _prefs.containsKey('test');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtener transacciones filtradas por mes
  List<Map<String, dynamic>> _obtenerTransaccionesMes() {
    return _transacciones.where((t) {
      DateTime? fecha;
      if (t['fecha'] != null) {
        try {
          fecha = DateTime.parse(t['fecha']);
        } catch (e) {
          // Si no hay fecha válida, usar fecha actual
          fecha = DateTime.now();
        }
      } else {
        // Asignar fecha actual si no existe
        fecha = DateTime.now();
      }
      return fecha.year == _mesSeleccionado.year && fecha.month == _mesSeleccionado.month;
    }).toList();
  }

  // Obtener nombre del mes en español
  String _obtenerNombreMes(DateTime fecha) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  double _calcularIngresos() {
    return _obtenerTransaccionesMes()
        .where((t) => t['tipo'] == 'Ingreso')
        .fold(0, (sum, item) => sum + item['monto']);
  }

  double _calcularEgresos() {
    return _obtenerTransaccionesMes()
        .where((t) => t['tipo'] == 'Egreso')
        .fold(0, (sum, item) => sum + item['monto'].abs());
  }

  List<PieChartSectionData> _obtenerDatosGraficoMensual() {
    final transaccionesMes = _obtenerTransaccionesMes();

    double ingresos = 0;
    Map<String, double> egresosPorCategoria = {};
    for (var t in transaccionesMes) {
      if (t['tipo'] == 'Ingreso') {
        ingresos += (t['monto'] as num).toDouble();
      } else if (t['tipo'] == 'Egreso') {
        final cat = t['categoria'] ?? 'Otro';
        egresosPorCategoria[cat] = (egresosPorCategoria[cat] ?? 0) + (t['monto'].abs() as num).toDouble();
      }
    }

    final totalEgresos = egresosPorCategoria.values.fold(0.0, (sum, v) => sum + v);
    final total = ingresos + totalEgresos;

    if (total == 0) {
      return [
        PieChartSectionData(
          value: 100,
          color: Colors.grey[300],
          title: 'Sin datos',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ];
    }

    final List<PieChartSectionData> sections = [];
    if (ingresos > 0) {
      sections.add(
        PieChartSectionData(
          value: ingresos,
          color: Colors.green,
          title: 'Ingresos\n${_appCurrency.formatAmount(ingresos)}',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    int colorIndex = 0;
    egresosPorCategoria.forEach((cat, value) {
      final color = _coloresCategorias[colorIndex % _coloresCategorias.length];
      colorIndex++;
      final emoji = _categorias[cat] ?? '❓';
      sections.add(
        PieChartSectionData(
          value: value,
          color: color,
          title: '$emoji\n${_appCurrency.formatAmount(value)}',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    });

    return sections;
  }

  List<PieChartSectionData> _obtenerDatosGraficoAnual() {
    final transaccionesAnio = _transacciones.where((t) {
      if (t['fecha'] == null) return false;
      try {
        final fecha = DateTime.parse(t['fecha']);
        return fecha.year == _mesSeleccionado.year;
      } catch (e) {
        return false;
      }
    }).toList();

    double ingresos = 0;
    Map<String, double> egresosPorCategoria = {};
    for (var t in transaccionesAnio) {
      if (t['tipo'] == 'Ingreso') {
        ingresos += (t['monto'] as num).toDouble();
      } else if (t['tipo'] == 'Egreso') {
        final cat = t['categoria'] ?? 'Otro';
        egresosPorCategoria[cat] = (egresosPorCategoria[cat] ?? 0) + (t['monto'].abs() as num).toDouble();
      }
    }

    final totalEgresos = egresosPorCategoria.values.fold(0.0, (sum, v) => sum + v);
    final total = ingresos + totalEgresos;

    if (total == 0) {
      return [
        PieChartSectionData(
          value: 100,
          color: Colors.grey[300],
          title: 'Sin datos',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ];
    }

    final List<PieChartSectionData> sections = [];
    if (ingresos > 0) {
      sections.add(
        PieChartSectionData(
          value: ingresos,
          color: Colors.green,
          title: 'Ingresos\n${_appCurrency.formatAmount(ingresos)}',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    int colorIndex = 0;
    egresosPorCategoria.forEach((cat, value) {
      final color = _coloresCategorias[colorIndex % _coloresCategorias.length];
      colorIndex++;
      final emoji = _categorias[cat] ?? '❓';
      sections.add(
        PieChartSectionData(
          value: value,
          color: color,
          title: '$emoji\n${_appCurrency.formatAmount(value)}',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    });

    return sections;
  }

  // Paleta de colores para categorías
  static const List<Color> _coloresCategorias = [
    Color(0xFFEF4444), // Rojo
    Color(0xFFFF9500), // Naranja
    Color(0xFFEAB308), // Amarillo
    Color(0xFF22C55E), // Verde
    Color(0xFF06B6D4), // Cian
    Color(0xFF3B82F6), // Azul
    Color(0xFF8B5CF6), // Púrpura
    Color(0xFFEC4899), // Rosa
    Color(0xFF6B7280), // Gris
  ];

  List<PieChartSectionData> _obtenerDatosEgresosPorCategoria() {
    // Agrupar egresos por categoría (del mes seleccionado)
    Map<String, double> egresosPorCategoria = {};
    for (var t in _obtenerTransaccionesMes()) {
      if (t['tipo'] == 'Egreso') {
        String cat = t['categoria'] ?? 'Otro';
        egresosPorCategoria[cat] = (egresosPorCategoria[cat] ?? 0) + (t['monto'].abs() as double);
      }
    }

    if (egresosPorCategoria.isEmpty) {
      return [
        PieChartSectionData(
          value: 100,
          color: Colors.grey[300],
          title: 'Sin gastos',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ];
    }

    int colorIndex = 0;
    return egresosPorCategoria.entries.map((entry) {
      final color = _coloresCategorias[colorIndex % _coloresCategorias.length];
      colorIndex++;
      final emoji = _categorias[entry.key] ?? '❓';
      return PieChartSectionData(
        value: entry.value,
        color: color,
        title: '$emoji\n\$${entry.value.toStringAsFixed(2)}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  void _agregarNuevaTransaccion() {
    final nombre = _tituloController.text;
    final monto = double.tryParse(_montoController.text) ?? 0.0;
    final razon = _justificacionController.text;

    if (nombre.isEmpty || monto <= 0) return;

    setState(() {
      _transacciones.add({
        'titulo': nombre,
        'monto': _tipoSeleccionado == 'Ingreso' ? monto : -monto,
        'tipo': _tipoSeleccionado,
        'categoria': _tipoSeleccionado == 'Ingreso' ? '' : _categoriaSeleccionada,
        'justificacion': razon,
        'fecha': DateTime.now().toIso8601String(),
      });
    });

    // Guardar en SharedPreferences
    _guardarTransacciones();
    
    // Actualizar ahorros automáticamente
    _actualizarAhorrosDelMes();

    // Limpiar y cerrar
    _tituloController.clear();
    _montoController.clear();
    _justificacionController.clear();
    Navigator.of(context).pop();
  }

  void _mostrarFormulario(BuildContext ctx, String tipo) {
    // Compatibilidad: formulario simple para crear
    _mostrarFormularioConIndice(ctx, tipo);
  }

  // Mostrar formulario para crear o editar. Si index != null editamos.
  void _mostrarFormularioConIndice(BuildContext ctx, String tipo, {int? index}) {
    _tipoSeleccionado = tipo;
    _categoriaSeleccionada = 'Otro';
    bool registrarComoGastoFijo = false;
    int diaVencimientoLocal = DateTime.now().day;
    if (index != null) {
      final existing = _transacciones[index];
      _tituloController.text = existing['titulo'] ?? '';
      // monto puede ser negativo para egresos
      _montoController.text = (existing['monto'] ?? 0).abs().toString();
      _justificacionController.text = existing['justificacion'] ?? '';
      _categoriaSeleccionada = existing['categoria'] ?? 'Otro';
    } else {
      _tituloController.clear();
      _montoController.clear();
      _justificacionController.clear();
      _tipoSeleccionado = tipo;
      _categoriaSeleccionada = 'Otro';
    }

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void submitForm() {
              if (index == null) {
                final nombre = _tituloController.text;
                final monto = double.tryParse(_montoController.text) ?? 0.0;
                _agregarNuevaTransaccion();
                if (tipo == 'Egreso' && registrarComoGastoFijo && nombre.isNotEmpty && monto > 0) {
                  _agregarGastoFijoDesdeEgreso(nombre, monto, diaVencimientoLocal);
                }
              } else {
                _guardarEdicion(index);
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      index == null ? (tipo == 'Ingreso' ? 'Nuevo Ingreso' : 'Nuevo Egreso') : 'Editar Movimiento',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _tituloController,
                      focusNode: _tituloFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _montoFocus.requestFocus(),
                      decoration: const InputDecoration(labelText: 'Título (ej. Sueldo, Alquiler)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _montoController,
                      focusNode: _montoFocus,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _justificacionFocus.requestFocus(),
                      decoration: const InputDecoration(labelText: 'Monto \$'),
                    ),
                    const SizedBox(height: 12),
                    // Mostrar categoría solo para egresos
                    if (tipo == 'Egreso')
                      DropdownButtonFormField<String>(
                        initialValue: _categoriaSeleccionada,
                        decoration: const InputDecoration(labelText: 'Categoría'),
                        items: _categorias.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text('${entry.value} ${entry.key}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _categoriaSeleccionada = value ?? 'Otro';
                          });
                        },
                      ),
                    if (tipo == 'Egreso') const SizedBox(height: 12),
                    if (tipo == 'Egreso' && index == null)
                      CheckboxListTile(
                        value: registrarComoGastoFijo,
                        onChanged: (value) {
                          setState(() {
                            registrarComoGastoFijo = value ?? false;
                          });
                        },
                        title: const Text('Marcar como gasto fijo'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    if (tipo == 'Egreso' && index == null && registrarComoGastoFijo)
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Día de vencimiento: $diaVencimientoLocal'),
                              ),
                              Slider(
                                value: diaVencimientoLocal.toDouble(),
                                min: 1,
                                max: 31,
                                divisions: 30,
                                label: diaVencimientoLocal.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    diaVencimientoLocal = value.toInt();
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    TextField(
                      controller: _justificacionController,
                      focusNode: _justificacionFocus,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => submitForm(),
                      decoration: const InputDecoration(labelText: 'Justificación'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () { Navigator.of(context).pop(); }, child: Text(_strings.cancelar)),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: submitForm,
                          child: Text(_strings.guardar),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _guardarEdicion(int index) {
    final nombre = _tituloController.text;
    final monto = double.tryParse(_montoController.text) ?? 0.0;
    final razon = _justificacionController.text;

    if (nombre.isEmpty || monto <= 0) return;

    setState(() {
      _transacciones[index] = {
        'titulo': nombre,
        'monto': _tipoSeleccionado == 'Ingreso' ? monto : -monto,
        'tipo': _tipoSeleccionado,
        'categoria': _tipoSeleccionado == 'Ingreso' ? '' : _categoriaSeleccionada,
        'justificacion': razon,
        'fecha': _transacciones[index]['fecha'] ?? DateTime.now().toIso8601String(),
      };
    });

    _guardarTransacciones();
    
    // Actualizar ahorros automáticamente
    _actualizarAhorrosDelMes();

    _tituloController.clear();
    _montoController.clear();
    _justificacionController.clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_authChecked) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_strings.appTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 64, color: Color(0xFF6B7280)),
                const SizedBox(height: 16),
                const Text(
                  'Acceso protegido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verifica tu identidad con biometría o código del dispositivo',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _autenticarConBiometria,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Verificar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_strings.appTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transacciones', icon: Icon(Icons.swap_horiz)),
            Tab(text: 'Ahorros', icon: Icon(Icons.savings)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'presupuesto') {
                _showPresupuestoDialog();
              } else if (value == 'graficos') {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChartsPage(
                    transacciones: _transacciones,
                    obtenerDatosGraficoMensual: _obtenerDatosGraficoMensual,
                    obtenerDatosGraficoAnual: _obtenerDatosGraficoAnual,
                    obtenerDatosEgresosPorCategoria: _obtenerDatosEgresosPorCategoria,
                    strings: _strings,
                  ),
                ));
              } else if (value == 'reportes') {
                _showReportesDialog();
              } else if (value == 'configuracion') {
                _showConfigurationDialog();
              } else if (value == 'gastos_fijos') {
                _mostrarDialogoGastosFijos();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'presupuesto', child: Text('💰 ${_strings.presupuestoMensual}')),
              PopupMenuItem(value: 'gastos_fijos', child: const Text('💳 Gastos Fijos')),
              PopupMenuItem(value: 'graficos', child: Text('📊 ${_strings.verGraficos}')),
              PopupMenuItem(value: 'reportes', child: Text('📋 Reportes')),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'configuracion', child: Text('⚙️ ${_strings.configuracion}')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña de Transacciones
          _buildTransaccionesTab(),
          // Pestaña de Ahorros
          _buildAhorrosTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'ingreso',
                  backgroundColor: const Color(0xFF10B981),
                  onPressed: () => _mostrarFormulario(context, 'Ingreso'),
                  icon: const Icon(Icons.add),
                  label: Text(_strings.ingresos, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  heroTag: 'egreso',
                  backgroundColor: const Color(0xFFEF4444),
                  onPressed: () => _mostrarFormulario(context, 'Egreso'),
                  icon: const Icon(Icons.remove),
                  label: Text(_strings.egresos, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            )
          : null,
    );
  }

  void _mostrarDialogoGastosFijos() {
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxHeight: 600),
                child: Column(
                  children: [
                    AppBar(
                      title: const Text('Gastos Fijos'),
                      automaticallyImplyLeading: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            Navigator.pop(context);
                            _mostrarDialogoGastoFijo();
                          },
                        ),
                      ],
                    ),
                    Expanded(
                      child: _gastosFijos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.credit_card, size: 64, color: Color(0xFFD1D5DB)),
                                  const SizedBox(height: 16),
                                  const Text('Sin gastos fijos registrados'),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _mostrarDialogoGastoFijo();
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Agregar Gasto Fijo'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _gastosFijos.length,
                              itemBuilder: (ctx, index) {
                                final gastoFijo = _gastosFijos[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.credit_card,
                                      color: gastoFijo['activo'] == true ? const Color(0xFF10B981) : Colors.grey,
                                    ),
                                    title: Text(gastoFijo['nombre'] ?? 'Gasto'),
                                    subtitle: Text(
                                      'Día ${gastoFijo['diaVencimiento']} • ${_appCurrency.formatAmount(gastoFijo['monto'] as double)}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _eliminarGastoFijo(index),
                                          tooltip: 'Eliminar',
                                        ),
                                        PopupMenuButton(
                                          itemBuilder: (ctx) => [
                                            PopupMenuItem(
                                              child: const Text('Editar'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _mostrarDialogoGastoFijo(index: index);
                                              },
                                            ),
                                            PopupMenuItem(
                                              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                              onTap: () {
                                                _eliminarGastoFijo(index);
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransaccionesTab() {
    double ingresos = _calcularIngresos();
    double egresos = _calcularEgresos();
    double balance = ingresos - egresos;
    
    // Calcular egresos del mes seleccionado para verificar presupuesto
    final List<Map<String, dynamic>> egresosDelMes = _transacciones
        .where((t) {
          final String? fechaStr = t['fecha'];
          if (fechaStr == null) return false;
          final DateTime fechaTransaccion = DateTime.parse(fechaStr);
          return t['tipo'] == 'egreso' &&
              fechaTransaccion.year == _mesSeleccionado.year &&
              fechaTransaccion.month == _mesSeleccionado.month;
        })
        .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Tarjetas de ingresos y egresos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                // Tarjeta de Ingresos
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: const Color(0xFFECFDF5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFF10B981), width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 28),
                              const SizedBox(width: 12),
                              Text(_strings.ingresos, style: const TextStyle(fontSize: 16, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(_appCurrency.formatAmount(ingresos), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Tarjeta de Egresos
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                    ),
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.trending_down, color: Color(0xFFEF4444), size: 28),
                                const SizedBox(width: 12),
                                Text(_strings.egresos, style: const TextStyle(fontSize: 16, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(_appCurrency.formatAmount(egresos), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Resumen de balance
            Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: _getBalanceCardColor(balance, egresosDelMes),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_strings.balanceTotal, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
                    Text(_appCurrency.formatAmount(balance), 
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _getBalanceTextColor(balance, egresosDelMes))),
                  ],
                ),
              ),
            ),
            // Selector de mes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: () {
                      setState(() {
                        _mesSeleccionado = DateTime(_mesSeleccionado.year, _mesSeleccionado.month - 1);
                      });
                    },
                  ),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _mesSeleccionado,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _mesSeleccionado = DateTime(pickedDate.year, pickedDate.month);
                        });
                      }
                    },
                    child: Text(
                      _obtenerNombreMes(_mesSeleccionado),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    onPressed: () {
                      setState(() {
                        _mesSeleccionado = DateTime(_mesSeleccionado.year, _mesSeleccionado.month + 1);
                      });
                    },
                  ),
                ],
              ),
            ),
            // Barra de progreso del presupuesto
            if (_presupuestoMensual > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: const Color(0xFFF9FAFB),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_strings.presupuestoMensual} 💰',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
                            ),
                            Text(
                              _appCurrency.formatAmount(_presupuestoMensual),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Barra de progreso
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (_calcularEgresosMesSeleccionado() / _presupuestoMensual).clamp(0.0, 1.0),
                            minHeight: 12,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressBarColor((_calcularEgresosMesSeleccionado() / _presupuestoMensual) * 100),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Información de gasto
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_strings.gastado}: ${_appCurrency.formatAmount(_calcularEgresosMesSeleccionado())}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                            ),
                            Text(
                              '${((_calcularEgresosMesSeleccionado() / _presupuestoMensual) * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _getProgressBarColor((_calcularEgresosMesSeleccionado() / _presupuestoMensual) * 100),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Lista de movimientos
            _obtenerTransaccionesMes().isEmpty 
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No hay movimientos en este mes. ¡Usa el botón +!'),
                )
              : SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: _obtenerTransaccionesMes().length,
                    itemBuilder: (ctx, i) {
                      final transaccionesMes = _obtenerTransaccionesMes();
                      final t = transaccionesMes[i];
                      // Encontrar el índice en la lista original
                      final indexOriginal = _transacciones.indexOf(t);
                      return Dismissible(
                        key: Key('transaccion_${indexOriginal}_$i'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white, size: 30),
                        ),
                        onDismissed: (direction) {
                          setState(() {
                            _transacciones.removeAt(indexOriginal);
                          });
                          _guardarTransacciones();
                          _actualizarAhorrosDelMes();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Movimiento eliminado')),
                          );
                        },
                        child: ListTile(
                          leading: t['tipo'] == 'Ingreso'
                              ? const CircleAvatar(
                                  backgroundColor: Color(0xFF10B981),
                                  child: Icon(Icons.check_circle, color: Colors.white, size: 20),
                                )
                              : CircleAvatar(
                                  backgroundColor: const Color(0xFFEF4444),
                                  child: Text(
                                    _categorias[t['categoria']] ?? '❓',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                          title: Text(t['titulo'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(t['tipo'] == 'Ingreso' ? t['justificacion'] : '${t['categoria']} • ${t['justificacion']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('\$${t['monto']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () {
                                  // Confirmar eliminación
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Eliminar movimiento'),
                                      content: Text('¿Estás seguro de que deseas eliminar "${t['titulo']}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _transacciones.removeAt(indexOriginal);
                                            });
                                            _guardarTransacciones();
                                            _actualizarAhorrosDelMes();
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Movimiento eliminado')),
                                            );
                                          },
                                          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () => _mostrarFormularioConIndice(context, t['tipo'], index: i),
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      );
    }

  Widget _buildAhorrosTab() {
    double totalAhorros = _calcularAhorrosTotales();
    
    // Ordenar registros por mes (más recientes primero)
    final ahorrosOrdenados = [..._registrosAhorros]
      ..sort((a, b) => _obtenerFechaAhorro(b).compareTo(_obtenerFechaAhorro(a)));
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Tarjeta de ahorros totales
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Card(
              elevation: 0,
              color: const Color(0xFFECFDF5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF10B981), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.savings, color: Color(0xFF10B981), size: 32),
                        const SizedBox(width: 16),
                        Text('Ahorros Acumulados', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _appCurrency.formatAmount(totalAhorros),
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Total acumulado de todos los meses',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _mostrarDialogoExtraccionAhorro,
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Extracción de dinero'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Registros de ahorros
          if (_registrosAhorros.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.savings, size: 64, color: Color(0xFFD1D5DB)),
                  const SizedBox(height: 16),
                  const Text(
                    'Sin registros de ahorros',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Registra transacciones para generar ahorros por mes',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const Text(
                    'Historial de Ahorros por Mes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ahorrosOrdenados.length,
                    itemBuilder: (ctx, i) {
                      final ahorro = ahorrosOrdenados[i];
                      final monto = (ahorro['monto'] as num).toDouble();
                      final tipo = (ahorro['tipo'] ?? 'balance') as String;

                      String mesKey;
                      if (ahorro['mes'] != null) {
                        mesKey = ahorro['mes'] as String;
                      } else if (ahorro['fecha'] != null) {
                        final fecha = DateTime.parse(ahorro['fecha']);
                        mesKey = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
                      } else {
                        mesKey = '0000-00';
                      }

                      final partes = mesKey.split('-');
                      final anio = int.tryParse(partes[0]) ?? 0;
                      final mes = int.tryParse(partes[1]) ?? 1;

                      const meses = [
                        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
                      ];

                      final montoPositivo = monto >= 0;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: const Color(0xFFF9FAFB),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tipo == 'extraccion'
                                        ? 'Extracción de ahorro'
                                        : (anio > 0 ? '${meses[mes - 1]} $anio' : 'Mes desconocido'),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tipo == 'extraccion'
                                        ? (ahorro['nota'] != null && (ahorro['nota'] as String).isNotEmpty
                                            ? ahorro['nota']
                                            : 'Uso de reservas')
                                        : (montoPositivo ? 'Balance positivo' : 'Balance negativo'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: tipo == 'extraccion'
                                          ? const Color(0xFFEF4444)
                                          : (montoPositivo ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _appCurrency.formatAmount(monto),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: tipo == 'extraccion'
                                      ? const Color(0xFFEF4444)
                                      : (montoPositivo ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getHoraFormato(DateTime fecha) {
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}

// Página separada para los gráficos
class ChartsPage extends StatelessWidget {
  final List<Map<String, dynamic>> transacciones;
  final Function obtenerDatosGraficoMensual;
  final Function obtenerDatosGraficoAnual;
  final Function obtenerDatosEgresosPorCategoria;
  final AppStrings strings;

  const ChartsPage({
    required this.transacciones,
    required this.obtenerDatosGraficoMensual,
    required this.obtenerDatosGraficoAnual,
    required this.obtenerDatosEgresosPorCategoria,
    required this.strings,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📊 ${strings.verGraficos}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gráfico de distribución mensual
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📅 Distribución Mensual',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: obtenerDatosGraficoMensual(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '📆 Distribución Anual',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: obtenerDatosGraficoAnual(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManualScreen extends StatelessWidget {
  final AppStrings strings;

  const ManualScreen({required this.strings, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual de uso', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        centerTitle: true,
        elevation: 0,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido a Zentavo. Aquí tienes una guía rápida para usar la app:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),
              Text('1) Transacciones', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('• Agrega ingresos o egresos con los botones de la parte inferior.'),
              Text('• Puedes editar tocando un movimiento o eliminarlo con el ícono de basura.'),
              Text('• Usa el selector de mes para revisar históricos.'),
              SizedBox(height: 16),
              Text('2) Ahorros', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('• Los ahorros se calculan automáticamente por mes (ingresos - egresos).'),
              Text('• Puedes realizar una extracción desde el botón “Extracción de dinero”.'),
              SizedBox(height: 16),
              Text('3) Gastos fijos', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('• Al crear un egreso, puedes marcarlo como gasto fijo con el tilde.'),
              Text('• También puedes gestionarlos desde Configuración > Gastos Fijos.'),
              Text('• En la lista de gastos fijos puedes editar o eliminarlos.'),
              SizedBox(height: 16),
              Text('4) Presupuesto mensual', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('• Define un presupuesto y la app te avisa si lo superas.'),
              SizedBox(height: 16),
              Text('5) Reportes y descargas', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('• Genera reportes en PDF o Excel desde el menú de opciones.'),
              Text('• Puedes exportar JSON, CSV o TXT desde “Descargar”.'),
              SizedBox(height: 16),
              Text('6) Seguridad', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('• La app solicita biometría o código del dispositivo al iniciar.'),
            ],
          ),
        ),
      ),
    );
  }
}
