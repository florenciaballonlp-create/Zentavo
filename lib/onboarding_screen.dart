import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization.dart';

/// Servicio para manejar el onboarding de nuevos usuarios
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyOnboardingVersion = 'onboarding_version';
  static const int _currentOnboardingVersion = 1;

  /// Verificar si el usuario ya completó el onboarding
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_keyOnboardingCompleted) ?? false;
    final version = prefs.getInt(_keyOnboardingVersion) ?? 0;
    
    // Si la versión cambió, mostrar onboarding nuevamente
    return completed && version >= _currentOnboardingVersion;
  }

  /// Marcar el onboarding como completado
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, true);
    await prefs.setInt(_keyOnboardingVersion, _currentOnboardingVersion);
  }

  /// Resetear el onboarding (para testing)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboardingCompleted);
    await prefs.remove(_keyOnboardingVersion);
  }
}

/// Pantalla de onboarding con tutorial interactivo
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  void _finishOnboarding() async {
    await OnboardingService().completeOnboarding();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior con botón de saltar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _currentPage > 0 ? _previousPage : null,
                    child: Text(
                      'Atrás',
                      style: TextStyle(
                        color: _currentPage > 0 ? const Color(0xFF0EA5A4) : Colors.grey,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text(
                      'Saltar',
                      style: TextStyle(color: Color(0xFF0EA5A4)),
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido de las páginas
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                  _buildPage4(),
                  _buildPage5(),
                ],
              ),
            ),

            // Indicadores de página
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF0EA5A4)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Botón de continuar
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5A4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage < 4 ? 'Siguiente' : 'Comenzar',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return _buildPageTemplate(
      icon: Icons.account_balance_wallet,
      color: const Color(0xFF0EA5A4),
      title: '¡Bienvenido a Control de Gastos!',
      description: 'La forma más simple y efectiva de controlar tus finanzas personales.',
      illustration: _buildIllustration1(),
    );
  }

  Widget _buildPage2() {
    return _buildPageTemplate(
      icon: Icons.add_circle,
      color: const Color(0xFF22C55E),
      title: 'Registra tus Ingresos y Egresos',
      description: 'Presiona el botón + para agregar una transacción. Puedes categorizar, agregar notas y fotos.',
      illustration: _buildIllustration2(),
    );
  }

  Widget _buildPage3() {
    return _buildPageTemplate(
      icon: Icons.people,
      color: const Color(0xFF6366F1),
      title: 'Eventos Compartidos',
      description: 'Crea eventos para viajes, reuniones o gastos grupales. Invita amigos y compartan gastos en tiempo real.',
      illustration: _buildIllustration3(),
    );
  }

  Widget _buildPage4() {
    return _buildPageTemplate(
      icon: Icons.bar_chart,
      color: const Color(0xFFF59E0B),
      title: 'Visualiza tu Progreso',
      description: 'Gráficos intuitivos te muestran en qué gastas más. Establece presupuestos y recibe recomendaciones personalizadas.',
      illustration: _buildIllustration4(),
    );
  }

  Widget _buildPage5() {
    return _buildPageTemplate(
      icon: Icons.workspace_premium,
      color: const Color(0xFF8B5CF6),
      title: 'Desbloquea tu Potencial',
      description: 'Prueba gratis y luego actualiza a Premium para eventos ilimitados, informes avanzados y más.',
      illustration: _buildIllustration5(),
    );
  }

  Widget _buildPageTemplate({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required Widget illustration,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustración
          illustration,
          const SizedBox(height: 40),
          
          // Icono
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: color),
          ),
          const SizedBox(height: 24),
          
          // Título
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          
          // Descripción
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration1() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF0EA5A4).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.monetization_on,
          size: 100,
          color: const Color(0xFF0EA5A4).withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildIllustration2() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 30,
            child: _buildMiniCard(Icons.arrow_upward, Colors.green, '\$500'),
          ),
          Positioned(
            bottom: 30,
            left: 30,
            child: _buildMiniCard(Icons.arrow_downward, Colors.red, '\$120'),
          ),
          Positioned(
            bottom: 50,
            right: 30,
            child: _buildMiniCard(Icons.shopping_bag, Colors.orange, '\$85'),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration3() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAvatar(Colors.blue),
            const SizedBox(width: 8),
            _buildAvatar(Colors.purple),
            const SizedBox(width: 8),
            _buildAvatar(Colors.pink),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration4() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: CustomPaint(
          painter: _SimpleChartPainter(),
        ),
      ),
    );
  }

  Widget _buildIllustration5() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.2),
            const Color(0xFFF59E0B).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(
          Icons.workspace_premium,
          size: 100,
          color: const Color(0xFF8B5CF6).withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildMiniCard(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Icon(Icons.person, color: color, size: 30),
    );
  }
}

class _SimpleChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.25, size.height * 0.4);
    path.lineTo(size.width * 0.5, size.height * 0.6);
    path.lineTo(size.width * 0.75, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.3);

    canvas.drawPath(path, paint);

    // Puntos
    final pointPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(0, size.height * 0.7), 5, pointPaint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.4), 5, pointPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.6), 5, pointPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.2), 5, pointPaint);
    canvas.drawCircle(Offset(size.width, size.height * 0.3), 5, pointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget para mostrar tooltips de ayuda sobre features específicas
class FeatureTooltip extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onGotIt;
  final Offset position;

  const FeatureTooltip({
    Key? key,
    required this.title,
    required this.description,
    this.onGotIt,
    required this.position,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo oscuro
        Container(
          color: Colors.black.withOpacity(0.7),
        ),
        
        // Tooltip
        Positioned(
          left: position.dx,
          top: position.dy,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: onGotIt ?? () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5A4),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text('¡Entendido!'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
