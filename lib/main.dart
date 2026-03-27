import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
import 'recurring_transactions.dart';
import 'backup_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'currency_exchange_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ================================
// ...existing code...

void main() => runApp(const ExpenseApp());

List<Map<String, dynamic>> _decodeMapListIsolate(String rawJson) {
  final List<dynamic> decoded = jsonDecode(rawJson);
  return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
}

Map<String, dynamic> _decodeMapIsolate(String rawJson) {
  final Map<String, dynamic> decoded = jsonDecode(rawJson);
  return decoded;
}

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
          home: HomePage(onThemeModeChanged: _setThemeMode),
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
  
  // Ahorros en monedas extranjeras (Premium)
  // Map: código de moneda -> lista de transacciones
  Map<String, List<Map<String, dynamic>>> _ahorrosMonedas = {};
  
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

  // Transacciones recurrentes
  List<RecurringTransaction> _transaccionesRecurrentes = [];

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

  // Modo seguro: diferir contenido pesado al entrar en principal
  bool _mainTabHeavyReady = false;
  bool _mostrarListaCompleta = false;
  int _lastTabIndex = 0;

  // Cache de transacciones del mes para evitar recomputaciones costosas por frame
  String? _cacheMonthKey;
  String? _cacheDataStamp;
  List<Map<String, dynamic>> _cacheTransaccionesMes = [];
  
  // Performance timing
  late DateTime _appStartTime;
  final Map<String, DateTime> _timingMarkers = {};

  void _recordTiming(String marker) {
    if (!kDebugMode) return;
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

  AppLanguage _getDefaultLanguageFromDeviceLocale(Locale locale) {
    switch (locale.languageCode.toLowerCase()) {
      case 'en':
        return AppLanguage.english;
      case 'pt':
        return AppLanguage.portuguese;
      case 'it':
        return AppLanguage.italian;
      case 'zh':
        return AppLanguage.chinese;
      case 'ja':
        return AppLanguage.japanese;
      case 'es':
      default:
        return AppLanguage.spanish;
    }
  }

  AppCurrency _getDefaultCurrencyFromDeviceLocale(Locale locale) {
    final countryCode = (locale.countryCode ?? '').toUpperCase();

    switch (countryCode) {
      case 'US':
        return AppCurrency.usd;
      case 'MX':
        return AppCurrency.mxn;
      case 'AR':
        return AppCurrency.ars;
      case 'CL':
        return AppCurrency.clp;
      case 'BR':
        return AppCurrency.brl;
      case 'GB':
        return AppCurrency.gbp;
      case 'IN':
        return AppCurrency.inr;
      case 'JP':
        return AppCurrency.jpy;
      case 'CA':
        return AppCurrency.cad;
      case 'AU':
        return AppCurrency.aud;
      case 'CH':
        return AppCurrency.chf;
      case 'CN':
        return AppCurrency.cny;
      case 'SE':
        return AppCurrency.sek;
      case 'NO':
        return AppCurrency.nok;
      case 'ZA':
        return AppCurrency.zar;
      case 'ES':
      case 'IT':
      case 'PT':
      case 'FR':
      case 'DE':
      case 'NL':
      case 'BE':
      case 'AT':
      case 'IE':
      case 'FI':
      case 'GR':
      case 'LU':
      case 'SI':
      case 'SK':
      case 'EE':
      case 'LV':
      case 'LT':
      case 'CY':
      case 'MT':
      case 'HR':
        return AppCurrency.eur;
      default:
        return AppCurrency.usd;
    }
  }

  double _parseAmountInput(String value) {
    final normalized = value.trim().replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  List<TextInputFormatter> _amountInputFormatters() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}$')),
    ];
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Solo verificar si compró Premium
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
      supported = await _localAuth.isDeviceSupported().timeout(const Duration(seconds: 3));
    } catch (_) {}
    try {
      canCheck = await _localAuth.canCheckBiometrics.timeout(const Duration(seconds: 3));
    } catch (_) {}

    if (!supported && !canCheck) {
      setState(() {
        _isAuthenticated = true;
        _authChecked = true;
      });
      return;
    }

    if (mounted && !_authChecked) {
      setState(() {
        _authChecked = true;
      });
    }

    bool success = false;
    try {
      success = await _localAuth.authenticate(
        localizedReason: 'Verifica tu identidad con biometría o código del dispositivo',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      ).timeout(const Duration(seconds: 15), onTimeout: () => false);
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
      if (mounted && _tabController.index != _lastTabIndex) {
        _lastTabIndex = _tabController.index;
        setState(() {});
      }
    });
    _isAuthenticated = true;
    _authChecked = true;
    _mesSeleccionado = DateTime(DateTime.now().year, DateTime.now().month);
    _diaVencimientoSeleccionado = 1;
    _recordTiming('Vars initialized');
    // Verificar onboarding
    _checkOnboarding();
    // Cargar datos de forma asincrónica para no bloquear la UI
    _cargarTransaccionesAsync();

    if (!kSafeStartupMode) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        _inicializarNotificaciones();
        _recordTiming('Notifications initialized (deferred)');
      });

      Future.delayed(const Duration(seconds: 4), () {
        if (!mounted) return;
        _initializeAnalytics();
        _recordTiming('Analytics initialized (deferred)');
      });

      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        _checkPremiumStatus();
        _recordTiming('Premium status checked (deferred)');
      });

      Future.delayed(const Duration(seconds: 6), () {
        if (!mounted) return;
        if (!kIsWeb) {
          _initializeMobileAds();
          _recordTiming('AdMob initialized (deferred)');
        }
      });
    } else {
      _recordTiming('Safe startup mode enabled');
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _mainTabHeavyReady = true;
      });
    });
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
    Future.delayed(const Duration(milliseconds: 800), () async {
      try {
        if (!mounted) return;
        _recordTiming('_cargarTransaccionesAsync START (non-blocking)');
        await _cargarTransacciones();
        if (!kSafeStartupMode) {
          Future.delayed(const Duration(seconds: 5), () {
            if (!mounted) return;
            _verificarYEnviarRecordatorios();
          });
        }
        _recordTiming('_cargarTransaccionesAsync COMPLETE');
      } catch (e, stackTrace) {
        print('Error en carga inicial de datos: $e');
        print(stackTrace);
      }
    });
  }

  Future<void> _cargarTransacciones() async {
    _recordTiming('_cargarTransacciones START');
    _prefs = await SharedPreferences.getInstance();
    _recordTiming('SharedPreferences inicializado');
    final String? datosGuardados = _prefs.getString('transacciones');
    _recordTiming('Transacciones cargadas de prefs');
    
    // Cargar idioma y moneda (por defecto según locale del dispositivo en primera instalación)
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;

    if (_prefs.containsKey('app_language')) {
      final String languageCode = _prefs.getString('app_language') ?? 'spanish';
      _appLanguage = AppLanguage.values.firstWhere(
        (lang) => lang.toString().split('.').last == languageCode,
        orElse: () => AppLanguage.spanish,
      );
    } else {
      _appLanguage = _getDefaultLanguageFromDeviceLocale(deviceLocale);
      await _prefs.setString('app_language', _appLanguage.toString().split('.').last);
    }
    _recordTiming('Idioma cargado');

    if (_prefs.containsKey('app_currency')) {
      final String currencyCode = _prefs.getString('app_currency') ?? 'usd';
      _appCurrency = AppCurrency.values.firstWhere(
        (curr) => curr.toString().split('.').last == currencyCode,
        orElse: () => AppCurrency.usd,
      );
    } else {
      _appCurrency = _getDefaultCurrencyFromDeviceLocale(deviceLocale);
      await _prefs.setString('app_currency', _appCurrency.toString().split('.').last);
    }
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
        _registrosAhorros = await compute(_decodeMapListIsolate, ahorrosGuardados);
      } catch (e) {
        print('Error al cargar ahorros: $e');
      }
    }
    _recordTiming('Ahorros cargados');
    
    // Cargar ahorros en monedas extranjeras (Premium)
    final String? ahorrosMonedasGuardados = _prefs.getString('ahorros_monedas');
    if (ahorrosMonedasGuardados != null && _isPremium) {
      try {
        final Map<String, dynamic> decoded = await compute(
          _decodeMapIsolate,
          ahorrosMonedasGuardados,
        );
        _ahorrosMonedas = decoded.map((key, value) {
          return MapEntry(
            key,
            (value as List).map((item) => Map<String, dynamic>.from(item)).toList(),
          );
        });
      } catch (e) {
        print('Error al cargar ahorros en monedas: $e');
      }
    }
    _recordTiming('Ahorros en monedas cargados');

    // Cargar gastos fijos
    final String? gastosFijosGuardados = _prefs.getString('gastos_fijos');
    if (gastosFijosGuardados != null) {
      try {
        _gastosFijos = await compute(_decodeMapListIsolate, gastosFijosGuardados);
      } catch (e) {
        print('Error al cargar gastos fijos: $e');
      }
    }
    _recordTiming('Gastos fijos cargados');

    // Cargar categorías personalizadas (Premium)
    final String? categoriasGuardadas = _prefs.getString('categorias_personalizadas');
    if (categoriasGuardadas != null) {
      try {
        final Map<String, dynamic> decoded = await compute(
          _decodeMapIsolate,
          categoriasGuardadas,
        );
        _categoriasPersonalizadas = decoded.map((key, value) => MapEntry(key, value.toString()));
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
        _monedasDisponibles = decoded
            .map((item) => AppCurrency.values.firstWhere(
                  (c) => c.toString() == item,
                  orElse: () => AppCurrency.usd,
                ))
            .toList();
      } catch (e) {
        print('Error al cargar monedas adicionales: $e');
      }
    }
    
    // Cargar transacciones recurrentes
    final String? recurrentesGuardadas = _prefs.getString('transacciones_recurrentes');
    if (recurrentesGuardadas != null) {
      try {
        final List<Map<String, dynamic>> decoded = await compute(
          _decodeMapListIsolate,
          recurrentesGuardadas,
        );
        _transaccionesRecurrentes = decoded
            .map((item) => RecurringTransaction.fromJson(item))
            .toList();
        
        // Generar transacciones pendientes automáticamente
        Future(() async {
          try {
            await _generarTransaccionesRecurrentes();
          } catch (e) {
            print('Error al generar recurrencias: $e');
          }
        });
      } catch (e) {
        print('Error al cargar recurrencias: $e');
      }
    }
    _recordTiming('Recurrencias cargadas y generadas');
    
    _recordTiming('Backup automático omitido en startup');
    
    if (datosGuardados != null) {
      try {
        final List<Map<String, dynamic>> decoded = await compute(
          _decodeMapListIsolate,
          datosGuardados,
        );
        _transacciones.clear();
        _transacciones.addAll(decoded);
        Future(() {
          if (!mounted) return;
          _verificarPresupuesto();
        });
      } catch (e) {
        print('Error al cargar transacciones: $e');
      }
    }

    if (mounted) {
      setState(() {});
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
                  title: Text(_strings.analytics),
                  subtitle: Text(_strings.verEstadisticas),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.backup, color: Color(0xFF06B6D4)),
                  title: Text(_strings.backupYRestauracion),
                  subtitle: Text(_strings.guardarYRestaurarDatos),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    _mostrarDialogoBackupRestauracion();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications, color: Color(0xFFF59E0B)),
                  title: Text(_strings.notificaciones),
                  subtitle: Text(_strings.configurarRecordatorios),
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
                  title: Text(_strings.tutorial),
                  subtitle: Text(_strings.verTutorialDeNuevo),
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
                  leading: const Icon(Icons.support_agent, color: Color(0xFF8B5CF6)),
                  title: Text(_strings.servicioTecnico),
                  subtitle: Text(_strings.servicioTecnicoDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    _mostrarServicioTecnico();
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.share, color: Color(0xFF0EA5A4), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _strings.compartirApp,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _strings.comparteEscaneaApp,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Opción: Mostrar código QR
              Card(
                elevation: 0,
                color: const Color(0xFFE7F8F7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF0EA5A4), width: 1.5),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _mostrarQRCode();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5A4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.qr_code_2,
                            color: Color(0xFF0EA5A4),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _strings.mostrarCodigoQR,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0EA5A4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _strings.escaneaQRDescripcion,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF0EA5A4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Opción: Escanear código QR
              Card(
                elevation: 0,
                color: const Color(0xFFFEF3C7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _escanearQRCode();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            color: Color(0xFFF59E0B),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _strings.escanearCodigoQR,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Opción: Compartir texto
              Card(
                elevation: 0,
                color: const Color(0xFFF3F4F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF9CA3AF), width: 1.5),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _compartirTexto();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9CA3AF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.text_fields,
                            color: Color(0xFF9CA3AF),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _strings.compartirTexto,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _strings.cerrar,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _compartirTexto() {
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

  void _mostrarQRCode() {
    // URL de descarga de la app (puedes cambiar esto por tu URL real)
    const String appURL = 'https://github.com/florenciaballonlp-create/Zentavo';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.qr_code_2, color: Color(0xFF0EA5A4), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _strings.codigoQRApp,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _strings.escaneaQRDescripcion,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0EA5A4),
                    width: 3,
                  ),
                ),
                child: QrImageView(
                  data: appURL,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                  embeddedImage: const AssetImage('assets/images/logo.png'),
                  embeddedImageStyle: const QrEmbeddedImageStyle(
                    size: Size(40, 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Zentavo',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0EA5A4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F8F7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF0EA5A4),
                    width: 1,
                  ),
                ),
                child: Text(
                  appURL,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0EA5A4),
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _strings.cerrar,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _escanearQRCode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              _strings.escanearCodigoQR,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0EA5A4),
            foregroundColor: Colors.white,
          ),
          body: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final String? code = barcode.rawValue;
                    if (code != null) {
                      Navigator.of(context).pop();
                      _procesarQRCode(code);
                      break;
                    }
                  }
                },
              ),
              // Overlay con marco de escaneo
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF0EA5A4),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              // Instrucciones en la parte inferior
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _strings.escaneaQRDescripcion,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _procesarQRCode(String url) {
    // Intentar abrir la URL escaneada
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '¡QR Escaneado!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'URL detectada:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  url,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: Color(0xFF0EA5A4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Deseas abrir este enlace en tu navegador?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _strings.cancelar,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final Uri uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No se pudo abrir el enlace'),
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al procesar el QR: $e'),
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5A4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Abrir enlace',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarServicioTecnico() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.support_agent, color: Color(0xFF8B5CF6), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _strings.servicioTecnico,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _strings.servicioTecnicoDesc,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Opción: Preguntas Frecuentes
                Card(
                  elevation: 0,
                  color: const Color(0xFFE0E7FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _mostrarPreguntasFrecuentes();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.help_outline,
                              color: Color(0xFF6366F1),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _strings.preguntasFrecuentes,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'FAQ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF6366F1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Opción: Contáctenos
                Card(
                  elevation: 0,
                  color: const Color(0xFFDCFCE7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _mostrarContactenos();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF22C55E),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _strings.contactenos,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _strings.contactenosDesc,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF22C55E),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _strings.cerrar,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarPreguntasFrecuentes() {
    // Lista de preguntas frecuentes
    final List<Map<String, String>> faqs = [
      {
        'pregunta': '¿Cómo agrego una nueva transacción?',
        'respuesta': 'Toca el botón "+" en la pantalla principal y selecciona "Ingreso" o "Egreso". Completa los campos requeridos y guarda.',
      },
      {
        'pregunta': '¿Puedo usar múltiples monedas?',
        'respuesta': 'Sí, Zentavo soporta 16 monedas diferentes. Puedes cambiar la moneda principal en Configuración > Moneda, y registrar transacciones en cualquier moneda extranjera.',
      },
      {
        'pregunta': '¿Cómo configuro un presupuesto mensual?',
        'respuesta': 'Ve a la pestaña "Transacciones", toca el ícono de configuración (⚙️) arriba a la derecha, y selecciona "Establecer presupuesto mensual".',
      },
      {
        'pregunta': '¿Puedo exportar mis datos?',
        'respuesta': 'Sí, puedes exportar en múltiples formatos: PDF, Excel, CSV, JSON. Ve a la pestaña "Transacciones" y toca el botón de exportar.',
      },
      {
        'pregunta': '¿Los datos están seguros?',
        'respuesta': 'Todos tus datos se almacenan localmente en tu dispositivo. Puedes habilitar protección con biometría en Configuración.',
      },
      {
        'pregunta': '¿Qué incluye la versión Premium?',
        'respuesta': 'Premium incluye: categorías personalizadas, múltiples monedas, reportes avanzados, análisis predictivo, respaldos en la nube, y más funciones premium.',
      },
      {
        'pregunta': '¿Cómo funcionan los ahorros en monedas extranjeras?',
        'respuesta': 'Ve a la pestaña "Ahorros" y toca "Ahorros en Monedas". Puedes agregar, retirar y ver el historial de transacciones en cualquiera de las 16 monedas soportadas.',
      },
      {
        'pregunta': '¿Puedo programar transacciones recurrentes?',
        'respuesta': 'Sí, en la pestaña "Gastos Fijos" puedes configurar gastos que se repiten mensualmente, como alquiler, servicios, suscripciones, etc.',
      },
      {
        'pregunta': '¿Cómo activo el tema oscuro?',
        'respuesta': 'Ve a Configuración > Tema y selecciona "Oscuro" o "Automático" para que siga el tema del sistema.',
      },
      {
        'pregunta': '¿Puedo compartir eventos de gastos?',
        'respuesta': 'Sí, usa la función "Eventos Compartidos" para planificar gastos grupales con amigos o familia. Genera un código QR para que otros se unan.',
      },
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.help_outline, color: Color(0xFF6366F1), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _strings.preguntasFrecuentes,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                final faq = faqs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: const Color(0xFFF3F4F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      faq['pregunta']!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq['respuesta']!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _strings.cerrar,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarContactenos() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.email_outlined, color: Color(0xFF22C55E), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _strings.contactenos,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _strings.informacionContacto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                // Email de soporte
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF22C55E),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.email,
                            color: Color(0xFF22C55E),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _strings.emailSoporte,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'soporte@zentavo.com',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final Uri emailUri = Uri(
                              scheme: 'mailto',
                              path: 'soporte@zentavo.com',
                              query: 'subject=Soporte Zentavo&body=Describe tu consulta aquí...',
                            );
                            try {
                              if (await canLaunchUrl(emailUri)) {
                                await launchUrl(emailUri);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No se pudo abrir el cliente de correo'),
                                      backgroundColor: Color(0xFFEF4444),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.send, size: 18),
                          label: Text(_strings.enviarEmail),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Horario de atención
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Color(0xFF6366F1),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _strings.horarioAtencion,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Lunes a Viernes: 9:00 AM - 6:00 PM',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sábados: 10:00 AM - 2:00 PM',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Zona horaria: UTC-5 (COT)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Información adicional
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Responderemos tu consulta en un máximo de 24 horas.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _strings.cerrar,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
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
          DateTime? fechaTransaccion;
          try {
            fechaTransaccion = DateTime.parse(fechaStr);
          } catch (_) {
            return false;
          }
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
            inputFormatters: _amountInputFormatters(),
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
                    _parseAmountInput(presupuestoController.text);
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

  void _mostrarDialogoGraficosReportes() {
    showDialog(
      context: context,
      builder: (_) {
        return DefaultTabController(
          length: 2,
          child: Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  AppBar(
                    title: Text(_strings.graficosEInformes),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                    bottom: TabBar(
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.bar_chart),
                          text: _strings.verGraficos,
                        ),
                        Tab(
                          icon: const Icon(Icons.description),
                          text: _strings.reportes,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildGraficosTab(),
                        _buildReportesTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGraficosTab() {
    return SingleChildScrollView(
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
                      _strings.distribucionMensual,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: _obtenerDatosGraficoMensual(),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _strings.distribucionAnual,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: _obtenerDatosGraficoAnual(),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportesTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 80, color: Color(0xFF0EA5A4)),
            const SizedBox(height: 24),
            Text(
              _strings.seleccionaFormatoReporte,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (_isPremium)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  '✨ Exportación anual disponible',
                  style: TextStyle(fontSize: 14, color: Color(0xFFF59E0B)),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(_strings.reportePDF),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.table_chart),
              label: Text(_strings.reporteExcel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5A4),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
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
        ),
      ),
    );
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
  
  // Métodos para ahorros en monedas extranjeras
  Future<void> _guardarAhorrosMonedas() async {
    try {
      final String datosJSON = jsonEncode(_ahorrosMonedas);
      await _prefs.setString('ahorros_monedas', datosJSON);
    } catch (e) {
      print('Error al guardar ahorros en monedas: $e');
    }
  }
  
  double _calcularTotalMoneda(String codigoMoneda) {
    final transacciones = _ahorrosMonedas[codigoMoneda] ?? [];
    return transacciones.fold(0.0, (sum, item) => sum + (item['monto'] as num).toDouble());
  }
  
  void _agregarAhorroMoneda(AppCurrency moneda, double monto, String nota) {
    final codigoMoneda = moneda.toString().split('.').last;
    
    if (!_ahorrosMonedas.containsKey(codigoMoneda)) {
      _ahorrosMonedas[codigoMoneda] = [];
    }
    
    setState(() {
      _ahorrosMonedas[codigoMoneda]!.add({
        'monto': monto,
        'fecha': DateTime.now().toIso8601String(),
        'nota': nota,
      });
    });
    
    _guardarAhorrosMonedas();
  }
  
  void _eliminarTransaccionMoneda(String codigoMoneda, int index) {
    setState(() {
      _ahorrosMonedas[codigoMoneda]?.removeAt(index);
      if (_ahorrosMonedas[codigoMoneda]?.isEmpty ?? false) {
        _ahorrosMonedas.remove(codigoMoneda);
      }
    });
    _guardarAhorrosMonedas();
  }
  
  // Método para manejar compra de moneda extranjera
  void _agregarCompraMonedaExtranjera(
    AppCurrency monedaOrigen,
    AppCurrency monedaDestino,
    double montoOrigen,
    String nota,
  ) {
    // Convertir el monto de la moneda origen a la moneda destino
    final montoConvertido = CurrencyExchangeService.convert(
      amount: montoOrigen,
      from: monedaOrigen,
      to: monedaDestino,
    );
    
    // Agregar el monto convertido como ahorro en la moneda destino
    final notaCompleta = nota.isNotEmpty 
        ? '$nota (${_strings.compraDe} ${montoOrigen.toStringAsFixed(2)} ${monedaOrigen.symbol})'
        : '${_strings.compraMoneda} - ${montoOrigen.toStringAsFixed(2)} ${monedaOrigen.symbol}';
    
    _agregarAhorroMoneda(monedaDestino, montoConvertido, notaCompleta);
    
    // Mostrar confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_strings.compraExitosa}\n${monedaOrigen.formatAmount(montoOrigen)} → ${monedaDestino.formatAmount(montoConvertido)}',
        ),
        backgroundColor: const Color(0xFF22C55E),
        duration: const Duration(seconds: 4),
      ),
    );
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
    final monto = _parseAmountInput(_ahorroController.text);
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
                inputFormatters: _amountInputFormatters(),
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
  
  // ===== MÉTODOS PARA AHORROS EN MONEDAS EXTRANJERAS =====
  
  void _mostrarDialogoAhorrosMonedas() {
    if (!_isPremium) {
      _mostrarDialogoPremiumRequerido(_strings.ahorrosMonedas);
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Obtener monedas con saldo
            final monedasConSaldo = _ahorrosMonedas.keys.toList();
            
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Color(0xFF0EA5A4)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_strings.ahorrosMonedas)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: monedasConSaldo.isEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.currency_exchange, size: 64, color: Color(0xFFD1D5DB)),
                          const SizedBox(height: 16),
                          Text(
                            _strings.sinAhorrosMonedas,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _strings.agregaAhorroMoneda,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: monedasConSaldo.length,
                        itemBuilder: (context, index) {
                          final codigoMoneda = monedasConSaldo[index];
                          final moneda = AppCurrency.values.firstWhere(
                            (m) => m.toString().split('.').last == codigoMoneda,
                          );
                          final total = _calcularTotalMoneda(codigoMoneda);
                          
                          return Card(
                            elevation: 0,
                            color: const Color(0xFFF9FAFB),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFE7F8F7),
                                child: Text(
                                  moneda.symbol,
                                  style: const TextStyle(
                                    color: Color(0xFF0EA5A4),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                moneda.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                moneda.formatAmount(total),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: total >= 0 ? const Color(0xFF0EA5A4) : const Color(0xFFEF4444),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0EA5A4)),
                                    tooltip: _strings.agregar,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _mostrarDialogoAgregarRetiro(moneda, true);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEF4444)),
                                    tooltip: _strings.retirar,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _mostrarDialogoAgregarRetiro(moneda, false);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.history, color: Color(0xFF6B7280)),
                                    tooltip: _strings.historial,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _mostrarHistorialMoneda(moneda);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(_strings.cerrar),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _mostrarDialogoSeleccionarMoneda();
                  },
                  icon: const Icon(Icons.add),
                  label: Text(_strings.nuevaMoneda),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5A4),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _mostrarDialogoSeleccionarMoneda() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_strings.seleccionarMoneda),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppCurrency.values.length,
              itemBuilder: (context, index) {
                final moneda = AppCurrency.values[index];
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE7F8F7),
                    child: Text(
                      moneda.symbol,
                      style: const TextStyle(
                        color: Color(0xFF0EA5A4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(moneda.name),
                  onTap: () {
                    Navigator.of(context).pop();
                    _mostrarDialogoAgregarRetiro(moneda, true);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_strings.cancelar),
            ),
          ],
        );
      },
    );
  }
  
  void _mostrarDialogoAgregarRetiro(AppCurrency moneda, bool esDeposito) {
    final montoController = TextEditingController();
    final notaController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            esDeposito ? _strings.agregarAhorro : _strings.retirarAhorro,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${esDeposito ? _strings.depositarEn : _strings.retirarDe} ${moneda.name}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: montoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: _amountInputFormatters(),
                decoration: InputDecoration(
                  labelText: _strings.monto,
                  border: const OutlineInputBorder(),
                  prefixText: moneda.symbol,
                  hintText: '0.00',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notaController,
                decoration: InputDecoration(
                  labelText: _strings.notaOpcional,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_strings.cancelar),
            ),
            ElevatedButton(
              onPressed: () {
                final monto = _parseAmountInput(montoController.text);
                if (monto <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_strings.ingresaMontoValido)),
                  );
                  return;
                }
                
                final montoFinal = esDeposito ? monto : -monto;
                _agregarAhorroMoneda(moneda, montoFinal, notaController.text.trim());
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      esDeposito
                          ? '${_strings.depositoExitoso} ${moneda.formatAmount(monto)}'
                          : '${_strings.retiroExitoso} ${moneda.formatAmount(monto)}',
                    ),
                    backgroundColor: const Color(0xFF0EA5A4),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: esDeposito ? const Color(0xFF0EA5A4) : const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: Text(esDeposito ? _strings.depositar : _strings.retirar),
            ),
          ],
        );
      },
    ).then((_) {
      montoController.dispose();
      notaController.dispose();
    });
  }
  
  void _mostrarHistorialMoneda(AppCurrency moneda) {
    final codigoMoneda = moneda.toString().split('.').last;
    final transacciones = _ahorrosMonedas[codigoMoneda] ?? [];
    
    // Ordenar por fecha (más recientes primero)
    final transaccionesOrdenadas = [...transacciones]
      ..sort((a, b) {
        final fechaA = DateTime.parse(a['fecha']);
        final fechaB = DateTime.parse(b['fecha']);
        return fechaB.compareTo(fechaA);
      });
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE7F8F7),
                child: Text(
                  moneda.symbol,
                  style: const TextStyle(
                    color: Color(0xFF0EA5A4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_strings.historial} - ${moneda.name}',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: transacciones.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history, size: 64, color: Color(0xFFD1D5DB)),
                      const SizedBox(height: 16),
                      Text(
                        _strings.sinTransacciones,
                        style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                      ),
                    ],
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: transaccionesOrdenadas.length,
                    itemBuilder: (context, index) {
                      final transaccion = transaccionesOrdenadas[index];
                      final monto = (transaccion['monto'] as num).toDouble();
                      final fecha = DateTime.parse(transaccion['fecha']);
                      final nota = transaccion['nota'] ?? '';
                      final esDeposito = monto > 0;
                      
                      final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');
                      
                      return Card(
                        elevation: 0,
                        color: const Color(0xFFF9FAFB),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            esDeposito ? Icons.arrow_downward : Icons.arrow_upward,
                            color: esDeposito ? const Color(0xFF0EA5A4) : const Color(0xFFEF4444),
                          ),
                          title: Text(
                            moneda.formatAmount(monto.abs()),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: esDeposito ? const Color(0xFF0EA5A4) : const Color(0xFFEF4444),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatoFecha.format(fecha),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                              if (nota.isNotEmpty)
                                Text(
                                  nota,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                    title: Text(_strings.confirmarEliminacion),
                                    content: Text(_strings.eliminarTransaccion),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(dialogContext).pop(),
                                        child: Text(_strings.cancelar),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _eliminarTransaccionMoneda(codigoMoneda, index);
                                          Navigator.of(dialogContext).pop();
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(_strings.transaccionEliminada),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFEF4444),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text(_strings.eliminar),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_strings.cerrar),
            ),
          ],
        );
      },
    );
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
    final monto = _parseAmountInput(_montoGastoFijoController.text);
    
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
    final monto = _parseAmountInput(_montoGastoFijoController.text);
    
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
    _prefs.setString('app_currency', moneda.toString().split('.').last);
    
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
                          onPressed: () async {
                            final monedaSeleccionada = await _mostrarDialogoAgregarMoneda();
                            if (monedaSeleccionada != null) {
                              _agregarMoneda(monedaSeleccionada);
                              setState(() {});
                            }
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

  Future<AppCurrency?> _mostrarDialogoAgregarMoneda() async {
    final monedasNoAgregadas = AppCurrency.values
        .where((m) => !_monedasDisponibles.contains(m) && m != _appCurrency)
        .toList();

    if (monedasNoAgregadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_strings.noObtieneMonedasDisponibles)),
      );
      return null;
    }

    return showDialog<AppCurrency>(
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
                    Navigator.pop(context, moneda);
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
                      inputFormatters: _amountInputFormatters(),
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

  Future<void> _guardarRecurrencias() async {
    try {
      if (!_isPrefsInitialized()) {
        _prefs = await SharedPreferences.getInstance();
      }
      final datosJSON = jsonEncode(
        _transaccionesRecurrentes.map((r) => r.toJson()).toList(),
      );
      await _prefs.setString('transacciones_recurrentes', datosJSON);
    } catch (e) {
      print('Error al guardar recurrencias: $e');
    }
  }

  Future<void> _generarTransaccionesRecurrentes() async {
    try {
      final transaccionesPendientes = RecurringTransactionService.generarTransaccionesPendientes(
        _transaccionesRecurrentes,
      );
      
      if (transaccionesPendientes.isNotEmpty) {
        setState(() {
          _transacciones.addAll(transaccionesPendientes);
        });
        await _guardarTransacciones();
        
        // Actualizar última generación de cada recurrencia procesada
        for (int i = 0; i < _transaccionesRecurrentes.length; i++) {
          if (_transaccionesRecurrentes[i].debeGenerar()) {
            _transaccionesRecurrentes[i] = RecurringTransactionService.marcarComoGenerada(
              _transaccionesRecurrentes[i],
            );
          }
        }
        await _guardarRecurrencias();
        
        print('[RECURRENTES] ${transaccionesPendientes.length} transacciones generadas automáticamente');
      }
    } catch (e) {
      print('Error al generar transacciones recurrentes: $e');
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
    final String monthKey =
        '${_mesSeleccionado.year.toString().padLeft(4, '0')}-${_mesSeleccionado.month.toString().padLeft(2, '0')}';

    final String dataStamp = _transacciones.isEmpty
        ? '0-empty'
        : '${_transacciones.length}-${_transacciones.first['fecha']}-${_transacciones.last['fecha']}';

    if (_cacheMonthKey == monthKey && _cacheDataStamp == dataStamp) {
      return _cacheTransaccionesMes;
    }

    final filtered = _transacciones.where((t) {
      final dynamic rawFecha = t['fecha'];
      if (rawFecha is String && rawFecha.length >= 7) {
        final bool sameMonth = rawFecha.substring(0, 7) == monthKey;
        if (sameMonth) return true;
      }

      if (rawFecha is String) {
        try {
          final fecha = DateTime.parse(rawFecha);
          return fecha.year == _mesSeleccionado.year && fecha.month == _mesSeleccionado.month;
        } catch (_) {
          return false;
        }
      }

      return false;
    }).toList();

    _cacheMonthKey = monthKey;
    _cacheDataStamp = dataStamp;
    _cacheTransaccionesMes = filtered;

    return filtered;
  }

  // Obtener nombre del mes según el idioma seleccionado
  String _obtenerNombreMes(DateTime fecha) {
    final meses = _strings.nombresMeses;
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  double _calcularIngresos() {
    return _obtenerTransaccionesMes()
        .where((t) => t['tipo'] == 'Ingreso')
        .fold(0.0, (sum, item) {
          final monto = (item['monto'] as num).toDouble();
          final monedaCode = item['moneda'] as String?;
          
          if (monedaCode == null || monedaCode == _appCurrency.toString().split('.').last) {
            // Misma moneda, no necesita conversión
            return sum + monto;
          } else {
            // Convertir a moneda principal
            try {
              final moneda = AppCurrency.values.firstWhere(
                (m) => m.toString().split('.').last == monedaCode,
              );
              final montoConvertido = CurrencyExchangeService.convert(
                amount: monto,
                from: moneda,
                to: _appCurrency,
              );
              return sum + montoConvertido;
            } catch (e) {
              return sum + monto; // Si hay error, sumar sin convertir
            }
          }
        });
  }

  double _calcularEgresos() {
    return _obtenerTransaccionesMes()
        .where((t) => t['tipo'] == 'Egreso')
        .fold(0.0, (sum, item) {
          final monto = (item['monto'] as num).toDouble().abs();
          final monedaCode = item['moneda'] as String?;
          
          if (monedaCode == null || monedaCode == _appCurrency.toString().split('.').last) {
            // Misma moneda, no necesita conversión
            return sum + monto;
          } else {
            // Convertir a moneda principal
            try {
              final moneda = AppCurrency.values.firstWhere(
                (m) => m.toString().split('.').last == monedaCode,
              );
              final montoConvertido = CurrencyExchangeService.convert(
                amount: monto,
                from: moneda,
                to: _appCurrency,
              );
              return sum + montoConvertido;
            } catch (e) {
              return sum + monto; // Si hay error, sumar sin convertir
            }
          }
        });
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
    final monto = _parseAmountInput(_montoController.text);
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
  
  void _agregarNuevaTransaccionConMoneda(AppCurrency moneda) {
    final nombre = _tituloController.text;
    final monto = _parseAmountInput(_montoController.text);
    final razon = _justificacionController.text;

    if (nombre.isEmpty || monto <= 0) return;

    final monedaCode = moneda.toString().split('.').last;

    setState(() {
      _transacciones.add({
        'titulo': nombre,
        'monto': _tipoSeleccionado == 'Ingreso' ? monto : -monto,
        'tipo': _tipoSeleccionado,
        'categoria': _tipoSeleccionado == 'Ingreso' ? '' : _categoriaSeleccionada,
        'justificacion': razon,
        'fecha': DateTime.now().toIso8601String(),
        'moneda': monedaCode,
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
        'currency': monedaCode,
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
  
  // ===== MÉTODO PARA CARGAR DATOS DEMO (SCREENSHOTS) =====
  void _cargarDatosDemo() async {
    // Mostrar confirmación
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📸 Cargar Datos Demo'),
        content: const Text(
          'Esto agregará:\n\n'
          '• 20 transacciones variadas\n'
          '• 3 presupuestos de ejemplo\n'
          '• 2 cuentas de ahorro\n'
          '• 3 gastos fijos\n\n'
          'Perfecto para tomar screenshots profesionales.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_strings.cancelar),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5A4),
            ),
            child: const Text('Cargar Datos'),
          ),
        ],
      ),
    );
    
    if (confirmacion != true) return;
    
    setState(() {
      // ===== TRANSACCIONES =====
      final ahora = DateTime.now();
      final mesActual = DateTime(ahora.year, ahora.month);
      final mesAnterior = DateTime(ahora.year, ahora.month - 1);
      
      // Ingresos
      _transacciones.add({
        'titulo': 'Salario Mensual',
        'monto': 3500.00,
        'tipo': 'Ingreso',
        'categoria': '',
        'justificacion': 'Pago del mes',
        'fecha': DateTime(ahora.year, ahora.month, 1).toIso8601String(),
      });
      
      _transacciones.add({
        'titulo': 'Freelance Proyecto Web',
        'monto': 850.00,
        'tipo': 'Ingreso',
        'categoria': '',
        'justificacion': 'Desarrollo de página web para cliente',
        'fecha': DateTime(ahora.year, ahora.month, 15).toIso8601String(),
      });
      
      _transacciones.add({
        'titulo': 'Venta en Marketplace',
        'monto': 120.00,
        'tipo': 'Ingreso',
        'categoria': '',
        'justificacion': 'Venta de artículos usados',
        'fecha': DateTime(ahora.year, ahora.month, 8).toIso8601String(),
      });
      
      // Egresos - Comida
      _transacciones.add({
        'titulo': 'Supermercado',
        'monto': -245.50,
        'tipo': 'Egreso',
        'categoria': 'Comida',
        'justificacion': 'Compra semanal',
        'fecha': DateTime(ahora.year, ahora.month, 3).toIso8601String(),
      });
      
      _transacciones.add({
        'titulo': 'Restaurante',
        'monto': -68.00,
        'tipo': 'Egreso',
        'categoria': 'Comida',
        'justificacion': 'Cena con amigos',
        'fecha': DateTime(ahora.year, ahora.month, 10).toIso8601String(),
      });
      
      _transacciones.add({
        'titulo': 'Delivery Pizza',
        'monto': -32.50,
        'tipo': 'Egreso',
        'categoria': 'Comida',
        'justificacion': 'Cena rápida',
        'fecha': DateTime(ahora.year, ahora.month, 17).toIso8601String(),
      });
      
      // Egresos - Transporte
      _transacciones.add({
        'titulo': 'Gasolina',
        'monto': -85.00,
        'tipo': 'Egreso',
        'categoria': 'Transporte',
        'justificacion': 'Tanque completo',
        'fecha': DateTime(ahora.year, ahora.month, 5).toIso8601String(),
      });
      
      _transacciones.add({
        'titulo': 'Uber',
        'monto': -18.50,
        'tipo': 'Egreso',
        'categoria': 'Transporte',
        'justificacion': 'Viaje al centro',
        'fecha': DateTime(ahora.year, ahora.month, 12).toIso8601String(),
      });
      
      // Egresos - Entretenimiento
      _transacciones.add({
        'titulo': 'Cine',
        'monto': -24.00,
        'tipo': 'Egreso',
        'categoria': 'Entretenimiento',
        'justificacion': '2 entradas + palomitas',
        'fecha': DateTime(ahora.year, ahora.month, 14).toIso8601String(),
      });
      
      _transacciones.add({
        'titulo': 'Netflix',
        'monto': -15.99,
        'tipo': 'Egreso',
        'categoria': 'Entretenimiento',
        'justificacion': 'Suscripción mensual',
        'fecha': DateTime(ahora.year, ahora.month, 1).toIso8601String(),
      });
      
      _transacciones.add({
        'titulo': 'Spotify Premium',
        'monto': -9.99,
        'tipo': 'Egreso',
        'categoria': 'Entretenimiento',
        'justificacion': 'Música sin anuncios',
        'fecha': DateTime(ahora.year, ahora.month, 1).toIso8601String(),
      });
      
      // Egresos - Servicios
      _transacciones.add({
        'titulo': 'Electricidad',
        'monto': -78.50,
        'tipo': 'Egreso',
        'categoria': 'Servicios',
        'justificacion': 'Factura mensual',
        'fecha': DateTime(ahora.year, ahora.month, 7).toIso8601String(),
      });
      
      _transacciones.add({
        'titulo': 'Internet',
        'monto': -55.00,
        'tipo': 'Egreso',
        'categoria': 'Servicios',
        'justificacion': 'Plan fibra óptica',
        'fecha': DateTime(ahora.year, ahora.month, 10).toIso8601String(),
      });
      
      // Egresos - Salud
      _transacciones.add({
        'titulo': 'Farmacia',
        'monto': -42.80,
        'tipo': 'Egreso',
        'categoria': 'Salud',
        'justificacion': 'Medicamentos',
        'fecha': DateTime(ahora.year, ahora.month, 6).toIso8601String(),
      });
      
      _transacciones.add({
        'titulo': 'Gimnasio',
        'monto': -45.00,
        'tipo': 'Egreso',
        'categoria': 'Salud',
        'justificacion': 'Membresía mensual',
        'fecha': DateTime(ahora.year, ahora.month, 1).toIso8601String(),
      });
      
      // Egresos - Compras
      _transacciones.add({
        'titulo': 'Ropa',
        'monto': -125.00,
        'tipo': 'Egreso',
        'categoria': 'Compras',
        'justificacion': '2 camisas + pantalón',
        'fecha': DateTime(ahora.year, ahora.month, 16).toIso8601String(),
      });
      
      _transacciones.add({
        'titulo': 'Zapatos Deportivos',
        'monto': -89.99,
        'tipo': 'Egreso',
        'categoria': 'Compras',
        'justificacion': 'Para correr',
        'fecha': DateTime(ahora.year, ahora.month, 11).toIso8601String(),
      });
      
      // Egresos - Educación
      _transacciones.add({
        'titulo': 'Curso Online',
        'monto': -199.00,
        'tipo': 'Egreso',
        'categoria': 'Educacion',
        'justificacion': 'Flutter avanzado',
        'fecha': DateTime(ahora.year, ahora.month, 4).toIso8601String(),
      });
      
      _transacciones.add({
        'titulo': 'Libros',
        'monto': -45.50,
        'tipo': 'Egreso',
        'categoria': 'Educacion',
        'justificacion': '3 libros técnicos',
        'fecha': DateTime(ahora.year, ahora.month, 13).toIso8601String(),
      });
      
      // Egresos - Otros
      _transacciones.add({
        'titulo': 'Regalo Cumpleaños',
        'monto': -65.00,
        'tipo': 'Egreso',
        'categoria': 'Otros',
        'justificacion': 'Regalo para mi hermana',
        'fecha': DateTime(ahora.year, ahora.month, 9).toIso8601String(),
      });
      
      // ===== PRESUPUESTOS =====
      _presupuestoMensual = 3000.00;
      
      // ===== AHORROS =====
      _registrosAhorros = [
        {
          'fecha': DateTime(ahora.year, ahora.month, 1).toIso8601String(),
          'monto': 500.00,
          'nota': 'Meta inicial del mes',
        },
        {
          'fecha': DateTime(ahora.year, ahora.month, 15).toIso8601String(),
          'monto': 300.00,
          'nota': 'Ahorro adicional del freelance',
        },
        {
          'fecha': DateTime(mesAnterior.year, mesAnterior.month, 1).toIso8601String(),
          'monto': 450.00,
          'nota': 'Ahorro mes anterior',
        },
      ];
      
      // ===== GASTOS FIJOS =====
      _gastosFijos = [
        {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'nombre': 'Alquiler',
          'monto': 800.00,
          'diaVencimiento': 5,
          'frecuencia': 'mensual',
          'activo': true,
          'recordatorioActivado': true,
        },
        {
          'id': (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          'nombre': 'Seguro de Auto',
          'monto': 120.00,
          'diaVencimiento': 15,
          'frecuencia': 'mensual',
          'activo': true,
          'recordatorioActivado': true,
        },
        {
          'id': (DateTime.now().millisecondsSinceEpoch + 2).toString(),
          'nombre': 'Tarjeta de Crédito',
          'monto': 250.00,
          'diaVencimiento': 20,
          'frecuencia': 'mensual',
          'activo': true,
          'recordatorioActivado': true,
        },
      ];
      
      _mesSeleccionado = mesActual;
    });
    
    // Guardar todo
    await _guardarTransacciones();
    await _prefs.setDouble('presupuesto_mensual', _presupuestoMensual);
    
    try {
      final String ahorrosJSON = jsonEncode(_registrosAhorros);
      await _prefs.setString('ahorros_historicos', ahorrosJSON);
    } catch (e) {
      print('Error al guardar ahorros demo: $e');
    }
    
    await _guardarGastosFijos();
    
    _actualizarAhorrosDelMes();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Datos demo cargados. ¡Listo para screenshots!'),
          backgroundColor: Color(0xFF22C55E),
          duration: Duration(seconds: 3),
        ),
      );
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

  // ===== MÉTODOS PARA TRANSACCIONES RECURRENTES Y GASTOS FIJOS =====

  void _mostrarDialogoTransaccionesFijas() {
    showDialog(
      context: context,
      builder: (_) {
        return DefaultTabController(
          length: 2,
          child: Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  AppBar(
                    title: Text(_strings.transaccionesFijas),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                    bottom: TabBar(
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.repeat),
                          text: _strings.language == AppLanguage.spanish 
                              ? 'Recurrencias' 
                              : 'Recurring',
                        ),
                        Tab(
                          icon: const Icon(Icons.credit_card),
                          text: _strings.language == AppLanguage.spanish 
                              ? 'Gastos Fijos' 
                              : 'Fixed Expenses',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildRecurrenciasTab(),
                        _buildGastosFijosTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecurrenciasTab() {
    return Column(
      children: [
        Expanded(
          child: _transaccionesRecurrentes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_repeat, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _strings.language == AppLanguage.spanish
                            ? 'No hay transacciones recurrentes'
                            : 'No recurring transactions',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _transaccionesRecurrentes.length,
                  itemBuilder: (ctx, i) {
                    final recurrencia = _transaccionesRecurrentes[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: recurrencia.tipo == 'Ingreso'
                              ? Colors.green[100]
                              : Colors.red[100],
                          child: Text(
                            recurrencia.tipo == 'Ingreso' ? '↓' : '↑',
                            style: TextStyle(
                              color: recurrencia.tipo == 'Ingreso'
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontSize: 20,
                            ),
                          ),
                        ),
                        title: Text(recurrencia.titulo),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_appCurrency.symbol}${recurrencia.monto.toStringAsFixed(2)}'),
                            Text(
                              recurrencia.getFrecuenciaString(
                                _strings.language == AppLanguage.spanish ? 'es' : 'en',
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                recurrencia.activa ? Icons.pause : Icons.play_arrow,
                                color: recurrencia.activa ? Colors.orange : Colors.green,
                              ),
                              onPressed: () {
                                setState(() {
                                  _transaccionesRecurrentes[i] = recurrencia.copyWith(
                                    activa: !recurrencia.activa,
                                  );
                                });
                                _guardarRecurrencias();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _transaccionesRecurrentes.removeAt(i);
                                });
                                _guardarRecurrencias();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _mostrarDialogoNuevaRecurrencia();
            },
            icon: const Icon(Icons.add),
            label: Text(_strings.agregar),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGastosFijosTab() {
    return Column(
      children: [
        Expanded(
          child: _gastosFijos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.credit_card, size: 64, color: Color(0xFFD1D5DB)),
                      const SizedBox(height: 16),
                      Text(_strings.sinGastosFijos),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _gastosFijos.length,
                  itemBuilder: (ctx, index) {
                    final gastoFijo = _gastosFijos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _mostrarDialogoGastoFijo();
            },
            icon: const Icon(Icons.add),
            label: Text(_strings.agregarGastoFijo),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoRecurrencias() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.repeat, color: Color(0xFF0EA5A4)),
              const SizedBox(width: 8),
              Text(_strings.language == AppLanguage.spanish 
                  ? 'Transacciones Recurrentes' 
                  : 'Recurring Transactions'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: _transaccionesRecurrentes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_repeat, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _strings.language == AppLanguage.spanish
                              ? 'No hay transacciones recurrentes'
                              : 'No recurring transactions',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _transaccionesRecurrentes.length,
                    itemBuilder: (ctx, i) {
                      final recurrencia = _transaccionesRecurrentes[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: recurrencia.tipo == 'Ingreso'
                                ? Colors.green[100]
                                : Colors.red[100],
                            child: Text(
                              recurrencia.tipo == 'Ingreso' ? '↓' : '↑',
                              style: TextStyle(
                                color: recurrencia.tipo == 'Ingreso'
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontSize: 20,
                              ),
                            ),
                          ),
                          title: Text(recurrencia.titulo),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_appCurrency.symbol}${recurrencia.monto.toStringAsFixed(2)}'),
                              Text(
                                recurrencia.getFrecuenciaString(
                                  _strings.language == AppLanguage.spanish ? 'es' : 'en',
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  recurrencia.activa ? Icons.pause : Icons.play_arrow,
                                  color: recurrencia.activa ? Colors.orange : Colors.green,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _transaccionesRecurrentes[i] = recurrencia.copyWith(
                                      activa: !recurrencia.activa,
                                    );
                                  });
                                  _guardarRecurrencias();
                                  Navigator.pop(ctx);
                                  _mostrarDialogoRecurrencias();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _transaccionesRecurrentes.removeAt(i);
                                  });
                                  _guardarRecurrencias();
                                  Navigator.pop(ctx);
                                  _mostrarDialogoRecurrencias();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_strings.cerrar),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _mostrarDialogoNuevaRecurrencia();
              },
              icon: const Icon(Icons.add),
              label: Text(_strings.agregar),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoNuevaRecurrencia() {
    final tituloController = TextEditingController();
    final montoController = TextEditingController();
    final justificacionController = TextEditingController();
    String tipoSeleccionado = 'Egreso';
    String categoriaSeleccionada = 'Otro';
    RecurringFrequency frecuenciaSeleccionada = RecurringFrequency.monthly;
    DateTime fechaInicio= DateTime.now();
    DateTime? fechaFin;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(_strings.language == AppLanguage.spanish 
                  ? 'Nueva Transacción Recurrente' 
                  : 'New Recurring Transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tipo
                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'Ingreso', child: Text(_strings.ingresos)),
                        DropdownMenuItem(value: 'Egreso', child: Text(_strings.egresos)),
                      ],
                      onChanged: (v) => setDialogState(() => tipoSeleccionado = v!),

                    ),
                    const SizedBox(height: 12),
                    // Título
                    TextField(
                      controller: tituloController,
                      decoration: InputDecoration(
                        labelText: _strings.titulo,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Monto
                    TextField(
                      controller: montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: _amountInputFormatters(),
                      decoration: InputDecoration(
                        labelText: _strings.monto,
                        border: const OutlineInputBorder(),
                        prefixText: _appCurrency.symbol,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Categoría
                    DropdownButtonFormField<String>(
                      value: categoriaSeleccionada,
                      decoration: InputDecoration(
                        labelText: _strings.categoria,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        ..._categorias.entries.map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text('${e.value} ${e.key}'),
                            )),
                        ..._categoriasPersonalizadas.entries.map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text('${e.value} ${e.key}'),
                            )),
                      ],
                      onChanged: (v) => setDialogState(() => categoriaSeleccionada = v!),
                    ),
                    const SizedBox(height: 12),
                    // Justificación
                    TextField(
                      controller: justificacionController,
                      decoration: InputDecoration(
                        labelText: _strings.justificacion,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    // Frecuencia
                    DropdownButtonFormField<RecurringFrequency>(
                      value: frecuenciaSeleccionada,
                      decoration: InputDecoration(
                        labelText: _strings.language == AppLanguage.spanish ? 'Frecuencia' : 'Frequency',
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: RecurringFrequency.daily,
                          child: Text(_strings.language == AppLanguage.spanish ? 'Diaria' : 'Daily'),
                        ),
                        DropdownMenuItem(
                          value: RecurringFrequency.weekly,
                          child: Text(_strings.language == AppLanguage.spanish ? 'Semanal' : 'Weekly'),
                        ),
                        DropdownMenuItem(
                          value: RecurringFrequency.biweekly,
                          child: Text(_strings.language == AppLanguage.spanish ? 'Quincenal' : 'Biweekly'),
                        ),
                        DropdownMenuItem(
                          value: RecurringFrequency.monthly,
                          child: Text(_strings.language == AppLanguage.spanish ? 'Mensual' : 'Monthly'),
                        ),
                        DropdownMenuItem(
                          value: RecurringFrequency.yearly,
                          child: Text(_strings.language == AppLanguage.spanish ? 'Anual' : 'Yearly'),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() => frecuenciaSeleccionada = v!),
                    ),
                    const SizedBox(height: 12),
                    // Fecha inicio
                    ListTile(
                      title: Text(_strings.language == AppLanguage.spanish ? 'Fecha de inicio' : 'Start date'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(fechaInicio)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fechaInicio,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => fechaInicio = picked);
                        }
                      },
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
                    if (tituloController.text.trim().isEmpty ||
                        montoController.text.trim().isEmpty) {
                      return;
                    }

                    final nuevaRecurrencia = RecurringTransaction(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      titulo: tituloController.text.trim(),
                      monto: _parseAmountInput(montoController.text),
                      tipo: tipoSeleccionado,
                      categoria: categoriaSeleccionada,
                      justificacion: justificacionController.text.trim(),
                      frecuencia: frecuenciaSeleccionada,
                      fechaInicio: fechaInicio,
                      fechaFin: fechaFin,
                      moneda: _appCurrency.toString(),
                    );

                    setState(() {
                      _transaccionesRecurrentes.add(nuevaRecurrencia);
                    });
                    _guardarRecurrencias();
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_strings.language == AppLanguage.spanish
                            ? 'Transacción recurrente creada'
                            : 'Recurring transaction created'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text(_strings.guardar),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      tituloController.dispose();
      montoController.dispose();
      justificacionController.dispose();
    });
  }

  // ===== MÉTODOS PARA BACKUP Y RESTAURACIÓN =====

  void _mostrarDialogoBackupRestauracion() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.backup, color: Color(0xFF0EA5A4)),
              const SizedBox(width: 8),
              Text(_strings.language == AppLanguage.spanish 
                  ? 'Backup y Restauración' 
                  : 'Backup & Restore'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF22C55E),
                  child: Icon(Icons.save, color: Colors.white),
                ),
                title: Text(_strings.language == AppLanguage.spanish 
                    ? 'Crear Backup' 
                    : 'Create Backup'),
                subtitle: Text(_strings.language == AppLanguage.spanish
                    ? 'Guarda todos tus datos'
                    : 'Save all your data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final file = await BackupService.crearBackupCompleto();
                    await BackupService.limpiarBackupsAntiguos();
                    
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _strings.language == AppLanguage.spanish
                              ? 'Backup creado exitosamente'
                              : 'Backup created successfully',
                        ),
                        backgroundColor: Colors.green,
                        action: SnackBarAction(
                          label: _strings.language == AppLanguage.spanish ? 'Compartir' : 'Share',
                          onPressed: () async {
                            await Share.shareXFiles([XFile(file.path)]);
                          },
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF59E0B),
                  child: Icon(Icons.restore, color: Colors.white),
                ),
                title: Text(_strings.language == AppLanguage.spanish 
                    ? 'Restaurar Backup' 
                    : 'Restore Backup'),
                subtitle: Text(_strings.language == AppLanguage.spanish
                    ? 'Recupera tus datos guardados'
                    : 'Recover your saved data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  await _seleccionarYRestaurarBackup();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF3B82F6),
                  child: Icon(Icons.history, color: Colors.white),
                ),
                title: Text(_strings.language == AppLanguage.spanish 
                    ? 'Ver Backups' 
                    : 'View Backups'),
                subtitle: Text(_strings.language == AppLanguage.spanish
                    ? 'Lista de backups disponibles'
                    : 'List of available backups'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarListaBackups();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_strings.cerrar),
            ),
          ],
        );
      },
    );
  }

  Future<void> _seleccionarYRestaurarBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        if (!mounted) return;
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(_strings.language == AppLanguage.spanish 
                ? '¿Restaurar backup?' 
                : 'Restore backup?'),
            content: Text(_strings.language == AppLanguage.spanish
                ? 'Esto reemplazará todos tus datos actuales. ¿Estás seguro?'
                : 'This will replace all your current data. Are you sure?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(_strings.cancelar),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text(_strings.language == AppLanguage.spanish ? 'Restaurar' : 'Restore'),
              ),
            ],
          ),
        );

        if (confirmar == true) {
          final exito = await BackupService.restaurarBackup(file);
          
          if (!mounted) return;
          if (exito) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_strings.language == AppLanguage.spanish
                    ? 'Backup restaurado. Reinicia la app.'
                    : 'Backup restored. Restart the app.'),
                backgroundColor: Colors.green,
              ),
            );
            // Recargar datos
            await _cargarTransacciones();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_strings.language == AppLanguage.spanish
                    ? 'Error al restaurar backup'
                    : 'Error restoring backup'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _mostrarListaBackups() async {
    final backups = await BackupService.listarBackups();
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(_strings.language == AppLanguage.spanish 
              ? 'Backups Disponibles' 
              : 'Available Backups'),
          content: SizedBox(
            width: double.maxFinite,
            child: backups.isEmpty
                ? Center(
                    child: Text(_strings.language == AppLanguage.spanish
                        ? 'No hay backups disponibles'
                        : 'No backups available'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: backups.length,
                    itemBuilder: (ctx, i) {
                      final backup = backups[i];
                      final nombre = p.basename(backup.path);
                      return FutureBuilder<Map<String, dynamic>?>(
                        future: BackupService.obtenerInfoBackup(backup),
                        builder: (ctx, snapshot) {
                          return ListTile(
                            leading: const Icon(Icons.description),
                            title: Text(nombre),
                            subtitle: snapshot.hasData
                                ? Text('${snapshot.data?['transacciones'] ?? 0} transacciones')
                                : const Text('Cargando...'),
                            trailing: IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: () async {
                                await Share.shareXFiles([XFile(backup.path)]);
                              },
                            ),
                            onTap: () async {
                              Navigator.pop(context);
                              final exito = await BackupService.restaurarBackup(backup);
                              if (!mounted) return;
                              if (exito) {
                                await _cargarTransacciones();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_strings.language == AppLanguage.spanish
                                        ? 'Backup restaurado'
                                        : 'Backup restored'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_strings.cerrar),
            ),
          ],
        );
      },
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
    
    // Variables para compra de moneda extranjera
    bool esCompraMonedaExtranjera = false;
    AppCurrency monedaDestino = AppCurrency.usd;
    
    // Moneda de la transacción (por defecto la moneda principal)
    AppCurrency monedaTransaccion = _appCurrency;
    
    if (index != null) {
      final existing = _transacciones[index];
      _tituloController.text = existing['titulo'] ?? '';
      // monto puede ser negativo para egresos
      _montoController.text = (existing['monto'] ?? 0).abs().toString();
      _justificacionController.text = existing['justificacion'] ?? '';
      _categoriaSeleccionada = existing['categoria'] ?? 'Otro';
      
      // Cargar moneda si existe
      if (existing['moneda'] != null) {
        try {
          final monedaCode = existing['moneda'] as String;
          monedaTransaccion = AppCurrency.values.firstWhere(
            (m) => m.toString().split('.').last == monedaCode,
            orElse: () => _appCurrency,
          );
        } catch (e) {
          monedaTransaccion = _appCurrency;
        }
      }
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
                final monto = _parseAmountInput(_montoController.text);
                
                // Si es compra de moneda extranjera, agregar a ahorros
                if (tipo == 'Egreso' && esCompraMonedaExtranjera) {
                  _agregarNuevaTransaccionConMoneda(monedaTransaccion);
                  _agregarCompraMonedaExtranjera(monedaTransaccion, monedaDestino, monto, nombre);
                } else {
                  _agregarNuevaTransaccionConMoneda(monedaTransaccion);
                }
                
                if (tipo == 'Egreso' && registrarComoGastoFijo && nombre.isNotEmpty && monto > 0) {
                  _agregarGastoFijoDesdeEgreso(nombre, monto, diaVencimientoLocal);
                }
              } else {
                _guardarEdicionConMoneda(index, monedaTransaccion);
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
                    // Selector de Moneda
                    Card(
                      elevation: 0,
                      color: const Color(0xFFF0F9FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF0EA5A4), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.currency_exchange, color: Color(0xFF0EA5A4), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _strings.monedaTransaccion,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  DropdownButton<AppCurrency>(
                                    value: monedaTransaccion,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    items: [_appCurrency, ..._monedasDisponibles].toSet().toList().map((currency) {
                                      final esMonedaPrincipal = currency == _appCurrency;
                                      return DropdownMenuItem(
                                        value: currency,
                                        child: Row(
                                          children: [
                                            Text(
                                              currency.symbol,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                currency.name.split(' - ')[0],
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (esMonedaPrincipal)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0EA5A4),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  _strings.principal,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        monedaTransaccion = value ?? _appCurrency;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _montoController,
                      focusNode: _montoFocus,
                      textInputAction: TextInputAction.next,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}$')),
                      ],
                      onSubmitted: (_) => _justificacionFocus.requestFocus(),
                      decoration: InputDecoration(
                        labelText: 'Monto ${monedaTransaccion.symbol}',
                        hintText: '${monedaTransaccion.symbol}0.00',
                      ),
                    ),
                    // Mostrar conversión si no es la moneda principal
                    if (monedaTransaccion != _appCurrency && _montoController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  CurrencyExchangeService.formatConversion(
                                    amount: _parseAmountInput(_montoController.text),
                                    from: monedaTransaccion,
                                    to: _appCurrency,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF92400E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Opción de compra de moneda extranjera (solo para egresos)
                    if (tipo == 'Egreso' && index == null)
                      Column(
                        children: [
                          CheckboxListTile(
                            value: esCompraMonedaExtranjera,
                            onChanged: (value) {
                              setState(() {
                                esCompraMonedaExtranjera = value ?? false;
                              });
                            },
                            title: Text(_strings.compraMonedaExtranjera),
                            subtitle: Text(_strings.compraMonedaExtrajeraDesc),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          // Selector de moneda destino si está marcado
                          if (esCompraMonedaExtranjera) ...[
                            const SizedBox(height: 8),
                            Card(
                              elevation: 0,
                              color: const Color(0xFFDCFCE7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFF22C55E), width: 1),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.swap_horiz, color: Color(0xFF22C55E), size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          _strings.monedaAComprar,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF166534),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButton<AppCurrency>(
                                      value: monedaDestino,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      items: AppCurrency.values.map((currency) {
                                        return DropdownMenuItem(
                                          value: currency,
                                          child: Row(
                                            children: [
                                              Text(
                                                currency.symbol,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(currency.name),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          monedaDestino = value ?? AppCurrency.usd;
                                        });
                                      },
                                    ),
                                    // Mostrar preview de conversión
                                    if (_montoController.text.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.info_outline, color: Color(0xFF22C55E), size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${_strings.recibirasAproximadamente}:\n${CurrencyExchangeService.formatConversion(
                                                amount: _parseAmountInput(_montoController.text),
                                                from: monedaTransaccion,
                                                to: monedaDestino,
                                              )}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF166534),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
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
    final monto = _parseAmountInput(_montoController.text);
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
  
  void _guardarEdicionConMoneda(int index, AppCurrency moneda) {
    final nombre = _tituloController.text;
    final monto = _parseAmountInput(_montoController.text);
    final razon = _justificacionController.text;

    if (nombre.isEmpty || monto <= 0) return;

    final monedaCode = moneda.toString().split('.').last;

    setState(() {
      _transacciones[index] = {
        'titulo': nombre,
        'monto': _tipoSeleccionado == 'Ingreso' ? monto : -monto,
        'tipo': _tipoSeleccionado,
        'categoria': _tipoSeleccionado == 'Ingreso' ? '' : _categoriaSeleccionada,
        'justificacion': razon,
        'fecha': _transacciones[index]['fecha'] ?? DateTime.now().toIso8601String(),
        'moneda': monedaCode,
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
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isAuthenticated = true;
                      _authChecked = true;
                    });
                  },
                  child: const Text(
                    'Continuar sin verificar',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
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
              } else if (value == 'graficos_reportes') {
                _mostrarDialogoGraficosReportes();
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
              } else if (value == 'transacciones_fijas') {
                _mostrarDialogoTransaccionesFijas();
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
                  MaterialPageRoute(builder: (_) => ProfileScreen(strings: _strings)),
                );
              } else if (value == 'datos_demo') {
                _cargarDatosDemo();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'presupuesto', child: Text('💰 ${_strings.presupuestoMensual}')),
              PopupMenuItem(
                value: 'transacciones_fijas',
                child: Text('🔄 ${_strings.transaccionesFijas}'),
              ),
              if (_isPremium)
                PopupMenuItem(value: 'categorias_personalizadas', child: Text('📂 ${_strings.misCategorias}')),
              if (_isPremium)
                PopupMenuItem(value: 'monedas_multiples', child: Text('💱 ${_strings.monedasMultiples}')),
              PopupMenuItem(
                value: 'graficos_reportes',
                child: Text('📊 ${_strings.graficosEInformes}'),
              ),
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
      body: Builder(
        builder: (context) {
          if (_tabController.index == 0) {
            return _buildTransaccionesTab();
          }
          if (_tabController.index == 1) {
            return _buildAhorrosTab();
          }
          return EventosCompartidosScreen(
            strings: _strings,
            currency: _appCurrency,
          );
        },
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
  
  void _mostrarDialogoDesgloseMonedas() {
    // Obtener transacciones del mes y agrupar por moneda
    final transaccionesMes = _obtenerTransaccionesMes();
    final Map<String, Map<String, double>> totalesPorMoneda = {};
    
    // Inicializar con moneda principal
    final monedaPrincipalCode = _appCurrency.toString().split('.').last;
    totalesPorMoneda[monedaPrincipalCode] = {'ingresos': 0.0, 'egresos': 0.0};
    
    // Agrupar transacciones por moneda
    for (var t in transaccionesMes) {
      final monedaCode = (t['moneda'] as String?) ?? monedaPrincipalCode;
      final monto = (t['monto'] as num).toDouble();
      
      if (!totalesPorMoneda.containsKey(monedaCode)) {
        totalesPorMoneda[monedaCode] = {'ingresos': 0.0, 'egresos': 0.0};
      }
      
      if (t['tipo'] == 'Ingreso') {
        totalesPorMoneda[monedaCode]!['ingresos'] = 
            (totalesPorMoneda[monedaCode]!['ingresos'] ?? 0.0) + monto;
      } else {
        totalesPorMoneda[monedaCode]!['egresos'] = 
            (totalesPorMoneda[monedaCode]!['egresos'] ?? 0.0) + monto.abs();
      }
    }
    
    // Filtrar monedas con saldo
    final monedasConSaldo = totalesPorMoneda.entries
        .where((entry) => 
            (entry.value['ingresos'] ?? 0.0) > 0 || 
            (entry.value['egresos'] ?? 0.0) > 0)
        .toList();
    
    // Mostrar diálogo con desglose
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.currency_exchange, color: Color(0xFFF59E0B), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _strings.desglosePorMoneda,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: monedasConSaldo.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _strings.sinTransacciones,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: monedasConSaldo.map((entry) {
                final monedaCode = entry.key;
                final ingresos = entry.value['ingresos'] ?? 0.0;
                final egresos = entry.value['egresos'] ?? 0.0;
                final balance = ingresos - egresos;
                
                final moneda = AppCurrency.values.firstWhere(
                  (m) => m.toString().split('.').last == monedaCode,
                  orElse: () => _appCurrency,
                );
                
                final esMonedaPrincipal = moneda == _appCurrency;
                
                // Si no es moneda principal, calcular conversión
                String? conversionTexto;
                if (!esMonedaPrincipal) {
                  final balanceConvertido = CurrencyExchangeService.convert(
                    amount: balance,
                    from: moneda,
                    to: _appCurrency,
                  );
                  conversionTexto = '→ ${_appCurrency.formatAmount(balanceConvertido)}';
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFBBF24).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: esMonedaPrincipal 
                                    ? const Color(0xFF0EA5A4)
                                    : const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    moneda.symbol,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    moneda.name.split(' - ')[0],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (esMonedaPrincipal) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5A4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _strings.principal,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '↑ ${moneda.formatAmount(ingresos)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF0EA5A4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '↓ ${moneda.formatAmount(egresos)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  moneda.formatAmount(balance),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: balance >= 0 
                                        ? const Color(0xFF0EA5A4)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                                if (conversionTexto != null)
                                  Text(
                                    conversionTexto,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF92400E),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
                    ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _strings.cerrar,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransaccionesTab() {
    final List<Map<String, dynamic>> transaccionesMes = _obtenerTransaccionesMes();
    final Map<Map<String, dynamic>, int> indexPorReferencia = Map.identity();
    for (int i = 0; i < _transacciones.length; i++) {
      indexPorReferencia[_transacciones[i]] = i;
    }
    final bool hayMuchasTransacciones = transaccionesMes.length > 60;
    final List<Map<String, dynamic>> transaccionesVisibles =
        (_mostrarListaCompleta || !hayMuchasTransacciones)
            ? transaccionesMes
            : transaccionesMes.take(60).toList();

    double ingresos = 0;
    double egresos = 0;
    for (final t in transaccionesMes) {
      final monto = (t['monto'] as num).toDouble();
      final tipo = t['tipo'];
      if (tipo == 'Ingreso') {
        ingresos += monto;
      } else if (tipo == 'Egreso') {
        egresos += monto.abs();
      }
    }

    double balance = ingresos - egresos;
    
    // Calcular egresos del mes seleccionado para verificar presupuesto
    final List<Map<String, dynamic>> egresosDelMes = transaccionesMes
        .where((t) => t['tipo'] == 'Egreso')
        .toList();

    final double egresosMesSeleccionado = egresos;
    final double porcentajePresupuesto = _presupuestoMensual > 0
        ? (egresosMesSeleccionado / _presupuestoMensual) * 100
        : 0;

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
                  child: GestureDetector(
                    onTap: _mostrarDialogoDesgloseMonedas,
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
                                Expanded(
                                  child: Text(_strings.ingresos, style: const TextStyle(fontSize: 16, color: Color(0xFF0EA5A4), fontWeight: FontWeight.w600)),
                                ),
                                const Icon(Icons.touch_app, color: Color(0xFF0EA5A4), size: 18),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(_appCurrency.formatAmount(ingresos), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0EA5A4))),
                          ],
                        ),
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
                        _mostrarListaCompleta = false;
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
                          _mostrarListaCompleta = false;
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
                        _mostrarListaCompleta = false;
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
                            value: (egresosMesSeleccionado / _presupuestoMensual).clamp(0.0, 1.0),
                            minHeight: 12,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressBarColor(porcentajePresupuesto),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Información de gasto
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_strings.gastado}: ${_appCurrency.formatAmount(egresosMesSeleccionado)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                            ),
                            Text(
                              '${porcentajePresupuesto.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _getProgressBarColor(porcentajePresupuesto),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Lista de movimientos (diferida para evitar ANR al abrir)
            if (!_mainTabHeavyReady)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Cargando movimientos...'),
                  ],
                ),
              )
            else
              (transaccionesVisibles.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No hay movimientos en este mes. ¡Usa el botón +!'),
                    )
                  : SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: transaccionesVisibles.length,
                        itemBuilder: (ctx, i) {
                          final t = transaccionesVisibles[i];
                          final indexOriginal = indexPorReferencia[t] ?? i;
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
                    )),
            if (hayMuchasTransacciones && !_mostrarListaCompleta)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _mostrarListaCompleta = true;
                      });
                    },
                    icon: const Icon(Icons.expand_more),
                    label: Text('Ver todos (${transaccionesMes.length})'),
                  ),
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
          // Botón de Ahorros en Monedas Extranjeras (Premium)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _mostrarDialogoAhorrosMonedas,
                icon: const Icon(Icons.currency_exchange),
                label: Text(_strings.ahorrosMonedas),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0EA5A4),
                  side: const BorderSide(color: Color(0xFF0EA5A4), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Resumen de Ahorros en Monedas (si hay)
          if (_ahorrosMonedas.isNotEmpty && _isPremium)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 0,
                color: const Color(0xFFFEF3C7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFF59E0B), width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Color(0xFFF59E0B), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _strings.resumenMonedasExtranjeras,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._ahorrosMonedas.keys.map((codigoMoneda) {
                        final moneda = AppCurrency.values.firstWhere(
                          (m) => m.toString().split('.').last == codigoMoneda,
                        );
                        final total = _calcularTotalMoneda(codigoMoneda);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    moneda.symbol,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    moneda.name.split(' - ')[0],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                moneda.formatAmount(total),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: total >= 0 ? const Color(0xFF0EA5A4) : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
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

  // Mapa de URLs de servicios recomendados
  static const Map<String, String> urlsAfiliacion = {
    'seguros': 'https://www.google.com/search?q=seguros+médicos+comparación',
    'tarjetas': 'https://www.google.com/search?q=tarjetas+de+crédito+comparación',
    'ahorros': 'https://www.google.com/search?q=cuentas+de+ahorro+mejores+tasas',
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



