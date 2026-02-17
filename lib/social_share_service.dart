import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

/// Servicio para compartir contenido en redes sociales
class SocialShareService {
  static final SocialShareService _instance = SocialShareService._internal();
  factory SocialShareService() => _instance;
  SocialShareService._internal();

  /// Compartir texto simple
  Future<void> shareText(String text) async {
    await Share.share(text);
  }

  /// Compartir con título y texto
  Future<void> shareWithTitle(String title, String text) async {
    await Share.share(text, subject: title);
  }

  /// Compartir archivo
  Future<void> shareFile(String filePath, {String? text}) async {
    await Share.shareXFiles([XFile(filePath)], text: text);
  }

  /// Compartir múltiples archivos
  Future<void> shareFiles(List<String> filePaths, {String? text}) async {
    final xFiles = filePaths.map((path) => XFile(path)).toList();
    await Share.shareXFiles(xFiles, text: text);
  }

  /// Compartir logro de ahorro
  Future<void> shareAhorroLogro({
    required double montoAhorrado,
    required String periodo,
  }) async {
    final text = '''
🎉 ¡Logré ahorrar \$$montoAhorrado en $periodo!

Con Control de Gastos mantengo mis finanzas organizadas y alcanzo mis metas.

#ControlDeGastos #Ahorro #FinanzasPersonales
''';
    await shareText(text);
  }

  /// Compartir meta alcanzada
  Future<void> shareMetaAlcanzada({
    required String meta,
    required double monto,
  }) async {
    final text = '''
✨ ¡Alcancé mi meta de "$meta"!

Ahorré \$$monto gracias a un mejor control de mis gastos.

#MetasCumplidas #Ahorro #ControlDeGastos
''';
    await shareText(text);
  }

  /// Compartir estadística interesante
  Future<void> shareEstadistica({
    required String titulo,
    required String descripcion,
  }) async {
    final text = '''
📊 $titulo

$descripcion

Control de Gastos me ayuda a entender mejor mis finanzas.

#FinanzasPersonales #Ahorro
''';
    await shareText(text);
  }

  /// Compartir racha de días registrando gastos
  Future<void> shareRacha(int dias) async {
    final text = '''
🔥 ¡Llevo $dias días registrando mis gastos!

La constancia es clave para el control financiero.

#ControlDeGastos #Disciplina #Finanzas
''';
    await shareText(text);
  }

  /// Compartir invitación a la app
  Future<void> shareInvitacion() async {
    final text = '''
💰 ¡Descubre Control de Gastos!

La app que me ayuda a mantener mis finanzas organizadas:
✅ Registra ingresos y egresos
✅ Gráficos e informes intuitivos
✅ Eventos compartidos para gastos grupales
✅ Presupuestos y recomendaciones personalizadas

¡Descárgala gratis!

#App #FinanzasPersonales #Ahorro
''';
    await shareText(text);
  }

  /// Compartir código de evento compartido
  Future<void> shareCodigoEvento({
    required String nombreEvento,
    required String codigo,
  }) async {
    final text = '''
🎉 Te invito a "$nombreEvento"

Código de acceso: $codigo

Descarga Control de Gastos y únete para compartir gastos fácilmente.

#EventosCompartidos #ControlDeGastos
''';
    await shareText(text);
  }

  /// Compartir informe mensual (con imagen)
  Future<void> shareReporteMensual({
    required String mes,
    required double ingresos,
    required double egresos,
    required double balance,
    String? imagePath,
  }) async {
    final emoji = balance >= 0 ? '📈' : '📉';
    final text = '''
$emoji Informe de $mes

💵 Ingresos: \$$ingresos
💸 Egresos: \$$egresos
💰 Balance: \$$balance

#FinanzasPersonales #Informe #ControlDeGastos
''';

    if (imagePath != null) {
      await Share.shareXFiles([XFile(imagePath)], text: text);
    } else {
      await shareText(text);
    }
  }

  /// Crear imagen de widget y compartir
  Future<void> shareWidgetAsImage({
    required GlobalKey widgetKey,
    required String text,
    String fileName = 'informe.png',
  }) async {
    try {
      // Capturar el widget como imagen
      final RenderRepaintBoundary boundary = widgetKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Guardar en temporal
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // Compartir
      await Share.shareXFiles([XFile(file.path)], text: text);
    } catch (e) {
      print('[SOCIAL_SHARE] Error sharing widget as image: $e');
    }
  }
}

/// Widget para mostrar opciones de compartir
class ShareOptionsBottomSheet extends StatelessWidget {
  final String shareText;
  final String? shareTitle;
  final String? imagePath;
  final VoidCallback? onShareAchievement;
  final VoidCallback? onShareInvitation;

  const ShareOptionsBottomSheet({
    Key? key,
    required this.shareText,
    this.shareTitle,
    this.imagePath,
    this.onShareAchievement,
    this.onShareInvitation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.share, color: Color(0xFF0EA5A4)),
              const SizedBox(width: 12),
              const Text(
                'Compartir',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildShareOption(
            context,
            icon: Icons.insert_link,
            title: 'Compartir texto',
            description: 'Compartir como mensaje',
            color: const Color(0xFF0EA5A4),
            onTap: () {
              SocialShareService().shareWithTitle(shareTitle ?? '', shareText);
              Navigator.pop(context);
            },
          ),
          
          if (imagePath != null) ...[
            const SizedBox(height: 12),
            _buildShareOption(
              context,
              icon: Icons.image,
              title: 'Compartir con imagen',
              description: 'Incluir captura de pantalla',
              color: const Color(0xFF6366F1),
              onTap: () {
                SocialShareService().shareFile(imagePath!, text: shareText);
                Navigator.pop(context);
              },
            ),
          ],
          
          if (onShareAchievement != null) ...[
            const SizedBox(height: 12),
            _buildShareOption(
              context,
              icon: Icons.emoji_events,
              title: 'Compartir logro',
              description: 'Comparte tu progreso',
              color: const Color(0xFFF59E0B),
              onTap: () {
                onShareAchievement!();
                Navigator.pop(context);
              },
            ),
          ],
          
          if (onShareInvitation != null) ...[
            const SizedBox(height: 12),
            _buildShareOption(
              context,
              icon: Icons.group_add,
              title: 'Invitar amigos',
              description: 'Recomienda la app',
              color: const Color(0xFF22C55E),
              onTap: () {
                onShareInvitation!();
                Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

/// Widget reutilizable para botón de compartir
class ShareButton extends StatelessWidget {
  final String shareText;
  final String? shareTitle;
  final String? imagePath;
  final VoidCallback? onShareAchievement;
  final VoidCallback? onShareInvitation;
  final IconData icon;
  final String? label;
  final Color? color;
  final bool isCompact;

  const ShareButton({
    Key? key,
    required this.shareText,
    this.shareTitle,
    this.imagePath,
    this.onShareAchievement,
    this.onShareInvitation,
    this.icon = Icons.share,
    this.label,
    this.color,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? const Color(0xFF0EA5A4);

    if (isCompact) {
      return IconButton(
        icon: Icon(icon, color: buttonColor),
        onPressed: () => _showShareOptions(context),
      );
    }

    if (label != null) {
      return ElevatedButton.icon(
        onPressed: () => _showShareOptions(context),
        icon: Icon(icon),
        label: Text(label!),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
        ),
      );
    }

    return FloatingActionButton(
      onPressed: () => _showShareOptions(context),
      backgroundColor: buttonColor,
      child: Icon(icon, color: Colors.white),
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareOptionsBottomSheet(
        shareText: shareText,
        shareTitle: shareTitle,
        imagePath: imagePath,
        onShareAchievement: onShareAchievement,
        onShareInvitation: onShareInvitation,
      ),
    );
  }
}

/// Dialog para celebrar logros y compartirlos
class AchievementShareDialog extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onShare;

  const AchievementShareDialog({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      onShare();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mostrar dialog de logro de forma rápida
void showAchievementDialog({
  required BuildContext context,
  required String title,
  required String description,
  required IconData icon,
  required Color color,
  required VoidCallback onShare,
}) {
  showDialog(
    context: context,
    builder: (context) => AchievementShareDialog(
      title: title,
      description: description,
      icon: icon,
      color: color,
      onShare: onShare,
    ),
  );
}
