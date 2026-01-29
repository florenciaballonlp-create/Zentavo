import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.nextScreen),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF10B981),
              Color(0xFF059669),
              Color(0xFF047857),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo personalizado
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'images/logo.png',
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Si no encuentra la imagen, muestra el ícono por defecto
                        return const Icon(
                          Icons.account_balance_wallet,
                          size: 130,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Nombre de la app
                  const Text(
                    'Zentavo',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(2, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtítulo
                  Text(
                    'Tu control financiero',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Indicador de carga
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
