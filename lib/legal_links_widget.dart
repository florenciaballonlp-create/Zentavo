import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalLinksWidget extends StatelessWidget {
  const LegalLinksWidget({Key? key}) : super(key: key);

  static const String privacyUrl = 'https://www.zentavo.it/privacy.html';
  static const String termsUrl = 'https://www.zentavo.it/terms.html';

  String _tr(
    BuildContext context, {
    required String es,
    String? en,
    String? pt,
    String? it,
    String? zh,
    String? ja,
  }) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    switch (code) {
      case 'en':
        return en ?? es;
      case 'pt':
        return pt ?? es;
      case 'it':
        return it ?? es;
      case 'zh':
        return zh ?? es;
      case 'ja':
        return ja ?? es;
      default:
        return es;
    }
  }

  void _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final messenger = ScaffoldMessenger.of(context);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              context,
              es: 'No se pudo abrir el enlace.',
              en: 'Could not open the link.',
              pt: 'Não foi possível abrir o link.',
              it: 'Impossibile aprire il link.',
              zh: '无法打开链接。',
              ja: 'リンクを開けませんでした。',
            ),
          ),
        ),
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
                child: Text(
                  _tr(
                    context,
                    es: 'Política de Privacidad',
                    en: 'Privacy Policy',
                    pt: 'Política de Privacidade',
                    it: 'Informativa sulla privacy',
                    zh: '隐私政策',
                    ja: 'プライバシーポリシー',
                  ),
                  style: const TextStyle(decoration: TextDecoration.underline),
                ),
              ),
              const Text('·', style: TextStyle(fontSize: 18, color: Colors.grey)),
              TextButton(
                onPressed: () => _launchUrl(context, termsUrl),
                child: Text(
                  _tr(
                    context,
                    es: 'Términos de Uso',
                    en: 'Terms of Use',
                    pt: 'Termos de Uso',
                    it: 'Termini di utilizzo',
                    zh: '使用条款',
                    ja: '利用規約',
                  ),
                  style: const TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _tr(
              context,
              es: 'Al suscribirte aceptas nuestros términos y políticas.',
              en: 'By subscribing, you accept our terms and policies.',
              pt: 'Ao assinar, você aceita nossos termos e políticas.',
              it: 'Sottoscrivendo accetti i nostri termini e le nostre policy.',
              zh: '订阅即表示你同意我们的条款和政策。',
              ja: '購読すると、利用規約とポリシーに同意したことになります。',
            ),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}