import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalLinksWidget extends StatelessWidget {
  const LegalLinksWidget({Key? key}) : super(key: key);

  static const String privacyUrl = 'https://zentavo.com/privacidad';
  static const String termsUrl = 'https://zentavo.com/terminos';

  void _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _launchUrl(context, privacyUrl),
                child: const Text(
                  'Política de Privacidad',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
              const Text('·', style: TextStyle(fontSize: 18, color: Colors.grey)),
              TextButton(
                onPressed: () => _launchUrl(context, termsUrl),
                child: const Text(
                  'Términos de Uso',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Al suscribirte aceptas nuestros términos y políticas.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}