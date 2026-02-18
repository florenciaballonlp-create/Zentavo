import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Tipo de aplicación de pago
enum PaymentApp {
  mercadoPago,
  paypal,
  venmo,
  cashApp,
  zelle,
  transferencia,
}

/// Solicitud de pago
class PaymentRequest {
  final String id;
  final String receptor; // Quien recibe el dinero
  final String pagador; // Quien debe pagar
  final double monto;
  final String concepto;
  final String? moneda;
  final DateTime fechaCreacion;
  final DateTime? fechaPago;
  final bool pagado;
  final String? metodoPago;
  final String? notasReceptor;
  
  PaymentRequest({
    required this.id,
    required this.receptor,
    required this.pagador,
    required this.monto,
    required this.concepto,
    this.moneda,
    required this.fechaCreacion,
    this.fechaPago,
    this.pagado = false,
    this.metodoPago,
    this.notasReceptor,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receptor': receptor,
      'pagador': pagador,
      'monto': monto,
      'concepto': concepto,
      'moneda': moneda,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaPago': fechaPago?.toIso8601String(),
      'pagado': pagado,
      'metodoPago': metodoPago,
      'notasReceptor': notasReceptor,
    };
  }

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['id'] as String,
      receptor: json['receptor'] as String,
      pagador: json['pagador'] as String,
      monto: (json['monto'] as num).toDouble(),
      concepto: json['concepto'] as String,
      moneda: json['moneda'] as String?,
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
      fechaPago: json['fechaPago'] != null 
          ? DateTime.parse(json['fechaPago'] as String) 
          : null,
      pagado: json['pagado'] as bool? ?? false,
      metodoPago: json['metodoPago'] as String?,
      notasReceptor: json['notasReceptor'] as String?,
    );
  }

  PaymentRequest copyWith({
    String? id,
    String? receptor,
    String? pagador,
    double? monto,
    String? concepto,
    String? moneda,
    DateTime? fechaCreacion,
    DateTime? fechaPago,
    bool? pagado,
    String? metodoPago,
    String? notasReceptor,
  }) {
    return PaymentRequest(
      id: id ?? this.id,
      receptor: receptor ?? this.receptor,
      pagador: pagador ?? this.pagador,
      monto: monto ?? this.monto,
      concepto: concepto ?? this.concepto,
      moneda: moneda ?? this.moneda,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaPago: fechaPago ?? this.fechaPago,
      pagado: pagado ?? this.pagado,
      metodoPago: metodoPago ?? this.metodoPago,
      notasReceptor: notasReceptor ?? this.notasReceptor,
    );
  }
}

/// Servicio para gestionar solicitudes de pago (PREMIUM)
class PaymentRequestService {
  
  /// Genera deep link para Mercado Pago
  static String generarDeepLinkMercadoPago({
    required String receptor,
    required double monto,
    String? concepto,
  }) {
    // Mercado Pago deep link format
    final params = {
      'amount': monto.toString(),
      'description': concepto ?? 'Pago',
    };
    
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return 'mercadopago://pay?$query';
  }

  /// Genera deep link para PayPal
  static String generarDeepLinkPayPal({
    required String emailReceptor,
    required double monto,
    String? moneda,
    String? concepto,
  }) {
    final currency = moneda ?? 'USD';
    final params = {
      'cmd': '_pay',
      'reset': '1',
      'email': emailReceptor,
      'amount': monto.toString(),
      'currency_code': currency,
      'item_name': concepto ?? 'Pago',
    };
    
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return 'paypal://paymentreview?$query';
  }

  /// Genera deep link para Venmo
  static String generarDeepLinkVenmo({
    required String usuario,
    required double monto,
    String? concepto,
  }) {
    final params = {
      'txn': 'pay',
      'recipients': usuario,
      'amount': monto.toString(),
      'note': concepto ?? 'Pago',
    };
    
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return 'venmo://paycharge?$query';
  }

  /// Genera deep link para Cash App
  static String generarDeepLinkCashApp({
    required String cashtag,
    required double monto,
    String? concepto,
  }) {
    final params = {
      'amount': monto.toString(),
      'note': concepto ?? 'Pago',
    };
    
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return 'cashapp://cash.app/\$cashtag?$query';
  }

  /// Abre app de pago con deep link
  static Future<bool> abrirAppPago(String deepLink) async {
    try {
      final uri = Uri.parse(deepLink);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      print('Error al abrir app de pago: $e');
      return false;
    }
  }

  /// Genera mensaje de solicitud de pago para compartir
  static String generarMensajeSolicitud({
    required String nombreReceptor,
    required String nombrePagador,
    required double monto,
    required String simboloMoneda,
    String? concepto,
    String? cbu,
    String? alias,
    String? email,
    String? telefono,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('💰 *Solicitud de Pago - Zentavo*\n');
    buffer.writeln('Hola $nombrePagador,');
    buffer.writeln('');
    buffer.writeln('$nombreReceptor te solicita un pago de:');
    buffer.writeln('🔹 Monto: *$simboloMoneda${monto.toStringAsFixed(2)}*');
    
    if (concepto != null && concepto.isNotEmpty) {
      buffer.writeln('🔹 Concepto: $concepto');
    }
    
    buffer.writeln('');
    buffer.writeln('📱 *Opciones de pago:*\n');
    
    if (cbu != null && cbu.isNotEmpty) {
      buffer.writeln('🏦 Transferencia bancaria');
      buffer.writeln('   CBU/CVU: `$cbu`');
      if (alias != null && alias.isNotEmpty) {
        buffer.writeln('   Alias: $alias');
      }
      buffer.writeln('');
    }
    
    if (email != null && email.isNotEmpty) {
      buffer.writeln('📧 PayPal: $email');
      buffer.writeln('');
    }
    
    if (telefono != null && telefono.isNotEmpty) {
      buffer.writeln('📞 Mercado Pago / Otros: $telefono');
      buffer.writeln('');
    }
    
    buffer.writeln('💵 También puedes pagar en efectivo\n');
    buffer.writeln('Una vez realizado el pago, por favor confirma.');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('Generado con Zentavo 💚');
    
    return buffer.toString();
  }

  /// Genera datos para QR code de pago
  static String generarDatosQR({
    required String receptor,
    required double monto,
    required String moneda,
    String? concepto,
    String? cbu,
    String? email,
  }) {
    final data = {
      'app': 'Zentavo',
      'type': 'payment_request',
      'receptor': receptor,
      'monto': monto,
      'moneda': moneda,
      'concepto': concepto,
      'cbu': cbu,
      'email': email,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    return jsonEncode(data);
  }

  /// Obtiene información de la app de pago
  static Map<String, dynamic> getPaymentAppInfo(PaymentApp app) {
    switch (app) {
      case PaymentApp.mercadoPago:
        return {
          'nombre': 'Mercado Pago',
          'icono': '💳',
          'color': const Color(0xFF009EE3),
          'disponibleEn': ['AR', 'BR', 'MX', 'CL', 'CO'],
        };
      case PaymentApp.paypal:
        return {
          'nombre': 'PayPal',
          'icono': '🅿️',
          'color': const Color(0xFF0070BA),
          'disponibleEn': ['US', 'Global'],
        };
      case PaymentApp.venmo:
        return {
          'nombre': 'Venmo',
          'icono': '💸',
          'color': const Color(0xFF008CFF),
          'disponibleEn': ['US'],
        };
      case PaymentApp.cashApp:
        return {
          'nombre': 'Cash App',
          'icono': '💵',
          'color': const Color(0xFF00D632),
          'disponibleEn': ['US', 'UK'],
        };
      case PaymentApp.zelle:
        return {
          'nombre': 'Zelle',
          'icono': '⚡',
          'color': const Color(0xFF6D1ED4),
          'disponibleEn': ['US'],
        };
      case PaymentApp.transferencia:
        return {
          'nombre': 'Transferencia',
          'icono': '🏦',
          'color': const Color(0xFF4B5563),
          'disponibleEn': ['Global'],
        };
    }
  }

  /// Verifica si una app de pago está disponible en el país
  static bool isAppDisponibleEnPais(PaymentApp app, String codigoPais) {
    final info = getPaymentAppInfo(app);
    final disponibleEn = info['disponibleEn'] as List<String>;
    return disponibleEn.contains('Global') || disponibleEn.contains(codigoPais);
  }
}
