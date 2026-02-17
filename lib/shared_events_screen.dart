import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:math';
import 'localization.dart';
import 'premium_screen.dart';

/// Modelo de datos para un evento compartido
class EventoCompartido {
  String id;
  String nombre;
  String descripcion;
  double presupuesto;
  DateTime fechaInicio;
  DateTime? fechaFin;
  List<Participante> participantes;
  List<GastoCompartido> gastos;
  String colorHex;
  String codigoCompartir;

  EventoCompartido({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    required this.presupuesto,
    required this.fechaInicio,
    this.fechaFin,
    required this.participantes,
    required this.gastos,
    this.colorHex = 'FF6366F1',
    required this.codigoCompartir,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'presupuesto': presupuesto,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin?.toIso8601String(),
      'participantes': participantes.map((p) => p.toJson()).toList(),
      'gastos': gastos.map((g) => g.toJson()).toList(),
      'colorHex': colorHex,
      'codigoCompartir': codigoCompartir,
    };
  }

  factory EventoCompartido.fromJson(Map<String, dynamic> json) {
    return EventoCompartido(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'] ?? '',
      presupuesto: (json['presupuesto'] as num).toDouble(),
      fechaInicio: DateTime.parse(json['fechaInicio']),
      fechaFin: json['fechaFin'] != null ? DateTime.parse(json['fechaFin']) : null,
      participantes: (json['participantes'] as List)
          .map((p) => Participante.fromJson(p))
          .toList(),
      gastos: (json['gastos'] as List)
          .map((g) => GastoCompartido.fromJson(g))
          .toList(),
      colorHex: json['colorHex'] ?? 'FF6366F1',
      codigoCompartir: json['codigoCompartir'],
    );
  }

  double get totalGastado {
    return gastos.fold(0.0, (sum, gasto) => sum + gasto.monto);
  }

  double get saldoRestante {
    return presupuesto - totalGastado;
  }

  double get porcentajeGastado {
    return presupuesto > 0 ? (totalGastado / presupuesto * 100) : 0;
  }
}

/// Modelo de participante en un evento
class Participante {
  String id;
  String nombre;
  String? avatar;
  bool esYo;

  Participante({
    required this.id,
    required this.nombre,
    this.avatar,
    this.esYo = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'avatar': avatar,
      'esYo': esYo,
    };
  }

  factory Participante.fromJson(Map<String, dynamic> json) {
    return Participante(
      id: json['id'],
      nombre: json['nombre'],
      avatar: json['avatar'],
      esYo: json['esYo'] ?? false,
    );
  }
}

/// Modelo de gasto compartido
class GastoCompartido {
  String id;
  String titulo;
  double monto;
  String categoria;
  String participanteId;
  DateTime fecha;
  String? notas;
  String? recibo; // Path a imagen de recibo (opcional)

  GastoCompartido({
    required this.id,
    required this.titulo,
    required this.monto,
    required this.categoria,
    required this.participanteId,
    required this.fecha,
    this.notas,
    this.recibo,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'monto': monto,
      'categoria': categoria,
      'participanteId': participanteId,
      'fecha': fecha.toIso8601String(),
      'notas': notas,
      'recibo': recibo,
    };
  }

  factory GastoCompartido.fromJson(Map<String, dynamic> json) {
    return GastoCompartido(
      id: json['id'],
      titulo: json['titulo'],
      monto: (json['monto'] as num).toDouble(),
      categoria: json['categoria'],
      participanteId: json['participanteId'],
      fecha: DateTime.parse(json['fecha']),
      notas: json['notas'],
      recibo: json['recibo'],
    );
  }
}

/// Pantalla principal de Eventos Compartidos
class EventosCompartidosScreen extends StatefulWidget {
  final AppStrings strings;
  final AppCurrency currency;

  const EventosCompartidosScreen({
    Key? key,
    required this.strings,
    required this.currency,
  }) : super(key: key);

  @override
  State<EventosCompartidosScreen> createState() => _EventosCompartidosScreenState();
}

class _EventosCompartidosScreenState extends State<EventosCompartidosScreen> {
  List<EventoCompartido> _eventos = [];
  late SharedPreferences _prefs;
  bool _isPremium = false;
  static const int _maxEventosGratis = 5;

  @override
  void initState() {
    super.initState();
    _cargarEventos();
    _checkPremiumStatus();
  }
  
  Future<void> _checkPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPremium = prefs.getBool('is_premium') ?? false;
    });
  }

  Future<void> _cargarEventos() async {
    _prefs = await SharedPreferences.getInstance();
    final eventosJson = _prefs.getString('eventos_compartidos');
    if (eventosJson != null) {
      final List<dynamic> decoded = jsonDecode(eventosJson);
      setState(() {
        _eventos = decoded.map((e) => EventoCompartido.fromJson(e)).toList();
      });
    }
  }

  Future<void> _guardarEventos() async {
    final eventosJson = jsonEncode(_eventos.map((e) => e.toJson()).toList());
    await _prefs.setString('eventos_compartidos', eventosJson);
  }

  String _generarCodigoCompartir() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  void _crearNuevoEvento() {
    // Verificar límite de eventos para usuarios gratis
    if (!_isPremium && _eventos.length >= _maxEventosGratis) {
      _mostrarDialogoLimiteAlcanzado();
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => _DialogoNuevoEvento(
        onCrear: (evento) {
          setState(() {
            _eventos.add(evento);
          });
          _guardarEventos();
        },
        generarCodigo: _generarCodigoCompartir,
        strings: widget.strings,
      ),
    );
  }
  
  void _mostrarDialogoLimiteAlcanzado() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 28),
            SizedBox(width: 12),
            Text('Límite Alcanzado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Has llegado al límite de $_maxEventosGratis eventos compartidos gratuitos.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B), width: 2),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✨ Con Premium obtén:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('Eventos ilimitados')),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('Sin anuncios')),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('Backup en la nube')),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('Y mucho más...')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_offer, color: Color(0xFF22C55E), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🔥 50% de descuento por tiempo limitado',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tal vez después'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PremiumScreen(
                    strings: widget.strings,
                    source: 'eventos_limite',
                  ),
                ),
              );
              if (result == true) {
                await _checkPremiumStatus();
                if (_isPremium) {
                  _crearNuevoEvento();
                }
              }
            },
            icon: const Icon(Icons.workspace_premium),
            label: const Text('Ver Premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _verDetalleEvento(EventoCompartido evento) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleEventoScreen(
          evento: evento,
          strings: widget.strings,
          currency: widget.currency,
          onActualizado: () {
            _guardarEventos();
            setState(() {});
          },
        ),
      ),
    );
  }

  void _compartirEvento(EventoCompartido evento) {
    final texto = '''
🎉 ¡Únete a mi evento en Zentavo!

📋 ${evento.nombre}
💰 Presupuesto: ${widget.currency.formatAmount(evento.presupuesto)}
👥 Participantes: ${evento.participantes.length}

🔑 Código: ${evento.codigoCompartir}

Descarga Zentavo y únete usando este código.
''';

    Share.share(texto);
    
    // Mostrar diálogo con código
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share, color: Color(0xFF0EA5A4)),
            SizedBox(width: 8),
            Text('Compartir Evento'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Comparte este código con tus amigos:', 
              style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5A4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0EA5A4), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    evento.codigoCompartir,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Color(0xFF0EA5A4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: evento.codigoCompartir));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _unirseConCodigo() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.group_add, color: Color(0xFF0EA5A4)),
            SizedBox(width: 8),
            Text('Unirse a Evento'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el código del evento compartido:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Código',
                hintText: 'ABC123',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final codigo = controller.text.trim().toUpperCase();
              // TODO: Implementar lógica de unirse a evento compartido
              // Por ahora, mostrar mensaje
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Funcionalidad de sincronización en desarrollo.\nCódigo: $codigo'),
                ),
              );
            },
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Indicador de eventos usados (solo para usuarios gratis)
          if (!_isPremium)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _eventos.length >= _maxEventosGratis 
                    ? const Color(0xFFFEF2F2) 
                    : const Color(0xFFF0FDF4),
                border: Border(
                  bottom: BorderSide(
                    color: _eventos.length >= _maxEventosGratis 
                        ? const Color(0xFFEF4444) 
                        : const Color(0xFF22C55E),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _eventos.length >= _maxEventosGratis 
                        ? Icons.warning_amber_rounded 
                        : Icons.event_available,
                    color: _eventos.length >= _maxEventosGratis 
                        ? const Color(0xFFEF4444) 
                        : const Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _eventos.length >= _maxEventosGratis
                              ? 'Límite alcanzado'
                              : 'Eventos: ${_eventos.length}/$_maxEventosGratis (Gratis)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _eventos.length >= _maxEventosGratis 
                                ? const Color(0xFFEF4444) 
                                : const Color(0xFF22C55E),
                          ),
                        ),
                        if (_eventos.length < _maxEventosGratis)
                          Text(
                            'Puedes crear ${_maxEventosGratis - _eventos.length} más',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PremiumScreen(
                            strings: widget.strings,
                            source: 'eventos_banner',
                          ),
                        ),
                      );
                      if (result == true) {
                        _checkPremiumStatus();
                      }
                    },
                    icon: const Icon(Icons.workspace_premium, size: 18),
                    label: const Text('Premium'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),
          
          // Contenido principal
          Expanded(
            child: _eventos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay eventos compartidos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea un evento para viajes, juntadas\no eventos especiales',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (!_isPremium) ...[
                          const SizedBox(height: 16),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Versión gratuita: hasta $_maxEventosGratis eventos',
                                    style: const TextStyle(fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _crearNuevoEvento,
                          icon: const Icon(Icons.add),
                          label: const Text('Crear Evento'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5A4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _unirseConCodigo,
                          icon: const Icon(Icons.group_add),
                          label: const Text('Unirse con Código'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _eventos.length,
                    itemBuilder: (context, index) {
                      final evento = _eventos[index];
                      return _EventoCard(
                        evento: evento,
                        currency: widget.currency,
                        onTap: () => _verDetalleEvento(evento),
                        onCompartir: () => _compartirEvento(evento),
                        onEliminar: () {
                          setState(() {
                            _eventos.removeAt(index);
                          });
                          _guardarEventos();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'unirse',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0EA5A4),
            onPressed: _unirseConCodigo,
            child: const Icon(Icons.group_add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'crear',
            backgroundColor: const Color(0xFF0EA5A4),
            onPressed: _crearNuevoEvento,
            icon: const Icon(Icons.add),
            label: const Text('Crear Evento'),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar una tarjeta de evento
class _EventoCard extends StatelessWidget {
  final EventoCompartido evento;
  final AppCurrency currency;
  final VoidCallback onTap;
  final VoidCallback onCompartir;
  final VoidCallback onEliminar;

  const _EventoCard({
    Key? key,
    required this.evento,
    required this.currency,
    required this.onTap,
    required this.onCompartir,
    required this.onEliminar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF${evento.colorHex}', radix: 16));
    final porcentaje = evento.porcentajeGastado;
    final excedido = porcentaje > 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evento.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (evento.descripcion.isNotEmpty)
                          Text(
                            evento.descripcion,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'compartir') {
                        onCompartir();
                      } else if (value == 'eliminar') {
                        onEliminar();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'compartir',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 20),
                            SizedBox(width: 8),
                            Text('Compartir'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Presupuesto',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            currency.formatAmount(evento.presupuesto),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Gastado',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            currency.formatAmount(evento.totalGastado),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: excedido ? Colors.red : null,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Restante',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            currency.formatAmount(evento.saldoRestante),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: excedido ? Colors.red : const Color(0xFF22C55E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (porcentaje / 100).clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        excedido ? Colors.red : color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${evento.participantes.length} participantes',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        '${porcentaje.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: excedido ? Colors.red : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para crear un nuevo evento
class _DialogoNuevoEvento extends StatefulWidget {
  final Function(EventoCompartido) onCrear;
  final String Function() generarCodigo;
  final AppStrings strings;

  const _DialogoNuevoEvento({
    Key? key,
    required this.onCrear,
    required this.generarCodigo,
    required this.strings,
  }) : super(key: key);

  @override
  State<_DialogoNuevoEvento> createState() => _DialogoNuevoEventoState();
}

class _DialogoNuevoEventoState extends State<_DialogoNuevoEvento> {
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _presupuestoController = TextEditingController();
  final _nombreParticipanteController = TextEditingController();
  DateTime _fechaInicio = DateTime.now();
  DateTime? _fechaFin;
  List<Participante> _participantes = [];
  String _colorSeleccionado = '6366F1';

  final List<String> _colores = [
    '6366F1', // Indigo
    'EC4899', // Pink
    'F59E0B', // Amber
    '10B981', // Emerald
    '8B5CF6', // Violet
    'EF4444', // Red
    '3B82F6', // Blue
    '14B8A6', // Teal
  ];

  @override
  void initState() {
    super.initState();
    // Agregar "Yo" como primer participante
    _participantes.add(Participante(
      id: 'yo_${DateTime.now().millisecondsSinceEpoch}',
      nombre: 'Yo',
      esYo: true,
    ));
  }

  void _agregarParticipante() {
    if (_nombreParticipanteController.text.trim().isEmpty) return;

    setState(() {
      _participantes.add(Participante(
        id: 'part_${DateTime.now().millisecondsSinceEpoch}',
        nombre: _nombreParticipanteController.text.trim(),
      ));
      _nombreParticipanteController.clear();
    });
  }

  void _crearEvento() {
    if (_nombreController.text.trim().isEmpty || _presupuestoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos requeridos')),
      );
      return;
    }

    final evento = EventoCompartido(
      id: 'evento_${DateTime.now().millisecondsSinceEpoch}',
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      presupuesto: double.tryParse(_presupuestoController.text) ?? 0,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      participantes: _participantes,
      gastos: [],
      colorHex: _colorSeleccionado,
      codigoCompartir: widget.generarCodigo(),
    );

    // Incrementar contador de eventos
    SharedPreferences.getInstance().then((prefs) {
      final eventosCreados = prefs.getInt('eventos_creados') ?? 0;
      prefs.setInt('eventos_creados', eventosCreados + 1);
    });

    widget.onCrear(evento);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          children: [
            AppBar(
              title: const Text('Nuevo Evento'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del evento *',
                      hintText: 'Ej: Viaje a la playa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Opcional',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _presupuestoController,
                    decoration: const InputDecoration(
                      labelText: 'Presupuesto *',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text('Color del evento:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _colores.map((color) {
                      final isSelected = color == _colorSeleccionado;
                      return GestureDetector(
                        onTap: () => setState(() => _colorSeleccionado = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(int.parse('FF$color', radix: 16)),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Participantes:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ..._participantes.map((p) => Chip(
                        label: Text(p.nombre),
                        deleteIcon: p.esYo ? null : const Icon(Icons.close, size: 18),
                        onDeleted: p.esYo
                            ? null
                            : () => setState(() => _participantes.remove(p)),
                      )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nombreParticipanteController,
                          decoration: const InputDecoration(
                            hintText: 'Nombre del participante',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _agregarParticipante(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _agregarParticipante,
                        icon: const Icon(Icons.add_circle),
                        color: const Color(0xFF0EA5A4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _crearEvento,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5A4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Crear Evento', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla de detalle de un evento compartido
class DetalleEventoScreen extends StatefulWidget {
  final EventoCompartido evento;
  final AppStrings strings;
  final AppCurrency currency;
  final VoidCallback onActualizado;

  const DetalleEventoScreen({
    Key? key,
    required this.evento,
    required this.strings,
    required this.currency,
    required this.onActualizado,
  }) : super(key: key);

  @override
  State<DetalleEventoScreen> createState() => _DetalleEventoScreenState();
}

class _DetalleEventoScreenState extends State<DetalleEventoScreen> {
  final TextEditingController _nombreParticipanteController = TextEditingController();

  @override
  void dispose() {
    _nombreParticipanteController.dispose();
    super.dispose();
  }

  void _agregarGasto() {
    showDialog(
      context: context,
      builder: (context) => _DialogoNuevoGasto(
        evento: widget.evento,
        onAgregar: (gasto) {
          setState(() {
            widget.evento.gastos.add(gasto);
          });
          widget.onActualizado();
        },
      ),
    );
  }

  void _adjuntarPersona() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Color(0xFF0EA5A4)),
            SizedBox(width: 8),
            Text('Adjuntar Persona'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Agrega a alguien que participará en este evento',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreParticipanteController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre de la persona',
                hintText: 'Ej: María, Juan, etc.',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _confirmarAgregarParticipante(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nombreParticipanteController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: _confirmarAgregarParticipante,
            icon: const Icon(Icons.person_add),
            label: const Text('Agregar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5A4),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarAgregarParticipante() {
    if (_nombreParticipanteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un nombre'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Verificar que no exista ya un participante con ese nombre
    final nombreNuevo = _nombreParticipanteController.text.trim();
    final yaExiste = widget.evento.participantes.any(
      (p) => p.nombre.toLowerCase() == nombreNuevo.toLowerCase(),
    );

    if (yaExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe un participante con ese nombre'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      widget.evento.participantes.add(Participante(
        id: 'part_${DateTime.now().millisecondsSinceEpoch}',
        nombre: nombreNuevo,
      ));
    });
    widget.onActualizado();
    
    _nombreParticipanteController.clear();
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nombreNuevo se agregó al evento'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Map<String, double> _calcularGastosPorParticipante() {
    final Map<String, double> gastos = {};
    for (var participante in widget.evento.participantes) {
      gastos[participante.id] = 0;
    }
    for (var gasto in widget.evento.gastos) {
      gastos[gasto.participanteId] = (gastos[gasto.participanteId] ?? 0) + gasto.monto;
    }
    return gastos;
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF${widget.evento.colorHex}', radix: 16));
    final gastosPorParticipante = _calcularGastosPorParticipante();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.evento.nombre),
        backgroundColor: color,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Adjuntar persona',
            onPressed: _adjuntarPersona,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir evento',
            onPressed: () {
              final texto = '''
🎉 ${widget.evento.nombre}
💰 Presupuesto: ${widget.currency.formatAmount(widget.evento.presupuesto)}
💸 Gastado: ${widget.currency.formatAmount(widget.evento.totalGastado)}
🔑 Código: ${widget.evento.codigoCompartir}
''';
              Share.share(texto);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Resumen del presupuesto
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoChip(
                        label: 'Presupuesto',
                        valor: widget.currency.formatAmount(widget.evento.presupuesto),
                        icono: Icons.account_balance_wallet,
                        color: Colors.blue,
                      ),
                      _InfoChip(
                        label: 'Gastado',
                        valor: widget.currency.formatAmount(widget.evento.totalGastado),
                        icono: Icons.shopping_cart,
                        color: widget.evento.porcentajeGastado > 100 ? Colors.red : Colors.orange,
                      ),
                      _InfoChip(
                        label: 'Restante',
                        valor: widget.currency.formatAmount(widget.evento.saldoRestante),
                        icono: Icons.savings,
                        color: widget.evento.porcentajeGastado > 100 ? Colors.red : Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (widget.evento.porcentajeGastado / 100).clamp(0, 1),
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        widget.evento.porcentajeGastado > 100 ? Colors.red : color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.evento.porcentajeGastado.toStringAsFixed(1)}% del presupuesto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.evento.porcentajeGastado > 100 ? Colors.red : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Gastos por participante
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.people, color: Color(0xFF0EA5A4)),
                          SizedBox(width: 8),
                          Text(
                            'Gastos por Participante',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        'Mantén presionado para eliminar',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  ...widget.evento.participantes.map((participante) {
                    final gastoTotal = gastosPorParticipante[participante.id] ?? 0;
                    final tieneGastos = widget.evento.gastos.any((g) => g.participanteId == participante.id);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.2),
                        child: Text(
                          participante.nombre[0].toUpperCase(),
                          style: TextStyle(color: color, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(participante.nombre),
                          if (participante.esYo)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Tú',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        widget.currency.formatAmount(gastoTotal),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onLongPress: () {
                        if (tieneGastos) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se puede eliminar a un participante con gastos registrados'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        if (widget.evento.participantes.length <= 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Debe haber al menos un participante'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminar participante'),
                            content: Text('¿Deseas eliminar a ${participante.nombre} del evento?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    widget.evento.participantes.remove(participante);
                                  });
                                  widget.onActualizado();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${participante.nombre} eliminado del evento'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lista de gastos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gastos Registrados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${widget.evento.gastos.length}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.evento.gastos.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'No hay gastos registrados',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...widget.evento.gastos.reversed.map((gasto) {
              final participante = widget.evento.participantes
                  .firstWhere((p) => p.id == gasto.participanteId);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(
                      participante.nombre[0].toUpperCase(),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(gasto.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${participante.nombre} • ${gasto.categoria}\n${_formatearFecha(gasto.fecha)}',
                  ),
                  trailing: Text(
                    widget.currency.formatAmount(gasto.monto),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  isThreeLine: true,
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar gasto'),
                        content: const Text('¿Estás seguro de eliminar este gasto?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                widget.evento.gastos.remove(gasto);
                              });
                              widget.onActualizado();
                              Navigator.pop(context);
                            },
                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarGasto,
        backgroundColor: color,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Gasto'),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}

/// Widget para mostrar información en chips
class _InfoChip extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  final Color color;

  const _InfoChip({
    Key? key,
    required this.label,
    required this.valor,
    required this.icono,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icono, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

/// Diálogo para agregar un nuevo gasto
class _DialogoNuevoGasto extends StatefulWidget {
  final EventoCompartido evento;
  final Function(GastoCompartido) onAgregar;

  const _DialogoNuevoGasto({
    Key? key,
    required this.evento,
    required this.onAgregar,
  }) : super(key: key);

  @override
  State<_DialogoNuevoGasto> createState() => _DialogoNuevoGastoState();
}

class _DialogoNuevoGastoState extends State<_DialogoNuevoGasto> {
  final _tituloController = TextEditingController();
  final _montoController = TextEditingController();
  final _notasController = TextEditingController();
  late String _participanteSeleccionado;
  late String _categoriaSeleccionada;

  final List<String> _categorias = [
    'Comida',
    'Transporte',
    'Hospedaje',
    'Diversión',
    'Compras',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _participanteSeleccionado = widget.evento.participantes.first.id;
    _categoriaSeleccionada = _categorias.first;
  }

  void _agregarGasto() {
    if (_tituloController.text.trim().isEmpty || _montoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos requeridos')),
      );
      return;
    }

    final gasto = GastoCompartido(
      id: 'gasto_${DateTime.now().millisecondsSinceEpoch}',
      titulo: _tituloController.text.trim(),
      monto: double.tryParse(_montoController.text) ?? 0,
      categoria: _categoriaSeleccionada,
      participanteId: _participanteSeleccionado,
      fecha: DateTime.now(),
      notas: _notasController.text.trim(),
    );

    widget.onAgregar(gasto);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        child: Column(
          children: [
            AppBar(
              title: const Text('Nuevo Gasto'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      hintText: 'Ej: Cena restaurante',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _montoController,
                    decoration: const InputDecoration(
                      labelText: 'Monto *',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _categoriaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                    items: _categorias.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _categoriaSeleccionada = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _participanteSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Pagado por',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.evento.participantes.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(p.nombre),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _participanteSeleccionado = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notasController,
                    decoration: const InputDecoration(
                      labelText: 'Notas',
                      hintText: 'Opcional',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _agregarGasto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5A4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Agregar Gasto', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
