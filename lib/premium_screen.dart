import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'localization.dart';

class PremiumScreen extends StatefulWidget {
  final AppStrings? strings;
  final String? source; // Para saber de dónde viene el usuario

  const PremiumScreen({this.strings, this.source, super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> with TickerProviderStateMixin {
  late AppStrings _strings;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _loading = true;
  bool _isPremium = false;
  
  // Performance timing
  late DateTime _screenOpenTime;
  
  // Timer de oferta
  late Timer _offerTimer;
  Duration _timeRemaining = const Duration(hours: 24);
  
  // Animaciones
  late AnimationController _pulseController;

  // IDs de productos (estos deben coincidir con los configurados en Google Play y App Store)
  static const String productIdMonthly = 'premium_monthly';
  static const String productIdYearly = 'premium_yearly';

  static const Set<String> _kProductIds = {
    productIdMonthly,
    productIdYearly,
  };

  @override
  void initState() {
    super.initState();
    _screenOpenTime = DateTime.now();
    print('[TIMING] PremiumScreen OPENED from: ${widget.source ?? "unknown"}');
    
    // Inicializar animaciones
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    // Inicializar timer de oferta
    _startOfferTimer();
    
    // Inicializar strings: usar las proporcionadas o crear una por defecto
    if (widget.strings != null) {
      _strings = widget.strings!;
    } else {
      _strings = AppStrings(language: AppLanguage.spanish);
    }
    
    _checkPremiumStatus();
    // En Web o Windows, mostrar directamente los planes mockeados sin intentar InAppPurchase
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      setState(() {
        _loading = false;
        _isAvailable = false; // Las compras no están disponibles en estos SO
      });
      print('[TIMING] PremiumScreen ready (Desktop/Web) - ${DateTime.now().difference(_screenOpenTime).inMilliseconds}ms');
    } else {
      _initStoreInfo();
    }
  }
  
  void _startOfferTimer() {
    _offerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds > 0) {
        setState(() {
          _timeRemaining = _timeRemaining - const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _checkPremiumStatus() async {
    print('[TIMING] _checkPremiumStatus START');
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool('is_premium') ?? false;
    print('[TIMING] _checkPremiumStatus COMPLETE - ${DateTime.now().difference(_screenOpenTime).inMilliseconds}ms');
    setState(() {
      _isPremium = isPremium;
    });
  }

  Future<void> _initStoreInfo() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      setState(() {
        _isAvailable = false;
        _loading = false;
      });
      return;
    }

    // Escuchar cambios en las compras
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      print('Error en compras: $error');
    });

    // Obtener productos disponibles
    final ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(_kProductIds);
    
    if (productDetailResponse.error != null) {
      print('[TIMING] _initStoreInfo ERROR - ${DateTime.now().difference(_screenOpenTime).inMilliseconds}ms');
      setState(() {
        _isAvailable = false;
        _loading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      print('[TIMING] _initStoreInfo NO PRODUCTS - ${DateTime.now().difference(_screenOpenTime).inMilliseconds}ms');
      setState(() {
        _isAvailable = false;
        _loading = false;
      });
      return;
    }

    print('[TIMING] _initStoreInfo COMPLETE - ${DateTime.now().difference(_screenOpenTime).inMilliseconds}ms');
    setState(() {
      _isAvailable = true;
      _products = productDetailResponse.productDetails;
      _loading = false;
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _deliverProduct(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void _showPendingUI() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Procesando compra...')),
    );
  }

  void _handleError(IAPError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${error.message}')),
    );
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    // Guardar estado premium
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);
    await prefs.setString('premium_product_id', purchaseDetails.productID);
    await prefs.setString('premium_purchase_date', DateTime.now().toIso8601String());
    
    // Determinar plan y fecha de expiración
    String planNombre = '';
    DateTime? fechaExpiracion;
    
    if (purchaseDetails.productID == productIdMonthly) {
      planNombre = 'Mensual';
      fechaExpiracion = DateTime.now().add(const Duration(days: 30));
    } else if (purchaseDetails.productID == productIdYearly) {
      planNombre = 'Anual';
      fechaExpiracion = DateTime.now().add(const Duration(days: 365));
    }
    
    await prefs.setString('premium_plan', planNombre);
    if (fechaExpiracion != null) {
      await prefs.setString('premium_expiration', fechaExpiracion.toIso8601String());
    }
    
    setState(() {
      _isPremium = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Bienvenido a Premium! 🎉'),
          backgroundColor: Color(0xFF0EA5A4),
        ),
      );
    }
  }

  void _buyProduct(ProductDetails productDetails) {
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compras restauradas')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al restaurar: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _offerTimer.cancel();
    _pulseController.dispose();
    if (!kIsWeb && !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      _subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Premium',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isPremium
              ? _buildPremiumActiveUI()
              : _buildPremiumOffersUI(),
    );
  }

  Widget _buildPremiumActiveUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5A4), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium, size: 80, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  '¡Eres Premium!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Disfruta de todas las funciones',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _strings.funcionesPremiumActivas,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          _buildFeatureCard(
            icon: Icons.block,
            title: _strings.sinPublicidad,
            description: _strings.sinPublicidadDesc,
          ),
          _buildFeatureCard(
            icon: Icons.cloud_upload,
            title: _strings.backupNube,
            description: _strings.backupNubeDesc,
          ),
          _buildFeatureCard(
            icon: Icons.analytics,
            title: _strings.analisisAvanzados,
            description: _strings.analisisAvanzadosDesc,
          ),
          _buildFeatureCard(
            icon: Icons.attach_money,
            title: _strings.monedasMultiples,
            description: _strings.monedasMultiples,
          ),
          _buildFeatureCard(
            icon: Icons.category,
            title: _strings.misCategorias,
            description: _strings.misCategorias,
          ),
          _buildFeatureCard(
            icon: Icons.trending_up,
            title: _strings.marketingAfiliacion,
            description: _strings.marketingAfiliacion,
          ),
          _buildFeatureCard(
            icon: Icons.support_agent,
            title: _strings.soportePrioritario,
            description: _strings.soportePrioritarioDesc,
          ),
          const SizedBox(height: 32),
          if (!kIsWeb)
            OutlinedButton.icon(
              onPressed: _restorePurchases,
              icon: const Icon(Icons.refresh),
              label: Text(_strings.restaurarCompras),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumOffersUI() {
    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Timer de oferta especial
          ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '¡OFERTA ESPECIAL!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.local_fire_department, color: Colors.white, size: 24),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '50% DE DESCUENTO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // El usuario puede scrollear manualmente para ver los planes
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '¡Aprovecha ahora!',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_downward,
                            color: Color(0xFFEF4444),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Héroe visual
          const Icon(
            Icons.workspace_premium,
            size: 80,
            color: Color(0xFF0EA5A4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mejora a Premium',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Desbloquea todas las funciones avanzadas',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Ahorro simulado
          _buildSavingsCalculator(),
          
          const SizedBox(height: 32),
          
          // Casos de uso
          const Text(
            'Perfecto para:',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildUseCaseCard(
            emoji: '✈️',
            title: 'Viajeros',
            description: 'Organiza gastos de viajes grupales sin complicaciones',
          ),
          _buildUseCaseCard(
            emoji: '🏠',
            title: 'Roommates',
            description: 'Divide servicios y compras del hogar fácilmente',
          ),
          _buildUseCaseCard(
            emoji: '🎓',
            title: 'Estudiantes',
            description: 'Controla tu presupuesto mensual y ahorra más',
          ),
          _buildUseCaseCard(
            emoji: '💑',
            title: 'Parejas',
            description: 'Gestionen sus finanzas juntos de forma transparente',
          ),
          
          const SizedBox(height: 32),
          
          // Funciones Premium
          const Text(
            'Funciones Premium',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          _buildFeatureCard(
            icon: Icons.group,
            title: 'Eventos Ilimitados',
            description: 'Crea todos los eventos compartidos que necesites',
          ),
          _buildFeatureCard(
            icon: Icons.block,
            title: _strings.sinPublicidad,
            description: 'Experiencia completamente libre de anuncios',
          ),
          _buildFeatureCard(
            icon: Icons.cloud_upload,
            title: _strings.backupNube,
            description: 'Sincroniza tus datos en todos tus dispositivos',
          ),
          _buildFeatureCard(
            icon: Icons.analytics,
            title: 'Análisis Avanzados con IA',
            description: 'Predicciones y recomendaciones personalizadas',
          ),
          _buildFeatureCard(
            icon: Icons.attach_money,
            title: _strings.monedasMultiples,
            description: '16+ monedas y conversión automática',
          ),
          _buildFeatureCard(
            icon: Icons.category,
            title: _strings.misCategorias,
            description: 'Crea categorías personalizadas ilimitadas',
          ),
          _buildFeatureCard(
            icon: Icons.file_download,
            title: 'Exportar Informes PDF',
            description: 'Descarga informes profesionales para tu contador',
          ),
          _buildFeatureCard(
            icon: Icons.support_agent,
            title: _strings.soportePrioritario,
            description: 'Respuesta prioritaria en menos de 24 horas',
          ),
          
          const SizedBox(height: 32),
          
          // Testimonios
          const Text(
            'Lo que dicen nuestros usuarios',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildTestimonialCard(
            name: 'María G.',
            role: 'Viajera frecuente',
            rating: 5,
            comment: 'La función de eventos compartidos es increíble. Organicé un viaje con 8 amigos y todos supieron exactamente cuánto gastar. ¡Sin peleas!',
          ),
          _buildTestimonialCard(
            name: 'Carlos R.',
            role: 'Estudiante universitario',
            rating: 5,
            comment: 'Antes gastaba sin control. Con Zentavo Premium ahorro \$200 al mes. El análisis IA me ayudó a identificar gastos innecesarios.',
          ),
          _buildTestimonialCard(
            name: 'Ana & Pedro',
            role: 'Pareja',
            rating: 5,
            comment: 'Perfecta para manejar finanzas en pareja. Todo es transparente y fácil. Las categorías personalizadas son un plus.',
          ),
          
          const SizedBox(height: 32),
          
          // Garantía
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF22C55E), width: 2),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified_user, color: Color(0xFF22C55E), size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Garantía de 30 días',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Si no estás satisfecho, te devolvemos tu dinero sin preguntas',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Planes
          Text(
            'Elige tu Plan',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          if (kIsWeb || (!_isAvailable))
            _buildMockPurchaseOptions()
          else if (_products.isNotEmpty)
            _buildPurchaseOptions()
          else
            _buildUnavailableNotice(),
          const SizedBox(height: 24),
          if (!kIsWeb)
            TextButton(
              onPressed: _restorePurchases,
              child: Text(_strings.yaCompraste),
            ),
        ],
      ),
    );
  }

  Widget _buildUnavailableNotice() {
    return Card(
      color: const Color(0xFFFEF2F2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            const Text(
              'Las compras no están disponibles en este momento',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                });
                _initStoreInfo();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseOptions() {
    // Ordenar productos: monthly, yearly, lifetime
    _products.sort((a, b) {
      if (a.id == productIdMonthly) return -1;
      if (b.id == productIdMonthly) return 1;
      if (a.id == productIdYearly) return -1;
      if (b.id == productIdYearly) return 1;
      return 0;
    });

    return Column(
      children: _products.map((product) {
        return _buildPurchaseCard(product);
      }).toList(),
    );
  }

  Widget _buildPurchaseCard(ProductDetails product) {
    String title = '';
    String description = '';
    String badge = '';
    Color badgeColor = const Color(0xFF0EA5A4);
    IconData icon = Icons.star;

    if (product.id == productIdMonthly) {
      title = 'Premium Mensual';
      description = 'Acceso completo por 1 mes';
      badge = '';
      icon = Icons.calendar_month;
    } else if (product.id == productIdYearly) {
      title = 'Premium Anual';
      description = 'Acceso completo por 1 año';
      badge = 'MÁS POPULAR';
      badgeColor = const Color(0xFFEF4444);
      icon = Icons.calendar_today;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: product.id == productIdYearly
              ? const BorderSide(color: Color(0xFF0EA5A4), width: 3)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => _buyProduct(product),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (badge.isNotEmpty) const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(icon, size: 32, color: const Color(0xFF0EA5A4)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          product.price,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0EA5A4),
                          ),
                        ),
                        if (product.id == productIdYearly)
                          const Text(
                            '~\$4.17/mes',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: const Color(0xFFF9FAFB),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F8F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF0EA5A4), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockPurchaseOptions() {
    // Mostrar planes premium en Windows/Web con descuento del 50%
    final plans = [
      {
        'id': productIdMonthly,
        'title': 'Premium Mensual',
        'description': 'Acceso completo por 1 mes',
        'price': '\$2.49',
        'originalPrice': '\$4.99',
        'badge': '',
        'icon': Icons.calendar_month,
      },
      {
        'id': productIdYearly,
        'title': 'Premium Anual',
        'description': 'Acceso completo por 1 año',
        'price': '\$14.99',
        'originalPrice': '\$29.99',
        'badge': 'MÁS POPULAR',
        'icon': Icons.calendar_today,
      },
    ];

    return Column(
      children: plans.map((plan) {
        return _buildMockPurchaseCard(plan);
      }).toList(),
    );
  }

  Widget _buildMockPurchaseCard(Map<String, dynamic> plan) {
    String badge = plan['badge'] ?? '';
    Color badgeColor = badge == 'MÁS POPULAR'
        ? const Color(0xFFEF4444)
        : const Color(0xFF0EA5A4);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: plan['id'] == productIdYearly
              ? const BorderSide(color: Color(0xFF0EA5A4), width: 3)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: kIsWeb
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Descarga la app móvil para comprar Premium'),
                    ),
                  );
                }
              : () => _showDemoActivationDialog(plan['title']),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (badge.isNotEmpty) const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      plan['icon'] as IconData,
                      size: 32,
                      color: const Color(0xFF0EA5A4),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan['title'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan['description'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (plan['originalPrice'] != null)
                          Text(
                            plan['originalPrice'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              decoration: TextDecoration.lineThrough,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        Text(
                          plan['price'] as String,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0EA5A4),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '50% OFF',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDemoActivationDialog(String planName) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Activar Premium'),
          content: Text(
            'Para completar la compra de "$planName", utiliza la app móvil (disponible en Google Play y App Store).\n\n'
            '¿Deseas activar Premium en esta versión de escritorio para pruebas?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_premium', true);
                
                // Establecer plan y fecha de expiración basado en el plan seleccionado
                String planKey = '';
                DateTime? fechaExpiracion;
                
                if (planName.contains('Mensual') || planName.contains('Monthly')) {
                  planKey = 'Mensual';
                  fechaExpiracion = DateTime.now().add(const Duration(days: 30));
                } else if (planName.contains('Anual') || planName.contains('Yearly')) {
                  planKey = 'Anual';
                  fechaExpiracion = DateTime.now().add(const Duration(days: 365));
                } else {
                  planKey = 'De por vida';
                  fechaExpiracion = DateTime(2099, 12, 31);
                }
                
                await prefs.setString('premium_plan', planKey);
                await prefs.setString('premium_expiration', fechaExpiracion.toIso8601String());
                await prefs.setString('premium_purchase_date', DateTime.now().toIso8601String());
                
                setState(() {
                  _isPremium = true;
                });
                Navigator.pop(context);
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Premium activado! 🎉'),
                    backgroundColor: Color(0xFF0EA5A4),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5A4),
              ),
              child: const Text('Activar para pruebas'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildUseCaseCard({
    required String emoji,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF0EA5A4)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestimonialCard({
    required String name,
    required String role,
    required int rating,
    required String comment,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0EA5A4),
                  child: Text(
                    name[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        role,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    rating,
                    (index) => const Icon(
                      Icons.star,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.verified, color: Color(0xFF0EA5A4), size: 16),
                SizedBox(width: 4),
                Text(
                  'Usuario verificado',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0EA5A4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSavingsCalculator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22C55E), width: 2),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, color: Color(0xFF22C55E), size: 32),
              SizedBox(width: 12),
              Text(
                'Usuarios Premium ahorran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF22C55E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '\$247',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Color(0xFF22C55E),
            ),
          ),
          const Text(
            'en promedio por mes',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF059669),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('📊 Análisis IA', style: TextStyle(fontSize: 14)),
                    Text('+\$120/mes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF22C55E))),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('💡 Alertas inteligentes', style: TextStyle(fontSize: 14)),
                    Text('+\$87/mes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF22C55E))),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('📂 Categorías custom', style: TextStyle(fontSize: 14)),
                    Text('+\$40/mes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF22C55E))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Invierte \$4.99/mes → Ahorra \$247/mes',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF059669),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}