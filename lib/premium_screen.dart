import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'legal_links_widget.dart';
import 'localization.dart';

class PremiumScreen extends StatefulWidget {
  final AppStrings? strings;
  final String? source;

  const PremiumScreen({this.strings, this.source, super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  static const String productIdMonthly = 'premium_monthly_v2';
  static const String productIdYearly = 'premium_yearly_v2';
  static const String legacyProductIdMonthly = 'premium_monthly';
  static const String legacyProductIdYearly = 'premium_yearly';

  static const Set<String> _productIds = {
    productIdMonthly,
    productIdYearly,
    legacyProductIdMonthly,
    legacyProductIdYearly,
  };

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _loading = true;
  bool _isPremium = false;
  bool _storeAvailable = false;
  List<ProductDetails> _products = <ProductDetails>[];
  String? _storeErrorMessage;
  List<String> _notFoundProductIds = <String>[];

  AppStrings get _strings => widget.strings ?? AppStrings();

  String _tr({
    required String es,
    String? en,
    String? pt,
    String? it,
    String? zh,
    String? ja,
  }) {
    switch (_strings.language) {
      case AppLanguage.english:
        return en ?? es;
      case AppLanguage.portuguese:
        return pt ?? es;
      case AppLanguage.italian:
        return it ?? es;
      case AppLanguage.chinese:
        return zh ?? es;
      case AppLanguage.japanese:
        return ja ?? es;
      case AppLanguage.spanish:
        return es;
    }
  }

  bool get _supportsNativeStore {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadPremiumStatus();

    if (_supportsNativeStore) {
      await _initStoreInfo();
    } else if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool('is_premium') ?? false;

    if (!mounted) {
      return;
    }

    setState(() {
      _isPremium = isPremium;
    });
  }

  Future<void> _initStoreInfo() async {
    final available = await _inAppPurchase.isAvailable();

    if (!mounted) {
      return;
    }

    if (!available) {
      setState(() {
        _storeAvailable = false;
        _storeErrorMessage = _tr(
          es: 'La tienda no está disponible en este momento.',
          en: 'The store is currently unavailable.',
          pt: 'A loja não está disponível no momento.',
          it: 'Lo store non è disponibile in questo momento.',
          zh: '商店当前不可用。',
          ja: '現在ストアを利用できません。',
        );
        _loading = false;
      });
      return;
    }

    _purchaseSubscription ??= _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onError: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _storeAvailable = false;
          _storeErrorMessage = _tr(
            es: 'Error al escuchar actualizaciones de compra.',
            en: 'Error while listening for purchase updates.',
            pt: 'Erro ao ouvir atualizações de compra.',
            it: 'Errore durante l’ascolto degli aggiornamenti di acquisto.',
            zh: '监听购买更新时出错。',
            ja: '購入更新の監視中にエラーが発生しました。',
          );
        });
      },
    );

    final response = await _inAppPurchase.queryProductDetails(_productIds);
    final products = response.productDetails.toList();
    final hasProducts = products.isNotEmpty;
    final notFound = response.notFoundIDs.toList();
    final storeError = response.error?.message;

    String? friendlyError;
    if (storeError != null && storeError.isNotEmpty) {
      friendlyError = storeError;
    } else if (!hasProducts) {
      friendlyError = _tr(
        es: 'No se pudieron cargar las suscripciones. Verifica los IDs de productos en App Store Connect.',
        en: 'Subscriptions could not be loaded. Verify product IDs in App Store Connect.',
        pt: 'Não foi possível carregar as assinaturas. Verifique os IDs dos produtos no App Store Connect.',
        it: 'Impossibile caricare gli abbonamenti. Verifica gli ID prodotto in App Store Connect.',
        zh: '无法加载订阅。请检查 App Store Connect 中的产品 ID。',
        ja: 'サブスクリプションを読み込めませんでした。App Store Connect の製品IDを確認してください。',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _storeAvailable = response.error == null && hasProducts;
      _products = products;
      _notFoundProductIds = notFound;
      _storeErrorMessage = friendlyError;
      _loading = false;
    });
  }

  Future<void> _retryLoadProducts() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _storeErrorMessage = null;
    });

    await _initStoreInfo();
  }

  Future<void> _activatePremium({String? planName}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    DateTime? expiration;

    if (planName != null) {
      if (planName.contains('Mensual') || planName.contains('Monthly')) {
        expiration = now.add(const Duration(days: 30));
      } else if (planName.contains('Anual') || planName.contains('Yearly')) {
        expiration = now.add(const Duration(days: 365));
      }
    }

    await prefs.setBool('is_premium', true);
    await prefs.setString('premium_purchase_date', now.toIso8601String());
    if (planName != null) {
      await prefs.setString('premium_plan', planName);
    }
    if (expiration != null) {
      await prefs.setString('premium_expiration', expiration.toIso8601String());
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isPremium = true;
    });

    Navigator.of(context).pop(true);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        final planName = purchaseDetails.productID == productIdYearly
            ? 'Premium Anual'
            : 'Premium Mensual';
        _activatePremium(planName: planName);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  void _buyProduct(ProductDetails productDetails) {
    final purchaseParam = PurchaseParam(productDetails: productDetails);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _restorePurchases() async {
    await _inAppPurchase.restorePurchases();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _tr(
            es: 'Se restauraron las compras.',
            en: 'Purchases were restored.',
            pt: 'As compras foram restauradas.',
            it: 'Gli acquisti sono stati ripristinati.',
            zh: '购买已恢复。',
            ja: '購入が復元されました。',
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(_tr(es: 'Premium'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isPremium
              ? _buildPremiumActiveUI()
              : _buildPremiumOffersUI(),
    );
  }

  Widget _buildPremiumActiveUI() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr(
                    es: 'Premium activo',
                    en: 'Premium active',
                    pt: 'Premium ativo',
                    it: 'Premium attivo',
                    zh: '高级版已激活',
                    ja: 'プレミアム有効',
                  ),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _tr(
                    es: 'Tu cuenta ya tiene acceso a las funciones premium.',
                    en: 'Your account already has access to premium features.',
                    pt: 'Sua conta já tem acesso aos recursos premium.',
                    it: 'Il tuo account ha già accesso alle funzioni premium.',
                    zh: '你的账户已可使用高级功能。',
                    ja: 'あなたのアカウントはプレミアム機能を利用できます。',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const LegalLinksWidget(),
      ],
    );
  }

  Widget _buildPremiumOffersUI() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          _tr(
            es: 'Desbloquea Zentavo Premium',
            en: 'Unlock Zentavo Premium',
            pt: 'Desbloqueie o Zentavo Premium',
            it: 'Sblocca Zentavo Premium',
            zh: '解锁 Zentavo Premium',
            ja: 'Zentavo Premiumをアンロック',
          ),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.source == null
              ? _tr(
                  es: 'Accede a herramientas avanzadas para exportar, compartir y organizar tus gastos.',
                  en: 'Access advanced tools to export, share and organize your expenses.',
                  pt: 'Acesse ferramentas avançadas para exportar, compartilhar e organizar seus gastos.',
                  it: 'Accedi a strumenti avanzati per esportare, condividere e organizzare le tue spese.',
                  zh: '使用高级工具来导出、分享和管理你的支出。',
                  ja: '支出をエクスポート・共有・整理するための高度な機能を利用できます。',
                )
              : _tr(
                  es: 'Continúa desde ${widget.source} con acceso a funciones avanzadas.',
                  en: 'Continue from ${widget.source} with access to advanced features.',
                  pt: 'Continue de ${widget.source} com acesso a recursos avançados.',
                  it: 'Continua da ${widget.source} con accesso alle funzioni avanzate.',
                  zh: '从 ${widget.source} 继续，并使用高级功能。',
                  ja: '${widget.source} から続けて高度な機能を利用できます。',
                ),
        ),
        const SizedBox(height: 24),
        _buildFeatureCard(
          icon: Icons.picture_as_pdf,
          title: _tr(
            es: 'Exportaciones avanzadas',
            en: 'Advanced exports',
            pt: 'Exportações avançadas',
            it: 'Esportazioni avanzate',
            zh: '高级导出',
            ja: '高度なエクスポート',
          ),
          description: _tr(
            es: 'Genera reportes y comparte información con mejor control.',
            en: 'Generate reports and share information with better control.',
            pt: 'Gere relatórios e compartilhe informações com mais controle.',
            it: 'Genera report e condividi informazioni con maggiore controllo.',
            zh: '生成报告并更好地掌控分享信息。',
            ja: 'レポートを作成し、情報共有をより細かく管理できます。',
          ),
        ),
        _buildFeatureCard(
          icon: Icons.people_alt_outlined,
          title: _strings.eventosCompartidos,
          description: _tr(
            es: 'Coordina gastos entre varias personas de forma más clara.',
            en: 'Coordinate expenses among multiple people more clearly.',
            pt: 'Coordene gastos entre várias pessoas com mais clareza.',
            it: 'Coordina le spese tra più persone in modo più chiaro.',
            zh: '更清晰地协调多人共同支出。',
            ja: '複数人の支出をより分かりやすく管理できます。',
          ),
        ),
        _buildFeatureCard(
          icon: Icons.workspace_premium_outlined,
          title: _tr(
            es: 'Experiencia completa',
            en: 'Full experience',
            pt: 'Experiência completa',
            it: 'Esperienza completa',
            zh: '完整体验',
            ja: 'フル体験',
          ),
          description: _tr(
            es: 'Mantén acceso a funciones premium desde una sola cuenta.',
            en: 'Keep access to premium features from a single account.',
            pt: 'Mantenha acesso aos recursos premium com uma única conta.',
            it: 'Mantieni l’accesso alle funzioni premium da un unico account.',
            zh: '通过一个账户持续使用高级功能。',
            ja: '1つのアカウントでプレミアム機能を利用できます。',
          ),
        ),
        const SizedBox(height: 24),
        if (_supportsNativeStore && _storeAvailable && _products.isNotEmpty)
          ..._products.map(_buildProductCard),
        if (_supportsNativeStore && !_storeAvailable)
          _buildStoreUnavailableCard(),
        if (!_supportsNativeStore)
          ..._buildCatalogOnlyPlans(),
        if (_supportsNativeStore)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _restorePurchases,
              child: Text(_strings.restaurarCompras),
            ),
          ),
        const SizedBox(height: 12),
        const LegalLinksWidget(),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE6FFFB),
          child: Icon(icon, color: const Color(0xFF0EA5A4)),
        ),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }

  List<Widget> _buildCatalogOnlyPlans() {
    final plans = [
      {
        'title': _tr(
          es: 'Premium Mensual',
          en: 'Premium Monthly',
          pt: 'Premium Mensal',
          it: 'Premium Mensile',
          zh: '高级版（月付）',
          ja: 'プレミアム（月額）',
        ),
        'description': _tr(
          es: 'Acceso completo por 1 mes',
          en: 'Full access for 1 month',
          pt: 'Acesso completo por 1 mês',
          it: 'Accesso completo per 1 mese',
          zh: '1个月完整访问权限',
          ja: '1か月間フルアクセス',
        ),
        'price': '\$2.49',
      },
      {
        'title': _tr(
          es: 'Premium Anual',
          en: 'Premium Yearly',
          pt: 'Premium Anual',
          it: 'Premium Annuale',
          zh: '高级版（年付）',
          ja: 'プレミアム（年額）',
        ),
        'description': _tr(
          es: 'Acceso completo por 1 año',
          en: 'Full access for 1 year',
          pt: 'Acesso completo por 1 ano',
          it: 'Accesso completo per 1 anno',
          zh: '1年完整访问权限',
          ja: '1年間フルアクセス',
        ),
        'price': '\$14.99',
      },
    ];

    return plans
        .map(
          (plan) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(plan['title']!),
              subtitle: Text(plan['description']!),
              trailing: Text(
                plan['price']!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: null,
            ),
          ),
        )
        .toList();
  }

  Widget _buildStoreUnavailableCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr(
                es: 'Compras no disponibles temporalmente',
                en: 'Purchases temporarily unavailable',
                pt: 'Compras temporariamente indisponíveis',
                it: 'Acquisti temporaneamente non disponibili',
                zh: '购买暂时不可用',
                ja: '購入は一時的に利用できません',
              ),
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _storeErrorMessage ??
                  _tr(
                es: 'Intenta nuevamente en unos minutos o usa Restaurar compras si ya tienes una suscripcion activa.',
                en: 'Try again in a few minutes or use Restore purchases if you already have an active subscription.',
                pt: 'Tente novamente em alguns minutos ou use Restaurar compras se já tiver uma assinatura ativa.',
                it: 'Riprova tra qualche minuto oppure usa Ripristina acquisti se hai già un abbonamento attivo.',
                zh: '请稍后再试，若你已有有效订阅，请使用“恢复购买”。',
                ja: '数分後に再試行するか、有効なサブスクリプションがある場合は「購入を復元」を使用してください。',
              ),
            ),
            if (_notFoundProductIds.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '${_tr(es: 'IDs no encontrados', en: 'Missing IDs', pt: 'IDs não encontrados', it: 'ID non trovati', zh: '未找到的ID', ja: '見つからないID')}: ${_notFoundProductIds.join(', ')}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _retryLoadProducts,
                icon: const Icon(Icons.refresh),
                label: Text(
                  _tr(
                    es: 'Reintentar',
                    en: 'Retry',
                    pt: 'Tentar novamente',
                    it: 'Riprova',
                    zh: '重试',
                    ja: '再試行',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductDetails product) {
    final isYearly =
        product.id == productIdYearly || product.id == legacyProductIdYearly;
    final termText = isYearly
        ? _tr(
            es: 'Duración: 1 año',
            en: 'Length: 1 year',
            pt: 'Duração: 1 ano',
            it: 'Durata: 1 anno',
            zh: '时长：1年',
            ja: '期間: 1年',
          )
        : _tr(
            es: 'Duración: 1 mes',
            en: 'Length: 1 month',
            pt: 'Duração: 1 mês',
            it: 'Durata: 1 mese',
            zh: '时长：1个月',
            ja: '期間: 1か月',
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isYearly
            ? const BorderSide(color: Color(0xFF0EA5A4), width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        title: Text(product.title),
        subtitle: Text('${product.description}\n$termText'),
        isThreeLine: true,
        trailing: Text(
          product.price,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onTap: () => _buyProduct(product),
      ),
    );
  }
}
