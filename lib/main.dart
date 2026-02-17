import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'export_utils.dart';
import 'localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_auth/local_auth.dart';
import 'splash_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'premium_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'shared_events_screen.dart';
import 'analytics_service.dart';
import 'onboarding_screen.dart';
import 'notifications_service.dart';
import 'social_share_service.dart';
import 'profile_screen.dart';

void main() => runApp(const ExpenseApp());

class ExpenseApp extends StatefulWidget {
  const ExpenseApp({super.key});

  @override
  State<ExpenseApp> createState() => _ExpenseAppState();
}

class _ExpenseAppState extends State<ExpenseApp> {
  late Future<ThemeMode> _themeModeFuture;
  static const Color _primaryColor = Color(0xFF0EA5A4);
  static const Color _secondaryColor = Color(0xFF22C55E);
  static const Color _tertiaryColor = Color(0xFFF59E0B);
  static const Color _lightBackground = Color(0xFFF5FBFA);
  static const Color _darkBackground = Color(0xFF0B1416);
  static const Color _darkSurface = Color(0xFF111D1F);

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
            colorScheme: ColorScheme.fromSeed(
              seedColor: _primaryColor,
              primary: _primaryColor,
              secondary: _secondaryColor,
              tertiary: _tertiaryColor,
              brightness: Brightness.light,
              surface: Colors.white,
              background: _lightBackground,
            ),
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
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            scaffoldBackgroundColor: _lightBackground,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _primaryColor,
              primary: _primaryColor,
              secondary: _secondaryColor,
              tertiary: _tertiaryColor,
              brightness: Brightness.dark,
              surface: _darkSurface,
              background: _darkBackground,
            ),
            useMaterial3: true,
            brightness: Brightness.dark,
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              color: _darkSurface,
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            scaffoldBackgroundColor: _darkBackground,
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
  
  // Monedas adicionales (Premium)
  List<AppCurrency> _monedasDisponibles = [];
  
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

  // Banner ads
  BannerAd? _bannerAdTransacciones;
  BannerAd? _bannerAdAhorros;
  bool _isBannerTransaccionesLoaded = false;
  bool _isBannerAhorrosLoaded = false;

  // Estado Premium
  bool _isPremium = false;
  
  // Contador de transacciones para conversión a Premium
  int _transaccionesCreadas = 0;
  bool _mostroPopupConversion = false;
  
  // Performance timing
  late DateTime _appStartTime;
  final Map<String, DateTime> _timingMarkers = {};

  void _recordTiming(String marker) {
    _timingMarkers[marker] = DateTime.now();
    final elapsed = DateTime.now().difference(_appStartTime).inMilliseconds;
    print('[TIMING] $marker - ${elapsed}ms desde inicio');
  }

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

  // Categorías personalizadas (Premium)
  Map<String, String> _categoriasPersonalizadas = {};

  Future<void> _checkPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool('is_premium') ?? false;
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
        });
      }
    } catch (e) {
      print('Error al verificar estado premium: $e');
    }
  }

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
    _appStartTime = DateTime.now();
    _recordTiming('initState START');
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _autenticarConBiometria();
    _mesSeleccionado = DateTime(DateTime.now().year, DateTime.now().month);
    _diaVencimientoSeleccionado = 1;
    _recordTiming('Vars initialized');
    _inicializarNotificaciones();
    _recordTiming('Notifications initialized');
    // Inicializar Analytics
    _initializeAnalytics();
    // Verificar onboarding
    _checkOnboarding();
    // Cargar datos de forma asincrónica para no bloquear la UI
    _cargarTransaccionesAsync();
    // No bloquear esperando _checkPremiumStatus()
    _checkPremiumStatus();
    // Solo inicializar AdMob en plataformas soportadas (Android/iOS)
    if (!kIsWeb) {
      _initializeMobileAds();
    }
    _recordTiming('initState COMPLETE');
  }

  Future<void> _initializeAnalytics() async {
    await AnalyticsService().initialize();
    await AnalyticsService().trackAppOpen();
  }

  Future<void> _checkOnboarding() async {
    final hasCompleted = await OnboardingService().hasCompletedOnboarding();
    if (!hasCompleted && mounted) {
      // Esperar un poco para que la UI esté lista
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      });
    }
  }

  void _initializeMobileAds() {
    if (kIsWeb || Platform.isWindows) {
      // AdMob no soportado en Web ni Windows
      print('[TIMING] AdMob skipped - platform not supported');
      return;
    }
    _recordTiming('MobileAds initialize START');
    MobileAds.instance.initialize();
    _recordTiming('MobileAds initialize COMPLETE');
    _createBannerAds();
  }

  void _createBannerAds() {
    if (kIsWeb || Platform.isWindows) {
      print('[TIMING] Banner ads skipped - platform not supported');
      return;
    }
    _recordTiming('Creating banner ads');
    // Determinar el Ad Unit ID según la plataforma
    String adUnitId;
    if (kIsWeb) {
      // En web usamos el ID de Android por defecto
      adUnitId = 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isAndroid) {
      adUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Test ID Android
    } else {
      adUnitId = 'ca-app-pub-3940256099942544/2934735716'; // Test ID iOS
    }

    // Banner para pestaña de Transacciones
    _bannerAdTransacciones = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerTransaccionesLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _isBannerTransaccionesLoaded = false;
          });
        },
      ),
    )..load();

    // Banner para pestaña de Ahorros
    _bannerAdAhorros = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAhorrosLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _isBannerAhorrosLoaded = false;
          });
        },
      ),
    )..load();
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
    _bannerAdTransacciones?.dispose();
    _bannerAdAhorros?.dispose();
    super.dispose();
  }

  Future<void> _cargarTransaccionesAsync() async {
    // Cargar datos de forma asincrónica sin bloquear la UI
    Future.delayed(Duration.zero, () async {
      _recordTiming('_cargarTransaccionesAsync START (non-blocking)');
      await _cargarTransacciones();
      _verificarYEnviarRecordatorios();
      _recordTiming('_cargarTransaccionesAsync COMPLETE');
    });
  }

  Future<void> _cargarTransacciones() async {
    _recordTiming('_cargarTransacciones START');
    _prefs = await SharedPreferences.getInstance();
    _recordTiming('SharedPreferences inicializado');
    final String? datosGuardados = _prefs.getString('transacciones');
    _recordTiming('Transacciones cargadas de prefs');
    
    // Cargar idioma y moneda
    final String languageCode = _prefs.getString('app_language') ?? 'spanish';
    _appLanguage = AppLanguage.values.firstWhere(
      (lang) => lang.toString().split('.').last == languageCode,
      orElse: () => AppLanguage.spanish,
    );
    _recordTiming('Idioma cargado');
    
    final String currencyCode = _prefs.getString('app_currency') ?? 'usd';
    _appCurrency = AppCurrency.values.firstWhere(
      (curr) => curr.toString().split('.').last == currencyCode,
      orElse: () => AppCurrency.usd,
    );
    _recordTiming('Moneda cargada');
    
    // Solo recrear AppStrings si el idioma cambió
    if (_strings.language != _appLanguage) {
      _strings = AppStrings(language: _appLanguage);
      _recordTiming('Strings inicializados (new language)');
    } else {
      _recordTiming('Strings cached (same language)');
    }
    
    // Cargar tema actual
    final themeModeString = _prefs.getString('themeMode') ?? 'system';
    _currentThemeMode = themeModeString;
    
    // Cargar presupuesto mensual
    _presupuestoMensual = _prefs.getDouble('presupuesto_mensual') ?? 0.0;
    _notificacionEnviada = false;
    
    // Cargar contador de transacciones para conversión
    _transaccionesCreadas = _prefs.getInt('transacciones_creadas') ?? 0;
    _mostroPopupConversion = _prefs.getBool('mostro_popup_conversion') ?? false;
    
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
    _recordTiming('Ahorros cargados');

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
    _recordTiming('Gastos fijos cargados');

    // Cargar categorías personalizadas (Premium)
    final String? categoriasGuardadas = _prefs.getString('categorias_personalizadas');
    if (categoriasGuardadas != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(categoriasGuardadas);
        setState(() {
          _categoriasPersonalizadas = decoded.map((key, value) => MapEntry(key, value.toString()));
        });
      } catch (e) {
        print('Error al cargar categorías personalizadas: $e');
      }
    }
    _recordTiming('Categorías cargadas');

    // Cargar monedas adicionales (Premium)
    final String? monedasGuardadas = _prefs.getString('monedas_adicionales');
    if (monedasGuardadas != null && _isPremium) {
      try {
        final List<dynamic> decoded = jsonDecode(monedasGuardadas);
        setState(() {
          _monedasDisponibles = decoded
              .map((item) => AppCurrency.values.firstWhere(
                    (c) => c.toString() == item,
                    orElse: () => AppCurrency.usd,
                  ))
              .toList();
        });
      } catch (e) {
        print('Error al cargar monedas adicionales: $e');
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
              RadioListTile<AppLanguage>(
                title: const Text('中文'),
                secondary: const Text('🇨🇳'),
                value: AppLanguage.chinese,
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
                title: const Text('日本語'),
                secondary: const Text('🇯🇵'),
                value: AppLanguage.japanese,
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: Text(_strings.manualDeUso),
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
                  leading: const Icon(Icons.analytics, color: Color(0xFF0EA5A4)),
                  title: const Text('Analytics'),
                  subtitle: const Text('Ver estadísticas de uso'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications, color: Color(0xFFF59E0B)),
                  title: const Text('Notificaciones'),
                  subtitle: const Text('Configurar recordatorios'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.school, color: Color(0xFF6366F1)),
                  title: const Text('Tutorial'),
                  subtitle: const Text('Ver tutorial de nuevo'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: Text(_strings.compartirApp),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    _compartirApp();
                  },
                ),
              ],
            ),
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
📊 Gráficos e informes detallados
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
          title: Text(_strings.reportes),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_strings.seleccionaFormatoReporte),
              if (_isPremium)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '✨ Exportación anual disponible',
                    style: TextStyle(fontSize: 12, color: Color(0xFFF59E0B)),
                  ),
                ),
            ],
          ),
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
                if (_isPremium) {
                  _mostrarOpcionesExportacion('pdf');
                } else {
                  _exportarMesActual('pdf');
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.table_chart),
              label: Text(_strings.reporteExcel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5A4),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                if (_isPremium) {
                  _mostrarOpcionesExportacion('excel');
                } else {
                  _exportarMesActual('excel');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _mostrarOpcionesExportacion(String formato) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('${_strings.exportar2} ${formato.toUpperCase()}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(_strings.mesActual),
                subtitle: Text(_obtenerNombreMes(_mesSeleccionado)),
                onTap: () {
                  Navigator.pop(context);
                  _exportarMesActual(formato);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_view_month),
                title: Text(_strings.todoElAnio),
                subtitle: Text('${_mesSeleccionado.year}'),
                onTap: () {
                  Navigator.pop(context);
                  _exportarAnual(formato);
                },
              ),
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: Text(_strings.todosLosDatos),
                subtitle: Text(_strings.historiaiCompleto),
                onTap: () {
                  Navigator.pop(context);
                  _exportarTodoHistorial(formato);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportarMesActual(String formato) async {
    try {
      final transaccionesMes = _obtenerTransaccionesMes();
      Directory dir;
      
      // Usar directorio de documentos de la app (accesible y permanente)
      if (Platform.isAndroid) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      
      final monthStr = '${_mesSeleccionado.month.toString().padLeft(2, '0')}-${_mesSeleccionado.year}';
      final extension = formato == 'pdf' ? 'pdf' : 'xlsx';
      final fileName = 'Informe_$monthStr.$extension';
      final filePath = p.join(dir.path, fileName);
      
      if (formato == 'pdf') {
        final pdfBytes = await exportMonthlyReportPdf(
          month: _mesSeleccionado,
          transactions: transaccionesMes,
          ingresos: _calcularIngresos(),
          egresos: _calcularEgresos(),
        );
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
      } else {
        final excelBytes = await exportMonthlyReportExcel(
          month: _mesSeleccionado,
          transactions: transaccionesMes,
          ingresos: _calcularIngresos(),
          egresos: _calcularEgresos(),
        );
        final file = File(filePath);
        await file.writeAsBytes(excelBytes);
      }
      
      // Mostrar diálogo con opciones
      if (mounted) {
        _mostrarDialogoArchivoGuardado(filePath, fileName, 'Informe Mensual $monthStr');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar informe: $e')),
        );
      }
    }
  }

  void _mostrarDialogoArchivoGuardado(String filePath, String fileName, String descripcion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Informe guardado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El informe se guard\u00f3 correctamente:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.insert_drive_file, size: 20, color: Color(0xFF0EA5A4)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ubicaci\u00f3n: Documentos de la app',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '\u00bfQu\u00e9 deseas hacer?',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await Share.shareXFiles([XFile(filePath)], text: descripcion);
            },
            icon: const Icon(Icons.share),
            label: const Text('Compartir'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              // Intentar abrir el archivo con la aplicaci\u00f3n predeterminada
              try {
                if (Platform.isAndroid || Platform.isIOS) {
                  await Share.shareXFiles([XFile(filePath)], text: 'Abrir con...');
                } else {
                  // En escritorio, intentar abrir directamente
                  final uri = Uri.file(filePath);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo abrir el archivo: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5A4),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportarAnual(String formato) async {
    try {
      // Filtrar transacciones del año seleccionado
      final transaccionesAnio = _transacciones.where((t) {
        if (t['fecha'] == null) return false;
        try {
          final fecha = DateTime.parse(t['fecha']);
          return fecha.year == _mesSeleccionado.year;
        } catch (e) {
          return false;
        }
      }).toList();

      if (transaccionesAnio.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_strings.noHayDatos)),
        );
        return;
      }

      double ingresosAnuales = 0;
      double egresosAnuales = 0;
      
      for (var t in transaccionesAnio) {
        if (t['tipo'] == 'Ingreso') {
          ingresosAnuales += (t['monto'] as num).toDouble();
        } else {
          egresosAnuales += (t['monto'].abs() as num).toDouble();
        }
      }

      Directory dir;
      if (Platform.isAndroid) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      
      final yearStr = '${_mesSeleccionado.year}';
      final extension = formato == 'pdf' ? 'pdf' : 'xlsx';
      final fileName = 'Informe_Anual_$yearStr.$extension';
      final filePath = p.join(dir.path, fileName);
      
      if (formato == 'pdf') {
        final pdfBytes = await exportMonthlyReportPdf(
          month: DateTime(_mesSeleccionado.year, 1),
          transactions: transaccionesAnio,
          ingresos: ingresosAnuales,
          egresos: egresosAnuales,
        );
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
      } else {
        final excelBytes = await exportMonthlyReportExcel(
          month: DateTime(_mesSeleccionado.year, 1),
          transactions: transaccionesAnio,
          ingresos: ingresosAnuales,
          egresos: egresosAnuales,
        );
        final file = File(filePath);
        await file.writeAsBytes(excelBytes);
      }
      
      if (mounted) {
        _mostrarDialogoArchivoGuardado(filePath, fileName, 'Informe Anual $yearStr');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar informe: $e')),
        );
      }
    }
  }

  Future<void> _exportarTodoHistorial(String formato) async {
    try {
      if (_transacciones.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_strings.noHayDatosExportar)),
        );
        return;
      }

      double ingresosTotal = 0;
      double egresosTotal = 0;
      
      for (var t in _transacciones) {
        if (t['tipo'] == 'Ingreso') {
          ingresosTotal += (t['monto'] as num).toDouble();
        } else {
          egresosTotal += (t['monto'].abs() as num).toDouble();
        }
      }

      Directory dir;
      if (Platform.isAndroid) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      
      final extension = formato == 'pdf' ? 'pdf' : 'xlsx';
      final fileName = 'Informe_Completo.$extension';
      final filePath = p.join(dir.path, fileName);
      
      if (formato == 'pdf') {
        final pdfBytes = await exportMonthlyReportPdf(
          month: DateTime.now(),
          transactions: _transacciones,
          ingresos: ingresosTotal,
          egresos: egresosTotal,
        );
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
      } else {
        final excelBytes = await exportMonthlyReportExcel(
          month: DateTime.now(),
          transactions: _transacciones,
          ingresos: ingresosTotal,
          egresos: egresosTotal,
        );
        final file = File(filePath);
        await file.writeAsBytes(excelBytes);
      }
      
      if (mounted) {
        _mostrarDialogoArchivoGuardado(filePath, fileName, 'Informe Completo');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar informe: $e')),
        );
      }
    }
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
    return balance >= 0 ? const Color(0xFFE7F8F7) : const Color(0xFFFEF2F2);
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
    return balance >= 0 ? const Color(0xFF0EA5A4) : const Color(0xFFEF4444);
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
      return const Color(0xFF0EA5A4); // Verde
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
        SnackBar(content: Text(_strings.ingresaMontoValido)),
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
          title: Text(_strings.extraccionDeAhorro),
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
              child: Text(_strings.extraer),
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
      SnackBar(content: Text('${_strings.gastoFijoAgregado}: "$nombre"')),
    );
  }

  void _agregarGastoFijo() {
    final nombre = _nombreGastoController.text;
    final monto = double.tryParse(_montoGastoFijoController.text) ?? 0.0;
    
    if (nombre.isEmpty || monto <= 0 || _diaVencimientoSeleccionado < 1 || _diaVencimientoSeleccionado > 31) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_strings.completaTodosCampos)),
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
      SnackBar(content: Text('${_strings.gastoFijoAgregado}: "$nombre"')),
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
      SnackBar(content: Text('${_strings.gastoFijoActualizado}: "$nombre"')),
    );
  }

  void _eliminarGastoFijo(int index) {
    final nombreEliminado = _gastosFijos[index]['nombre'];
    setState(() {
      _gastosFijos.removeAt(index);
    });
    _guardarGastosFijos();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_strings.gastoFijoEliminado}: "$nombreEliminado"')),
    );
  }

  // ===== MÉTODOS PARA CATEGORÍAS PERSONALIZADAS (PREMIUM) =====

  Future<void> _guardarCategoriasPersonalizadas() async {
    try {
      final String datosJSON = jsonEncode(_categoriasPersonalizadas);
      await _prefs.setString('categorias_personalizadas', datosJSON);
    } catch (e) {
      print('Error al guardar categorías personalizadas: $e');
    }
  }

  Map<String, String> _obtenerTodasLasCategorias() {
    return {..._categorias, ..._categoriasPersonalizadas};
  }

  void _agregarCategoriaPersonalizada(String nombre, String emoji) {
    if (nombre.isEmpty || emoji.isEmpty) return;
    
    setState(() {
      _categoriasPersonalizadas[nombre] = emoji;
    });
    _guardarCategoriasPersonalizadas();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_strings.categoriaAgregada}: "$nombre"')),
    );
  }

  void _eliminarCategoriaPersonalizada(String nombre) {
    setState(() {
      _categoriasPersonalizadas.remove(nombre);
    });
    _guardarCategoriasPersonalizadas();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_strings.categoriaEliminada}: "$nombre"')),
    );
  }

  void _mostrarDialogoCategoriasPersonalizadas() {
    if (!_isPremium) {
      _mostrarDialogoPremiumRequerido('Categorías personalizadas');
      return;
    }

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
                      title: const Text('Mis Categorías'),
                      automaticallyImplyLeading: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            _mostrarDialogoNuevaCategoria();
                          },
                        ),
                      ],
                    ),
                    Expanded(
                      child: _categoriasPersonalizadas.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.category, size: 64, color: Color(0xFFD1D5DB)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tienes categorías personalizadas',
                                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Toca + para agregar una nueva',
                                    style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _categoriasPersonalizadas.length,
                              itemBuilder: (ctx, index) {
                                final entry = _categoriasPersonalizadas.entries.elementAt(index);
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    leading: Text(
                                      entry.value,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                    title: Text(entry.key),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _eliminarCategoriaPersonalizada(entry.key);
                                      },
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

  void _mostrarDialogoNuevaCategoria() {
    final nombreController = TextEditingController();
    final emojiController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(_strings.nuevaCategoria),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                  hintText: 'ej. Mascotas, Ropa, etc.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emojiController,
                decoration: const InputDecoration(
                  labelText: 'Emoji',
                  border: OutlineInputBorder(),
                  hintText: '🐶',
                ),
                maxLength: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_strings.cancelar),
            ),
            ElevatedButton(
              onPressed: () {
                final nombre = nombreController.text.trim();
                final emoji = emojiController.text.trim();
                if (nombre.isNotEmpty && emoji.isNotEmpty) {
                  _agregarCategoriaPersonalizada(nombre, emoji);
                  Navigator.pop(context);
                }
              },
              child: Text(_strings.agregar),
            ),
          ],
        );
      },
    ).then((_) {
      nombreController.dispose();
      emojiController.dispose();
    });
  }

  void _mostrarDialogoPremiumRequerido(String funcionalidad) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              const Text('Premium Requerido'),
            ],
          ),
          content: Text(
            '$funcionalidad es una función exclusiva de Premium.\n\n'
            '¿Deseas actualizar a Premium?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_strings.cancelar),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PremiumScreen(strings: _strings)),
                );
                if (result == true) {
                  _checkPremiumStatus();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
              ),
              child: const Text('Ver Premium'),
            ),
          ],
        );
      },
    );
  }

  // ===== MÉTODOS PARA MONEDAS MÚLTIPLES (PREMIUM) =====

  Future<void> _guardarMonedasAdicionales() async {
    try {
      final List<String> monedasString = _monedasDisponibles.map((m) => m.toString()).toList();
      final String datosJSON = jsonEncode(monedasString);
      await _prefs.setString('monedas_adicionales', datosJSON);
    } catch (e) {
      print('Error al guardar monedas adicionales: $e');
    }
  }

  void _agregarMoneda(AppCurrency moneda) {
    if (!_monedasDisponibles.contains(moneda)) {
      setState(() {
        _monedasDisponibles.add(moneda);
      });
      _guardarMonedasAdicionales();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Moneda ${moneda.name.toUpperCase()} agregada')),
      );
    }
  }

  void _eliminarMoneda(AppCurrency moneda) {
    if (moneda == _appCurrency) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_strings.noObtieneMonedasActiva)),
      );
      return;
    }

    setState(() {
      _monedasDisponibles.remove(moneda);
    });
    _guardarMonedasAdicionales();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_strings.monedaEliminada}: ${moneda.name.toUpperCase()}')),
    );
  }

  void _cambiarMonedaActiva(AppCurrency moneda) {
    setState(() {
      _appCurrency = moneda;
    });
    _prefs.setString('currency', moneda.name);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_strings.monedaCambiada} ${moneda.symbol} ${moneda.name.toUpperCase()}')),
    );
  }

  void _mostrarDialogoMonedas() {
    if (!_isPremium) {
      _mostrarDialogoPremiumRequerido('Monedas múltiples');
      return;
    }

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
                      title: Text(_strings.monedaTitle),
                      automaticallyImplyLeading: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            _mostrarDialogoAgregarMoneda();
                          },
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_strings.moneda} ${_strings.activa}:',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            color: const Color(0xFFE7F8F7),
                            child: ListTile(
                              leading: Text(
                                _appCurrency.symbol,
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(
                                _appCurrency.name.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(_getNombreMoneda(_appCurrency)),
                              trailing: const Icon(Icons.check_circle, color: Color(0xFF0EA5A4)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Monedas disponibles (${_monedasDisponibles.length}):',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: _monedasDisponibles.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.currency_exchange, size: 64, color: Color(0xFFD1D5DB)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tienes monedas adicionales',
                                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Toca + para agregar una nueva',
                                    style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _monedasDisponibles.length,
                              itemBuilder: (ctx, index) {
                                final moneda = _monedasDisponibles[index];
                                final esActiva = moneda == _appCurrency;
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: ListTile(
                                    leading: Text(
                                      moneda.symbol,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    title: Text(moneda.name.toUpperCase()),
                                    subtitle: Text(_getNombreMoneda(moneda)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!esActiva)
                                          IconButton(
                                            icon: const Icon(Icons.swap_horiz, color: Color(0xFF0EA5A4)),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _cambiarMonedaActiva(moneda);
                                            },
                                          ),
                                        if (!esActiva)
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                                            onPressed: () {
                                              setState(() {
                                                _eliminarMoneda(moneda);
                                              });
                                            },
                                          ),
                                        if (esActiva)
                                          const Icon(Icons.check_circle, color: Color(0xFF0EA5A4)),
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

  void _mostrarDialogoAgregarMoneda() {
    final monedasNoAgregadas = AppCurrency.values
        .where((m) => !_monedasDisponibles.contains(m) && m != _appCurrency)
        .toList();

    if (monedasNoAgregadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_strings.noObtieneMonedasDisponibles)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(_strings.agregarMoneda),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: monedasNoAgregadas.length,
              itemBuilder: (ctx, index) {
                final moneda = monedasNoAgregadas[index];
                return ListTile(
                  leading: Text(
                    moneda.symbol,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(moneda.name.toUpperCase()),
                  subtitle: Text(_getNombreMoneda(moneda)),
                  onTap: () {
                    Navigator.pop(context);
                    _agregarMoneda(moneda);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_strings.cancelar),
            ),
          ],
        );
      },
    );
  }

  String _getNombreMoneda(AppCurrency moneda) {
    switch (moneda) {
      case AppCurrency.usd:
        return 'Dólar estadounidense';
      case AppCurrency.eur:
        return 'Euro';
      case AppCurrency.mxn:
        return 'Peso mexicano';
      case AppCurrency.ars:
        return 'Peso argentino';
      case AppCurrency.clp:
        return 'Peso chileno';
      case AppCurrency.brl:
        return 'Real brasileño';
      case AppCurrency.gbp:
        return 'Libra esterlina';
      case AppCurrency.inr:
        return 'Rupia india';
      case AppCurrency.jpy:
        return 'Yen japonés';
      case AppCurrency.cad:
        return 'Dólar canadiense';
      case AppCurrency.aud:
        return 'Dólar australiano';
      case AppCurrency.chf:
        return 'Franco suizo';
      case AppCurrency.cny:
        return 'Yuan chino';
      case AppCurrency.sek:
        return 'Corona sueca';
      case AppCurrency.nok:
        return 'Corona noruega';
      case AppCurrency.zar:
        return 'Rand sudafricano';
    }
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

  // Obtener nombre del mes según el idioma seleccionado
  String _obtenerNombreMes(DateTime fecha) {
    final meses = _strings.nombresMeses;
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
          title: _strings.sinDatos,
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
          title: '${_strings.ingresoLabel}\n${_appCurrency.formatAmount(ingresos)}',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    int colorIndex = 0;
    egresosPorCategoria.forEach((cat, value) {
      final color = _coloresCategorias[colorIndex % _coloresCategorias.length];
      colorIndex++;
      final todasCategorias = _obtenerTodasLasCategorias();
      final emoji = todasCategorias[cat] ?? '❓';
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
          title: _strings.sinDatos,
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
          title: '${_strings.ingresoLabel}\n${_appCurrency.formatAmount(ingresos)}',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    int colorIndex = 0;
    egresosPorCategoria.forEach((cat, value) {
      final color = _coloresCategorias[colorIndex % _coloresCategorias.length];
      colorIndex++;
      final todasCategorias = _obtenerTodasLasCategorias();
      final emoji = todasCategorias[cat] ?? '❓';
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
      
      // Incrementar contador de transacciones
      _transaccionesCreadas++;
      
      // Cambiar al mes actual para mostrar la transacción recién creada
      final ahora = DateTime.now();
      _mesSeleccionado = DateTime(ahora.year, ahora.month);
    });

    // Guardar en SharedPreferences
    _guardarTransacciones();
    _prefs.setInt('transacciones_creadas', _transaccionesCreadas);
    
    // Track analytics
    AnalyticsService().trackEvent(
      AnalyticsService.eventTransactionCreated,
      properties: {
        AnalyticsService.propTransactionType: _tipoSeleccionado,
        AnalyticsService.propCategory: _categoriaSeleccionada,
        AnalyticsService.propAmount: monto,
      },
    );
    
    // Actualizar ahorros automáticamente
    _actualizarAhorrosDelMes();

    // Limpiar y cerrar
    _tituloController.clear();
    _montoController.clear();
    _justificacionController.clear();
    Navigator.of(context).pop();
    
    // Verificar si debe mostrar popup de conversión a Premium
    _verificarPopupConversion();
  }
  
  void _verificarPopupConversion() {
    // No mostrar si ya es Premium o si ya se mostró el popup
    if (_isPremium || _mostroPopupConversion) return;
    
    // Mostrar después de la 5ta transacción
    if (_transaccionesCreadas == 5) {
      Future.delayed(const Duration(seconds: 1), () {
        _mostrarPopupConversionPremium();
      });
    }
    
    // Mostrar recordatorio después de 15 transacciones
    if (_transaccionesCreadas == 15 && !_mostroPopupConversion) {
      Future.delayed(const Duration(seconds: 1), () {
        _mostrarPopupAhorro();
      });
    }
  }
  
  void _mostrarPopupConversionPremium() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5A4).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                size: 48,
                color: Color(0xFF0EA5A4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Felicidades!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Has registrado 5 transacciones',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Estás aprendiendo a controlar tus finanzas 💪',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF7ED), Color(0xFFFEF2F2)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B), width: 2),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFFF59E0B), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Desbloquea más con Premium',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPopupFeature('Análisis con IA de tus gastos'),
                  _buildPopupFeature('Eventos compartidos ilimitados'),
                  _buildPopupFeature('Sin anuncios'),
                  _buildPopupFeature('16+ monedas'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department, color: Color(0xFFEF4444), size: 16),
                        SizedBox(width: 4),
                        Text(
                          '50% OFF solo hoy',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _mostroPopupConversion = true;
              });
              _prefs.setBool('mostro_popup_conversion', true);
              Navigator.pop(context);
            },
            child: const Text('Tal vez después'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              setState(() {
                _mostroPopupConversion = true;
              });
              _prefs.setBool('mostro_popup_conversion', true);
              Navigator.pop(context);
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PremiumScreen(
                    strings: _strings,
                    source: 'popup_5_transacciones',
                  ),
                ),
              );
              if (result == true) {
                _checkPremiumStatus();
              }
            },
            icon: const Icon(Icons.workspace_premium),
            label: const Text('Ver Premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPopupFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
  
  void _mostrarPopupAhorro() {
    // Calcular ahorro total
    final ingresos = _transacciones
        .where((t) => t['tipo'] == 'Ingreso')
        .fold<double>(0, (sum, t) => sum + (t['monto'] ?? 0));
    final egresos = _transacciones
        .where((t) => t['tipo'] == 'Egreso')
        .fold<double>(0, (sum, t) => sum + (t['monto'] ?? 0).abs());
    final ahorro = ingresos - egresos;

    if (ahorro <= 0) return; // Solo mostrar si hay ahorro positivo
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.trending_up,
                size: 48,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Excelente trabajo!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Has logrado ahorrar',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _appCurrency.formatAmount(ahorro),
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Con Premium podrías optimizar aún más tus finanzas',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '💡 Usuarios Premium ahorran \$247 más al mes en promedio',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0EA5A4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar gratis'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PremiumScreen(
                    strings: _strings,
                    source: 'popup_ahorro',
                  ),
                ),
              );
              if (result == true) {
                _checkPremiumStatus();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5A4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Ahorrar más'),
          ),
        ],
      ),
    );
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
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _categoriaSeleccionada,
                            decoration: const InputDecoration(labelText: 'Categoría'),
                            items: _obtenerTodasLasCategorias().entries.map((entry) {
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
                          if (_isPremium)
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _mostrarDialogoCategoriasPersonalizadas();
                              },
                              icon: const Icon(Icons.add_circle_outline, size: 16),
                              label: const Text('Gestionar categorías'),
                            ),
                        ],
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
    return AppLocalizations(
      strings: _strings,
      child: Builder(
        builder: (context) {
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

    _recordTiming('build HOME SCREEN');
    return Scaffold(
      appBar: AppBar(
        title: Text(_strings.appTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: _strings.transacciones, icon: const Icon(Icons.swap_horiz)),
            Tab(text: _strings.ahorros, icon: const Icon(Icons.savings)),
            Tab(text: _strings.eventosCompartidos, icon: const Icon(Icons.group)),
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
              } else if (value == 'recomendaciones') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RecomendacionesScreen(
                      transacciones: _transacciones,
                      strings: _strings,
                      isPremium: _isPremium,
                    ),
                  ),
                );
              } else if (value == 'configuracion') {
                _showConfigurationDialog();
              } else if (value == 'gastos_fijos') {
                _mostrarDialogoGastosFijos();
              } else if (value == 'categorias_personalizadas') {
                _mostrarDialogoCategoriasPersonalizadas();
              } else if (value == 'monedas_multiples') {
                _mostrarDialogoMonedas();
              } else if (value == 'premium') {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PremiumScreen(strings: _strings)),
                );
                if (result == true) {
                  _checkPremiumStatus();
                }
              } else if (value == 'perfil') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'presupuesto', child: Text('💰 ${_strings.presupuestoMensual}')),
              PopupMenuItem(value: 'gastos_fijos', child: Text('💳 ${_strings.gastosFijos}')),
              if (_isPremium)
                PopupMenuItem(value: 'categorias_personalizadas', child: Text('📂 ${_strings.misCategorias}')),
              if (_isPremium)
                PopupMenuItem(value: 'monedas_multiples', child: Text('💱 ${_strings.monedasMultiples}')),
              PopupMenuItem(value: 'graficos', child: Text('📊 ${_strings.verGraficos}')),
              PopupMenuItem(value: 'reportes', child: Text('📋 ${_strings.reportes}')),
              if (_isPremium)
                PopupMenuItem(value: 'recomendaciones', child: Text('🤝 ${_strings.recomendacionesFinancieras}')),
              if (!_isPremium)
                PopupMenuItem(value: 'premium', child: Text('⭐ Premium')),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'perfil', child: Text('👤 ${_strings.miPerfil}')),
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
          // Pestaña de Eventos Compartidos
          EventosCompartidosScreen(
            strings: _strings,
            currency: _appCurrency,
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'ingreso',
                  backgroundColor: const Color(0xFF0EA5A4),
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
        },
      ),
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
                      title: Text(_strings.gastosFijosTitle),
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
                                  Text(_strings.sinGastosFijos),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _mostrarDialogoGastoFijo();
                                    },
                                    icon: const Icon(Icons.add),
                                    label: Text(_strings.agregarGastoFijo),
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
                                      color: gastoFijo['activo'] == true ? const Color(0xFF0EA5A4) : Colors.grey,
                                    ),
                                    title: Text(gastoFijo['nombre'] ?? 'Gasto'),
                                    subtitle: Text(
                                      'Día ${gastoFijo['diaVencimiento']} • ${_appCurrency.formatAmount(gastoFijo['monto'] as double)}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Color(0xFF0EA5A4)),
                                          onPressed: () => _mostrarDialogoGastoFijo(index: index),
                                          tooltip: 'Editar',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _eliminarGastoFijo(index),
                                          tooltip: 'Eliminar',
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
          // Banner Premium - Solo mostrar si NO es premium
          if (!_isPremium)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PremiumScreen(strings: _strings)),
                  );
                  if (result == true) {
                    _checkPremiumStatus();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _strings.desbloquearPremium,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Text(
                              _strings.verMas,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPremiumBenefitRow(_strings.categoriasPersonalizadas),
                                const SizedBox(height: 6),
                                _buildPremiumBenefitRow(_strings.monedasMultiplesBanner),
                                const SizedBox(height: 6),
                                _buildPremiumBenefitRow(_strings.reportesAvanzados),
                                const SizedBox(height: 6),
                                _buildPremiumBenefitRow(_strings.marketingAfiliacion),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Tarjetas de ingresos y egresos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                // Tarjeta de Ingresos
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: const Color(0xFFE7F8F7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFF0EA5A4), width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trending_up, color: Color(0xFF0EA5A4), size: 28),
                              const SizedBox(width: 12),
                              Text(_strings.ingresos, style: const TextStyle(fontSize: 16, color: Color(0xFF0EA5A4), fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(_appCurrency.formatAmount(ingresos), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0EA5A4))),
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
                                  backgroundColor: Color(0xFF0EA5A4),
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
            // Banner publicitario - Solo mostrar si NO es premium
            if (!_isPremium && _isBannerTransaccionesLoaded && _bannerAdTransacciones != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                alignment: Alignment.center,
                width: _bannerAdTransacciones!.size.width.toDouble(),
                height: _bannerAdTransacciones!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAdTransacciones!),
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
              color: const Color(0xFFE7F8F7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF0EA5A4), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.savings, color: Color(0xFF0EA5A4), size: 32),
                        const SizedBox(width: 16),
                        Text(_strings.ahorrosAcumulados, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _appCurrency.formatAmount(totalAhorros),
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Color(0xFF0EA5A4)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _strings.totalAcumuladoMeses,
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
                label: Text(_strings.extraccionDinero),
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
                  Text(
                    _strings.sinRegistrosAhorros,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _strings.registraTransaccionesAhorros,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    _strings.historialAhorrosMes,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
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

                      final meses = _strings.nombresMeses;

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
                                        ? _strings.extraccionAhorro
                                        : (anio > 0 ? '${meses[mes - 1]} $anio' : _strings.mesDesconocido),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tipo == 'extraccion'
                                        ? (ahorro['nota'] != null && (ahorro['nota'] as String).isNotEmpty
                                            ? ahorro['nota']
                                            : _strings.usoReservas)
                                        : (montoPositivo ? _strings.balancePositivo : _strings.balanceNegativo),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: tipo == 'extraccion'
                                          ? const Color(0xFFEF4444)
                                          : (montoPositivo ? const Color(0xFF0EA5A4) : const Color(0xFFEF4444)),
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
                                      : (montoPositivo ? const Color(0xFF0EA5A4) : const Color(0xFFEF4444)),
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
          // Banner publicitario - Solo mostrar si NO es premium
          if (!_isPremium && _isBannerAhorrosLoaded && _bannerAdAhorros != null)
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 16),
              alignment: Alignment.center,
              width: _bannerAdAhorros!.size.width.toDouble(),
              height: _bannerAdAhorros!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAdAhorros!),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumBenefitRow(String benefit) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            benefit,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
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
                      Text(
                        strings.distribucionMensual,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
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
                      Text(
                        strings.distribucionAnual,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
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

class RecomendacionesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> transacciones;
  final AppStrings strings;
  final bool isPremium;

  const RecomendacionesScreen({
    super.key,
    required this.transacciones,
    required this.strings,
    required this.isPremium,
  });

  // Mapa de URLs de afiliación por tipo de servicio
  static const Map<String, String> urlsAfiliacion = {
    'seguros': 'https://afiliados.seguros-medicos.com/ref/zentavo',
    'tarjetas': 'https://afiliados.tarjetas-credito.com/ref/zentavo',
    'ahorros': 'https://afiliados.cuentas-ahorro.com/ref/zentavo',
  };

  Future<void> _abrirURL(String urlKey) async {
    final url = urlsAfiliacion[urlKey] ?? '';
    if (url.isEmpty) return;

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('No se pudo abrir la URL: $url');
      }
    } catch (e) {
      print('Error al abrir URL: $e');
    }
  }

  Map<String, double> _calcularGastosPorCategoria() {
    final Map<String, double> gastosPorCategoria = {};
    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1);
    
    for (var transaccion in transacciones) {
      final tipo = transaccion['tipo'] as String;
      final fechaStr = transaccion['fecha'] as String;
      final fecha = DateTime.parse(fechaStr);
      final categoria = transaccion['categoria'] as String;
      final monto = transaccion['monto'] as double;
      
      if (tipo == 'Egreso' && fecha.isAfter(inicioMes)) {
        gastosPorCategoria[categoria] = 
            (gastosPorCategoria[categoria] ?? 0) + monto;
      }
    }
    
    return gastosPorCategoria;
  }

  double _calcularCapacidadAhorro() {
    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1);
    double ingresos = 0;
    double egresos = 0;
    
    for (var transaccion in transacciones) {
      final tipo = transaccion['tipo'] as String;
      final fechaStr = transaccion['fecha'] as String;
      final fecha = DateTime.parse(fechaStr);
      final monto = transaccion['monto'] as double;
      
      if (fecha.isAfter(inicioMes)) {
        if (tipo == 'Ingreso') {
          ingresos += monto;
        } else if (tipo == 'Egreso') {
          egresos += monto;
        }
      }
    }
    
    return ingresos > 0 ? ((ingresos - egresos) / ingresos) * 100 : 0;
  }

  List<Widget> _generarRecomendaciones() {
    final recomendaciones = <Widget>[];
    final gastosPorCategoria = _calcularGastosPorCategoria();
    final capacidadAhorro = _calcularCapacidadAhorro();
    
    // Recomendación por gastos en salud
    final salud = gastosPorCategoria.entries.firstWhere(
      (e) => e.key.toLowerCase().contains('salud'),
      orElse: () => const MapEntry('', 0),
    );
    if (salud.value > 500) {
      recomendaciones.add(_buildRecomendacionCard(
        icon: Icons.local_hospital,
        title: strings.seguros,
        description: strings.recomendacionSalud,
        color: const Color(0xFFEF4444),
        urlKey: 'seguros',
      ));
    }
    
    // Recomendación por gastos en transporte
    final transporte = gastosPorCategoria.entries.firstWhere(
      (e) => e.key.toLowerCase().contains('transporte'),
      orElse: () => const MapEntry('', 0),
    );
    if (transporte.value > 300) {
      recomendaciones.add(_buildRecomendacionCard(
        icon: Icons.credit_card,
        title: strings.tarjetasCredito,
        description: strings.recomendacionTransporte,
        color: const Color(0xFFF59E0B),
        urlKey: 'tarjetas',
      ));
    }
    
    // Recomendación por alta capacidad de ahorro
    if (capacidadAhorro > 20) {
      recomendaciones.add(_buildRecomendacionCard(
        icon: Icons.savings,
        title: strings.cuentasAhorro,
        description: strings.recomendacionAhorro,
        color: const Color(0xFF10B981),
        urlKey: 'ahorros',
      ));
    }
    
    // Si no hay recomendaciones, mostrar mensaje
    if (recomendaciones.isEmpty) {
      recomendaciones.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.analytics, size: 64, color: Color(0xFF9CA3AF)),
                const SizedBox(height: 16),
                Text(
                  strings.recomendacionesDescripcion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return recomendaciones;
  }

  Widget _buildRecomendacionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String urlKey,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _abrirURL(urlKey),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(strings.verOfertas),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recomendaciones = _generarRecomendaciones();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.recomendacionesFinancieras,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: !isPremium
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      size: 80,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      strings.desbloquearPremium,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.recomendacionesDescripcion,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => PremiumScreen(strings: strings)),
                        );
                      },
                      icon: const Icon(Icons.workspace_premium),
                      label: Text(strings.verMas),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.serviciosRecomendados,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          strings.recomendacionesDescripcion,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...recomendaciones,
                  const SizedBox(height: 24),
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
        title: Text(strings.manualDeUso, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.manualBienvenida,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Text(strings.manualTransaccionesTitulo, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(strings.manualTransaccionesP1),
              Text(strings.manualTransaccionesP2),
              Text(strings.manualTransaccionesP3),
              const SizedBox(height: 16),
              Text(strings.manualAhorrosTitulo, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(strings.manualAhorrosP1),
              Text(strings.manualAhorrosP2),
              const SizedBox(height: 16),
              Text(strings.manualGastosFijosTitulo, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(strings.manualGastosFijosP1),
              Text(strings.manualGastosFijosP2),
              Text(strings.manualGastosFijosP3),
              const SizedBox(height: 16),
              Text(strings.manualPresupuestoTitulo, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(strings.manualPresupuestoP1),
              const SizedBox(height: 16),
              Text(strings.manualReportesTitulo, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(strings.manualReportesP1),
              Text(strings.manualReportesP2),
              const SizedBox(height: 16),
              Text(strings.manualSeguridadTitulo, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(strings.manualSeguridadP1),
              const SizedBox(height: 16),
              Text(strings.manualEventosTitulo, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(strings.manualEventosP1),
              Text(strings.manualEventosP2),
              Text(strings.manualEventosP3),
              Text(strings.manualEventosP4),
              const SizedBox(height: 16),
              Text(strings.manualAnalyticsTitulo, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(strings.manualAnalyticsP1),
              Text(strings.manualAnalyticsP2),
            ],
          ),
        ),
      ),
    );
  }
}



