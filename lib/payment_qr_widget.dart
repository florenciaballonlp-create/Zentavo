import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'payment_request_service.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

/// Widget para mostrar QR de solicitud de pago (PREMIUM)
class PaymentQRWidget extends StatefulWidget {
  final String receptor;
  final double monto;
  final String moneda;
  final String concepto;
  final String? cbu;
  final String? email;
  final bool isDarkMode;
  final Color primaryColor;

  const PaymentQRWidget({
    Key? key,
    required this.receptor,
    required this.monto,
    required this.moneda,
    required this.concepto,
    this.cbu,
    this.email,
    required this.isDarkMode,
    required this.primaryColor,
  }) : super(key: key);

  @override
  State<PaymentQRWidget> createState() => _PaymentQRWidgetState();
}

class _PaymentQRWidgetState extends State<PaymentQRWidget> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isGeneratingImage = false;

  String get _qrData => PaymentRequestService.generarDatosQR(
        receptor: widget.receptor,
        monto: widget.monto,
        moneda: widget.moneda,
        concepto: widget.concepto,
        cbu: widget.cbu,
        email: widget.email,
      );

  Future<void> _copiarDatos() async {
    String datos = '';
    
    if (widget.cbu != null && widget.cbu!.isNotEmpty) {
      datos += 'CBU/CVU: ${widget.cbu}\n';
    }
    if (widget.email != null && widget.email!.isNotEmpty) {
      datos += 'Email PayPal: ${widget.email}\n';
    }
    datos += 'Monto: ${widget.moneda} ${widget.monto.toStringAsFixed(2)}';
    
    await Clipboard.setData(ClipboardData(text: datos));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Datos copiados al portapapeles'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _compartirQR() async {
    try {
      setState(() => _isGeneratingImage = true);
      
      // Capturar el QR como imagen
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('No se pudo capturar el QR');
      }
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      
      if (pngBytes == null) {
        throw Exception('Error al generar imagen');
      }
      
      // Compartir la imagen
      final result = await Share.shareXFiles(
        [XFile.fromData(pngBytes, mimeType: 'image/png', name: 'zentavo_qr_pago.png')],
        text: 'Solicitud de pago - ${widget.receptor}\nMonto: ${widget.moneda} ${widget.monto.toStringAsFixed(2)}\n${widget.concepto}',
      );
      
      setState(() => _isGeneratingImage = false);
    } catch (e) {
      setState(() => _isGeneratingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: bgColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.qr_code_2, color: widget.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Código QR de Pago',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor.withOpacity(0.6)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // QR Code
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _qrData,
                    version: QrVersions.auto,
                    size: 250.0,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: widget.primaryColor,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black87,
                    ),
                    embeddedImage: null,
                    embeddedImageStyle: const QrEmbeddedImageStyle(
                      size: Size(40, 40),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Información del pago
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      label: 'Receptor',
                      value: widget.receptor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.attach_money,
                      label: 'Monto',
                      value: '${widget.moneda} ${widget.monto.toStringAsFixed(2)}',
                      textColor: textColor,
                      isHighlight: true,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.description_outlined,
                      label: 'Concepto',
                      value: widget.concepto,
                      textColor: textColor,
                    ),
                    if (widget.cbu != null && widget.cbu!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.account_balance,
                        label: 'CBU/CVU',
                        value: widget.cbu!,
                        textColor: textColor,
                      ),
                    ],
                    if (widget.email != null && widget.email!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: widget.email!,
                        textColor: textColor,
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isGeneratingImage ? null : _copiarDatos,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar Datos'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: widget.primaryColor),
                        foregroundColor: widget.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingImage ? null : _compartirQR,
                      icon: _isGeneratingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share),
                      label: Text(_isGeneratingImage ? 'Generando...' : 'Compartir'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Nota informativa
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Comparte este QR con quien debe pagarte. Al escanearlo verá los datos de pago.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: textColor.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isHighlight ? 16 : 14,
                  color: textColor,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
