import 'package:flutter/material.dart';

/// Frecuencia de recurrencia de transacciones
enum RecurringFrequency {
  daily,      // Diaria
  weekly,     // Semanal
  biweekly,   // Quincenal
  monthly,    // Mensual
  yearly,     // Anual
}

/// Modelo de transacción recurrente
class RecurringTransaction {
  final String id;
  final String titulo;
  final double monto;
  final String tipo; // 'Ingreso' o 'Egreso'
  final String categoria;
  final String justificacion;
  final RecurringFrequency frecuencia;
  final DateTime fechaInicio;
  final DateTime? fechaFin; // null = sin fin
  final DateTime? ultimaGeneracion;
  final bool activa;
  final String? moneda;

  RecurringTransaction({
    required this.id,
    required this.titulo,
    required this.monto,
    required this.tipo,
    required this.categoria,
    required this.justificacion,
    required this.frecuencia,
    required this.fechaInicio,
    this.fechaFin,
    this.ultimaGeneracion,
    this.activa = true,
    this.moneda,
  });

  /// Convierte a Map para guardar en SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'monto': monto,
      'tipo': tipo,
      'categoria': categoria,
      'justificacion': justificacion,
      'frecuencia': frecuencia.index,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin?.toIso8601String(),
      'ultimaGeneracion': ultimaGeneracion?.toIso8601String(),
      'activa': activa,
      'moneda': moneda,
    };
  }

  /// Crea desde Map guardado
  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      monto: (json['monto'] as num).toDouble(),
      tipo: json['tipo'] as String,
      categoria: json['categoria'] as String,
      justificacion: json['justificacion'] as String,
      frecuencia: RecurringFrequency.values[json['frecuencia'] as int],
      fechaInicio: DateTime.parse(json['fechaInicio'] as String),
      fechaFin: json['fechaFin'] != null ? DateTime.parse(json['fechaFin'] as String) : null,
      ultimaGeneracion: json['ultimaGeneracion'] != null 
          ? DateTime.parse(json['ultimaGeneracion'] as String) 
          : null,
      activa: json['activa'] as bool? ?? true,
      moneda: json['moneda'] as String?,
    );
  }

  /// Crea copia con campos modificados
  RecurringTransaction copyWith({
    String? id,
    String? titulo,
    double? monto,
    String? tipo,
    String? categoria,
    String? justificacion,
    RecurringFrequency? frecuencia,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    DateTime? ultimaGeneracion,
    bool? activa,
    String? moneda,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      monto: monto ?? this.monto,
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
      justificacion: justificacion ?? this.justificacion,
      frecuencia: frecuencia ?? this.frecuencia,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      ultimaGeneracion: ultimaGeneracion ?? this.ultimaGeneracion,
      activa: activa ?? this.activa,
      moneda: moneda ?? this.moneda,
    );
  }

  /// Calcula la próxima fecha de generación
  DateTime? getProximaFecha() {
    final base = ultimaGeneracion ?? fechaInicio;
    
    switch (frecuencia) {
      case RecurringFrequency.daily:
        return base.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return base.add(const Duration(days: 7));
      case RecurringFrequency.biweekly:
        return base.add(const Duration(days: 14));
      case RecurringFrequency.monthly:
        // Mantener el mismo día del mes
        int mes = base.month + 1;
        int anio = base.year;
        if (mes > 12) {
          mes = 1;
          anio++;
        }
        // Ajustar día si el mes tiene menos días
        int dia = base.day;
        final diasEnMes = DateTime(anio, mes + 1, 0).day;
        if (dia > diasEnMes) dia = diasEnMes;
        return DateTime(anio, mes, dia);
      case RecurringFrequency.yearly:
        return DateTime(base.year + 1, base.month, base.day);
    }
  }

  /// Verifica si debe generar una nueva transacción hoy
  bool debeGenerar() {
    if (!activa) return false;
    
    final ahora = DateTime.now();
    
    // No generar si ya pasó la fecha fin
    if (fechaFin != null && ahora.isAfter(fechaFin!)) return false;
    
    // No generar si aún no llega la fecha de inicio
    if (ahora.isBefore(fechaInicio)) return false;
    
    // Si nunca se generó, generar si ya pasó la fecha de inicio
    if (ultimaGeneracion == null) {
      return !ahora.isBefore(fechaInicio);
    }
    
    final proxima = getProximaFecha();
    if (proxima == null) return false;
    
    // Generar si la fecha actual es >= próxima fecha
    return !ahora.isBefore(proxima);
  }

  /// Obtiene string de frecuencia localizado
  String getFrecuenciaString(String idioma) {
    switch (frecuencia) {
      case RecurringFrequency.daily:
        return idioma == 'es' ? 'Diaria' : 'Daily';
      case RecurringFrequency.weekly:
        return idioma == 'es' ? 'Semanal' : 'Weekly';
      case RecurringFrequency.biweekly:
        return idioma == 'es' ? 'Quincenal' : 'Biweekly';
      case RecurringFrequency.monthly:
        return idioma == 'es' ? 'Mensual' : 'Monthly';
      case RecurringFrequency.yearly:
        return idioma == 'es' ? 'Anual' : 'Yearly';
    }
  }
}

/// Servicio para gestionar transacciones recurrentes
class RecurringTransactionService {
  /// Genera transacciones pendientes desde recurrencias
  static List<Map<String, dynamic>> generarTransaccionesPendientes(
    List<RecurringTransaction> recurrencias,
  ) {
    final transaccionesGeneradas = <Map<String, dynamic>>[];
    
    for (final recurrencia in recurrencias) {
      if (recurrencia.debeGenerar()) {
        transaccionesGeneradas.add({
          'id': '${DateTime.now().millisecondsSinceEpoch}_${recurrencia.id}',
          'titulo': recurrencia.titulo,
          'monto': recurrencia.monto,
          'tipo': recurrencia.tipo,
          'categoria': recurrencia.categoria,
          'justificacion': recurrencia.justificacion,
          'fecha': DateTime.now().toIso8601String(),
          'moneda': recurrencia.moneda,
          'esRecurrente': true,
          'recurrenciaId': recurrencia.id,
        });
      }
    }
    
    return transaccionesGeneradas;
  }

  /// Actualiza la fecha de última generación de una recurrencia
  static RecurringTransaction marcarComoGenerada(RecurringTransaction recurrencia) {
    return recurrencia.copyWith(
      ultimaGeneracion: DateTime.now(),
    );
  }
}
