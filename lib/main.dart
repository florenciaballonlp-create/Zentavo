import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'export_utils.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(const ExpenseApp());

class ExpenseApp extends StatefulWidget {
  const ExpenseApp({super.key});

  @override
  State<ExpenseApp> createState() => _ExpenseAppState();
}

class _ExpenseAppState extends State<ExpenseApp> {
  late Future<ThemeMode> _themeModeFuture;

  @override
  void initState() {
    super.initState();
    _themeModeFuture = _loadThemeMode();
  }

  Future<ThemeMode> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode') ?? 'system';
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
    }
    await prefs.setString('themeMode', modeString);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeMode>(
      future: _themeModeFuture,
      builder: (context, snapshot) {
        final themeMode = snapshot.data ?? ThemeMode.system;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Control de Gastos',
          themeMode: themeMode,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF10B981),
            useMaterial3: true,
            brightness: Brightness.light,
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xFF10B981),
            useMaterial3: true,
            brightness: Brightness.dark,
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              color: const Color(0xFF1E1E1E),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          home: HomePage(onThemeModeChanged: _setThemeMode),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final Function(ThemeMode)? onThemeModeChanged;

  const HomePage({super.key, this.onThemeModeChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Lista de transacciones dinámica
  final List<Map<String, dynamic>> _transacciones = [];

  // Controladores para leer lo que escribes en el formulario
  final _tituloController = TextEditingController();
  final _montoController = TextEditingController();
  final _justificacionController = TextEditingController();
  late String _tipoSeleccionado;
  late String _categoriaSeleccionada;
  late SharedPreferences _prefs;
  String _exportDefault = 'ask'; // 'ask' or 'documents'
  
  // Control de mes seleccionado
  late DateTime _mesSeleccionado;

  // Mapa de categorías con iconos
  static const Map<String, String> _categorias = {
    'Comida': '🍔',
    'Transporte': '🚗',
    'Diversión': '🎮',
    'Salud': '🏥',
    'Servicios': '💡',
    'Utilidades': '📱',
    'Vivienda': '🏠',
    'Educación': '📚',
    'Otro': '❓',
  };

  @override
  void initState() {
    super.initState();
    _mesSeleccionado = DateTime(DateTime.now().year, DateTime.now().month);
    _cargarTransacciones();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _montoController.dispose();
    _justificacionController.dispose();
    super.dispose();
  }

  Future<void> _cargarTransacciones() async {
    _prefs = await SharedPreferences.getInstance();
    final String? datosGuardados = _prefs.getString('transacciones');
    _exportDefault = _prefs.getString('export_default') ?? 'ask';
    
    if (datosGuardados != null) {
      try {
        final List<dynamic> decoded = jsonDecode(datosGuardados);
        setState(() {
          _transacciones.clear();
          _transacciones.addAll(
            decoded.map((item) => Map<String, dynamic>.from(item)).toList(),
          );
        });
      } catch (e) {
        print('Error al cargar transacciones: $e');
      }
    }
  }

  Future<void> _setExportDefault(String value) async {
    _exportDefault = value;
    try {
      await _prefs.setString('export_default', value);
    } catch (e) {
      print('Error al guardar preferencia de exportación: $e');
    }
    setState(() {});
  }

  void _showExportPreferencesDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Preferencia de guardado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Preguntar carpeta (por defecto)'),
                value: 'ask',
                groupValue: _exportDefault,
                onChanged: (v) { if (v != null) { _setExportDefault(v); Navigator.of(context).pop(); } },
              ),
              RadioListTile<String>(
                title: const Text('Guardar en Documents automáticamente'),
                value: 'documents',
                groupValue: _exportDefault,
                onChanged: (v) { if (v != null) { _setExportDefault(v); Navigator.of(context).pop(); } },
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))],
        );
      },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Tema de la aplicación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Seguir configuración del sistema'),
                secondary: const Icon(Icons.brightness_auto),
                value: 'system',
                groupValue: 'system', // Se actualiza desde ExpenseApp
                onChanged: (v) {
                  Navigator.of(context).pop();
                  if (widget.onThemeModeChanged != null) {
                    widget.onThemeModeChanged!(ThemeMode.system);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Modo claro'),
                secondary: const Icon(Icons.light_mode),
                value: 'light',
                groupValue: 'light',
                onChanged: (v) {
                  Navigator.of(context).pop();
                  if (widget.onThemeModeChanged != null) {
                    widget.onThemeModeChanged!(ThemeMode.light);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Modo oscuro'),
                secondary: const Icon(Icons.dark_mode),
                value: 'dark',
                groupValue: 'dark',
                onChanged: (v) {
                  Navigator.of(context).pop();
                  if (widget.onThemeModeChanged != null) {
                    widget.onThemeModeChanged!(ThemeMode.dark);
                  }
                },
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))],
        );
      },
    );
  }

  Future<void> _guardarTransacciones() async {
    try {
      // Asegurarse de que _prefs está inicializado
      if (!_isPrefsInitialized()) {
        _prefs = await SharedPreferences.getInstance();
      }
      final String datosJSON = jsonEncode(_transacciones);
      await _prefs.setString('transacciones', datosJSON);
    } catch (e) {
      print('Error al guardar transacciones: $e');
    }
  }

  bool _isPrefsInitialized() {
    try {
      _prefs.containsKey('test');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtener transacciones filtradas por mes
  List<Map<String, dynamic>> _obtenerTransaccionesMes() {
    return _transacciones.where((t) {
      DateTime? fecha;
      if (t['fecha'] != null) {
        try {
          fecha = DateTime.parse(t['fecha']);
        } catch (e) {
          // Si no hay fecha válida, usar fecha actual
          fecha = DateTime.now();
        }
      } else {
        // Asignar fecha actual si no existe
        fecha = DateTime.now();
      }
      return fecha.year == _mesSeleccionado.year && fecha.month == _mesSeleccionado.month;
    }).toList();
  }

  // Obtener nombre del mes en español
  String _obtenerNombreMes(DateTime fecha) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  double _calcularIngresos() {
    return _obtenerTransaccionesMes()
        .where((t) => t['tipo'] == 'Ingreso')
        .fold(0, (sum, item) => sum + item['monto']);
  }

  double _calcularEgresos() {
    return _obtenerTransaccionesMes()
        .where((t) => t['tipo'] == 'Egreso')
        .fold(0, (sum, item) => sum + item['monto'].abs());
  }

  List<PieChartSectionData> _obtenerDatosGraficoMensual() {
    double ingresos = _calcularIngresos();
    double egresos = _calcularEgresos();
    double total = ingresos + egresos;

    if (total == 0) {
      return [
        PieChartSectionData(
          value: 100,
          color: Colors.grey[300],
          title: 'Sin datos',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ];
    }

    return [
      PieChartSectionData(
        value: ingresos,
        color: Colors.green,
        title: 'Ingresos\n\$${ingresos.toStringAsFixed(2)}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: egresos,
        color: Colors.red,
        title: 'Egresos\n\$${egresos.toStringAsFixed(2)}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
  }

  List<PieChartSectionData> _obtenerDatosGraficoAnual() {
    double ingresos = _calcularIngresos();
    double egresos = _calcularEgresos();
    double total = ingresos + egresos;

    if (total == 0) {
      return [
        PieChartSectionData(
          value: 100,
          color: Colors.grey[300],
          title: 'Sin datos',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ];
    }

    return [
      PieChartSectionData(
        value: ingresos,
        color: Colors.green,
        title: 'Ingresos\n\$${ingresos.toStringAsFixed(2)}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: egresos,
        color: Colors.red,
        title: 'Egresos\n\$${egresos.toStringAsFixed(2)}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
  }

  // Paleta de colores para categorías
  static const List<Color> _coloresCategorias = [
    Color(0xFFEF4444), // Rojo
    Color(0xFFFF9500), // Naranja
    Color(0xFFEAB308), // Amarillo
    Color(0xFF22C55E), // Verde
    Color(0xFF06B6D4), // Cian
    Color(0xFF3B82F6), // Azul
    Color(0xFF8B5CF6), // Púrpura
    Color(0xFFEC4899), // Rosa
    Color(0xFF6B7280), // Gris
  ];

  List<PieChartSectionData> _obtenerDatosEgresosPorCategoria() {
    // Agrupar egresos por categoría (del mes seleccionado)
    Map<String, double> egresosPorCategoria = {};
    for (var t in _obtenerTransaccionesMes()) {
      if (t['tipo'] == 'Egreso') {
        String cat = t['categoria'] ?? 'Otro';
        egresosPorCategoria[cat] = (egresosPorCategoria[cat] ?? 0) + (t['monto'].abs() as double);
      }
    }

    if (egresosPorCategoria.isEmpty) {
      return [
        PieChartSectionData(
          value: 100,
          color: Colors.grey[300],
          title: 'Sin gastos',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ];
    }

    int colorIndex = 0;
    return egresosPorCategoria.entries.map((entry) {
      final color = _coloresCategorias[colorIndex % _coloresCategorias.length];
      colorIndex++;
      final emoji = _categorias[entry.key] ?? '❓';
      return PieChartSectionData(
        value: entry.value,
        color: color,
        title: '${emoji}\n\$${entry.value.toStringAsFixed(2)}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  void _agregarNuevaTransaccion() {
    final nombre = _tituloController.text;
    final monto = double.tryParse(_montoController.text) ?? 0.0;
    final razon = _justificacionController.text;

    if (nombre.isEmpty || monto <= 0) return;

    setState(() {
      _transacciones.add({
        'titulo': nombre,
        'monto': _tipoSeleccionado == 'Ingreso' ? monto : -monto,
        'tipo': _tipoSeleccionado,
        'categoria': _categoriaSeleccionada,
        'justificacion': razon,
        'fecha': DateTime.now().toIso8601String(),
      });
    });

    // Guardar en SharedPreferences
    _guardarTransacciones();

    // Limpiar y cerrar
    _tituloController.clear();
    _montoController.clear();
    _justificacionController.clear();
    Navigator.of(context).pop();
  }

  void _mostrarFormulario(BuildContext ctx, String tipo) {
    // Compatibilidad: formulario simple para crear
    _mostrarFormularioConIndice(ctx, tipo);
  }

  // Mostrar formulario para crear o editar. Si index != null editamos.
  void _mostrarFormularioConIndice(BuildContext ctx, String tipo, {int? index}) {
    _tipoSeleccionado = tipo;
    _categoriaSeleccionada = 'Otro';
    if (index != null) {
      final existing = _transacciones[index];
      _tituloController.text = existing['titulo'] ?? '';
      // monto puede ser negativo para egresos
      _montoController.text = (existing['monto'] ?? 0).abs().toString();
      _justificacionController.text = existing['justificacion'] ?? '';
      _categoriaSeleccionada = existing['categoria'] ?? 'Otro';
    } else {
      _tituloController.clear();
      _montoController.clear();
      _justificacionController.clear();
      _tipoSeleccionado = tipo;
      _categoriaSeleccionada = 'Otro';
    }

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      index == null ? (tipo == 'Ingreso' ? 'Nuevo Ingreso' : 'Nuevo Egreso') : 'Editar Movimiento',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(controller: _tituloController, decoration: const InputDecoration(labelText: 'Título (ej. Sueldo, Alquiler)')),
                    const SizedBox(height: 12),
                    TextField(controller: _montoController, decoration: const InputDecoration(labelText: 'Monto \$'), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    // Mostrar categoría solo para egresos
                    if (tipo == 'Egreso')
                      DropdownButtonFormField<String>(
                        value: _categoriaSeleccionada,
                        decoration: const InputDecoration(labelText: 'Categoría'),
                        items: _categorias.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text('${entry.value} ${entry.key}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _categoriaSeleccionada = value ?? 'Otro';
                          });
                        },
                      ),
                    if (tipo == 'Egreso') const SizedBox(height: 12),
                    TextField(controller: _justificacionController, decoration: const InputDecoration(labelText: 'Justificación')),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () { Navigator.of(context).pop(); }, child: const Text('Cancelar')),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (index == null) {
                              _agregarNuevaTransaccion();
                            } else {
                              _guardarEdicion(index);
                            }
                          },
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _guardarEdicion(int index) {
    final nombre = _tituloController.text;
    final monto = double.tryParse(_montoController.text) ?? 0.0;
    final razon = _justificacionController.text;

    if (nombre.isEmpty || monto <= 0) return;

    setState(() {
      _transacciones[index] = {
        'titulo': nombre,
        'monto': _tipoSeleccionado == 'Ingreso' ? monto : -monto,
        'tipo': _tipoSeleccionado,
        'categoria': _categoriaSeleccionada,
        'justificacion': razon,
        'fecha': _transacciones[index]['fecha'] ?? DateTime.now().toIso8601String(),
      };
    });

    _guardarTransacciones();

    _tituloController.clear();
    _montoController.clear();
    _justificacionController.clear();
    Navigator.of(context).pop();
  }

  // Exportación: JSON, CSV, Texto simple
  String _exportToJsonString() => exportToJson(_transacciones);
  String _exportToCsvString() => exportToCsv(_transacciones);
  String _exportToTextString() => exportToText(_transacciones);

  void _showExportDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: SelectableText(content)),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: content));
                Navigator.of(context).pop();
              },
              child: const Text('Copiar'),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
          ],
        );
      },
    );
  }

  Future<void> _exportAndShare(String format) async {
    String content;
    String ext;
    if (format == 'json') {
      content = _exportToJsonString();
      ext = 'json';
    } else if (format == 'csv') {
      content = _exportToCsvString();
      ext = 'csv';
    } else {
      content = _exportToTextString();
      ext = 'txt';
    }

    try {
      final dir = await getTemporaryDirectory();
      final filePath = p.join(dir.path, 'control_gastos_export.$ext');
      final file = File(filePath);
      await file.writeAsString(content);

      // Usar share_plus para compartir el archivo
      final xfile = XFile(file.path);
      await Share.shareXFiles([xfile], text: 'Exportación $ext de Control de Gastos');
    } catch (e) {
      print('Error al exportar y compartir: $e');
    }
  }

  Future<void> _exportToFolder(String format) async {
    String content;
    String ext;
    if (format == 'json') {
      content = _exportToJsonString();
      ext = 'json';
    } else if (format == 'csv') {
      content = _exportToCsvString();
      ext = 'csv';
    } else {
      content = _exportToTextString();
      ext = 'txt';
    }

    try {
      final directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null) return; // usuario canceló

      final fileName = 'control_gastos_export_${DateTime.now().toIso8601String().replaceAll(':', '-')}.${ext}';
      final filePath = p.join(directoryPath, fileName);
      final file = File(filePath);
      await file.writeAsString(content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo guardado: $fileName')),
        );
      }
    } catch (e) {
      print('Error al guardar en carpeta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el archivo')),
        );
      }
    }
  }

  Future<void> _exportToDocuments(String format) async {
    String content;
    String ext;
    if (format == 'json') {
      content = _exportToJsonString();
      ext = 'json';
    } else if (format == 'csv') {
      content = _exportToCsvString();
      ext = 'csv';
    } else {
      content = _exportToTextString();
      ext = 'txt';
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'control_gastos_export_${DateTime.now().toIso8601String().replaceAll(':', '-')}.${ext}';
      final filePath = p.join(dir.path, fileName);
      final file = File(filePath);
      await file.writeAsString(content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo guardado en Documents: $fileName')),
        );
      }
    } catch (e) {
      print('Error al guardar en Documents: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el archivo en Documents')),
        );
      }
    }
  }

  void _showSaveAsDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Guardar en:'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Carpeta elegida'),
                subtitle: const Text('JSON'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showSaveFormatDialog('folder');
                },
              ),
              ListTile(
                title: const Text('Documents'),
                subtitle: const Text('JSON'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showSaveFormatDialog('documents');
                },
              ),
              ListTile(
                title: const Text('Usar preferencia'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showSaveFormatDialog('default');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSaveFormatDialog(String saveType) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Formato:'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('JSON'),
                onTap: () async {
                  Navigator.of(context).pop();
                  if (saveType == 'folder') {
                    await _exportToFolder('json');
                  } else if (saveType == 'documents') {
                    await _exportToDocuments('json');
                  } else {
                    if (_exportDefault == 'documents') {
                      await _exportToDocuments('json');
                    } else {
                      await _exportToFolder('json');
                    }
                  }
                },
              ),
              ListTile(
                title: const Text('CSV'),
                onTap: () async {
                  Navigator.of(context).pop();
                  if (saveType == 'folder') {
                    await _exportToFolder('csv');
                  } else if (saveType == 'documents') {
                    await _exportToDocuments('csv');
                  } else {
                    if (_exportDefault == 'documents') {
                      await _exportToDocuments('csv');
                    } else {
                      await _exportToFolder('csv');
                    }
                  }
                },
              ),
              ListTile(
                title: const Text('TXT'),
                onTap: () async {
                  Navigator.of(context).pop();
                  if (saveType == 'folder') {
                    await _exportToFolder('txt');
                  } else if (saveType == 'documents') {
                    await _exportToDocuments('txt');
                  } else {
                    if (_exportDefault == 'documents') {
                      await _exportToDocuments('txt');
                    } else {
                      await _exportToFolder('txt');
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDownloadDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Descargar como:'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('JSON'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showExportDialog('Descargar JSON', _exportToJsonString());
                },
              ),
              ListTile(
                title: const Text('CSV'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showExportDialog('Descargar CSV', _exportToCsvString());
                },
              ),
              ListTile(
                title: const Text('TXT'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showExportDialog('Descargar TXT', _exportToTextString());
                },
              ),
              ListTile(
                title: const Text('PDF'),
                onTap: () {
                  Navigator.of(context).pop();
                  _downloadPdf();
                },
              ),
              ListTile(
                title: const Text('Excel'),
                onTap: () {
                  Navigator.of(context).pop();
                  _downloadExcel();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExportFormatDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Exportar como:'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('JSON'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showExportDialog('Exportar JSON', _exportToJsonString());
                },
              ),
              ListTile(
                title: const Text('CSV'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showExportDialog('Exportar CSV', _exportToCsvString());
                },
              ),
              ListTile(
                title: const Text('TXT'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showExportDialog('Exportar TXT', _exportToTextString());
                },
              ),
              ListTile(
                title: const Text('PDF'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showExportPdfDialog();
                },
              ),
              ListTile(
                title: const Text('Excel'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showExportExcelDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadPdf() async {
    try {
      final pdfData = await exportToPdf(_transacciones);
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'control_gastos_${DateTime.now().toIso8601String().replaceAll(':', '-')}.pdf';
      final filePath = p.join(dir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(pdfData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF descargado: $fileName')),
        );
      }
    } catch (e) {
      print('Error al descargar PDF: $e');
    }
  }

  Future<void> _downloadExcel() async {
    try {
      final excelData = await exportToExcel(_transacciones);
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'control_gastos_${DateTime.now().toIso8601String().replaceAll(':', '-')}.xlsx';
      final filePath = p.join(dir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(excelData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel descargado: $fileName')),
        );
      }
    } catch (e) {
      print('Error al descargar Excel: $e');
    }
  }

  Future<void> _showExportPdfDialog() async {
    try {
      final pdfData = await exportToPdf(_transacciones);
      final dir = await getTemporaryDirectory();
      final filePath = p.join(dir.path, 'control_gastos.pdf');
      final file = File(filePath);
      await file.writeAsBytes(pdfData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generado')),
        );
      }
    } catch (e) {
      print('Error al generar PDF: $e');
    }
  }

  Future<void> _showExportExcelDialog() async {
    try {
      final excelData = await exportToExcel(_transacciones);
      final dir = await getTemporaryDirectory();
      final filePath = p.join(dir.path, 'control_gastos.xlsx');
      final file = File(filePath);
      await file.writeAsBytes(excelData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel generado')),
        );
      }
    } catch (e) {
      print('Error al generar Excel: $e');
    }
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Compartir PDF mediante:'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('WhatsApp'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _sharePdfVia('whatsapp');
                },
              ),
              ListTile(
                title: const Text('Email'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _sharePdfVia('email');
                },
              ),
              ListTile(
                title: const Text('Telegram'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _sharePdfVia('telegram');
                },
              ),
              ListTile(
                title: const Text('Más opciones'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _sharePdfVia('share');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sharePdfVia(String method) async {
    try {
      final pdfData = await exportToPdf(_transacciones);
      final dir = await getTemporaryDirectory();
      final filePath = p.join(dir.path, 'control_gastos.pdf');
      final file = File(filePath);
      await file.writeAsBytes(pdfData);

      final xfile = XFile(file.path);

      if (method == 'share') {
        await Share.shareXFiles([xfile], text: 'Exportación Control de Gastos');
      } else {
        // Para métodos específicos, Share.shareXFiles ya intenta abrirlos con la app correspondiente
        await Share.shareXFiles([xfile], text: 'Exportación Control de Gastos');
      }
    } catch (e) {
      print('Error al compartir PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double ingresos = _calcularIngresos();
    double egresos = _calcularEgresos();
    double balance = ingresos - egresos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Control de Gastos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        centerTitle: true,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'exportar') {
                _showExportFormatDialog();
              } else if (value == 'guardar') {
                _showSaveAsDialog();
              } else if (value == 'descargar') {
                _showDownloadDialog();
              } else if (value == 'compartir') {
                _showShareDialog();
              } else if (value == 'prefs') {
                _showExportPreferencesDialog();
              } else if (value == 'tema') {
                _showThemeDialog();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'exportar', child: Text('Exportar')),
              const PopupMenuItem(value: 'guardar', child: Text('Guardar como')),
              const PopupMenuItem(value: 'descargar', child: Text('Descargar')),
              const PopupMenuItem(value: 'compartir', child: Text('Compartir')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'prefs', child: Text('Preferencias')),
              const PopupMenuItem(value: 'tema', child: Text('Tema')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Tarjetas de ingresos y egresos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  // Tarjeta de Ingresos
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: const Color(0xFFECFDF5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFF10B981), width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.trending_up, color: Color(0xFF10B981), size: 28),
                                SizedBox(width: 12),
                                Text('Ingresos', style: TextStyle(fontSize: 16, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('\$${ingresos.toStringAsFixed(2)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tarjeta de Egresos
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: const Color(0xFFFEF2F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.trending_down, color: Color(0xFFEF4444), size: 28),
                                SizedBox(width: 12),
                                Text('Egresos', style: TextStyle(fontSize: 16, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('\$${egresos.toStringAsFixed(2)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Resumen de balance
            Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: balance >= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Balance Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
                    Text('\$${balance.toStringAsFixed(2)}', 
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
                  ],
                ),
              ),
            ),
            // Botón de gráficos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.pie_chart, size: 24),
                  label: const Text('Ver Gráficos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChartsPage(
                        transacciones: _transacciones,
                        obtenerDatosGraficoMensual: _obtenerDatosGraficoMensual,
                        obtenerDatosGraficoAnual: _obtenerDatosGraficoAnual,
                        obtenerDatosEgresosPorCategoria: _obtenerDatosEgresosPorCategoria,
                      ),
                    ));
                  },
                ),
              ),
            ),
            // Botones de reportes mensuales
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      label: const Text('Reporte PDF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        try {
                          final transaccionesMes = _obtenerTransaccionesMes();
                          final pdfBytes = await exportMonthlyReportPdf(
                            month: _mesSeleccionado,
                            transactions: transaccionesMes,
                            ingresos: _calcularIngresos(),
                            egresos: _calcularEgresos(),
                          );
                          
                          final dir = await getTemporaryDirectory();
                          final monthStr = '${_mesSeleccionado.month.toString().padLeft(2, '0')}-${_mesSeleccionado.year}';
                          final filePath = p.join(dir.path, 'Reporte_$monthStr.pdf');
                          final file = File(filePath);
                          await file.writeAsBytes(pdfBytes);
                          
                          await Share.shareXFiles([XFile(file.path)], text: 'Reporte Mensual $monthStr');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reporte PDF generado y compartido')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al generar PDF: $e')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.table_chart, size: 20),
                      label: const Text('Reporte Excel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        try {
                          final transaccionesMes = _obtenerTransaccionesMes();
                          final excelBytes = await exportMonthlyReportExcel(
                            month: _mesSeleccionado,
                            transactions: transaccionesMes,
                            ingresos: _calcularIngresos(),
                            egresos: _calcularEgresos(),
                          );
                          
                          final dir = await getTemporaryDirectory();
                          final monthStr = '${_mesSeleccionado.month.toString().padLeft(2, '0')}-${_mesSeleccionado.year}';
                          final filePath = p.join(dir.path, 'Reporte_$monthStr.xlsx');
                          final file = File(filePath);
                          await file.writeAsBytes(excelBytes);
                          
                          await Share.shareXFiles([XFile(file.path)], text: 'Reporte Mensual $monthStr');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reporte Excel generado y compartido')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al generar Excel: $e')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Selector de mes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: () {
                      setState(() {
                        _mesSeleccionado = DateTime(_mesSeleccionado.year, _mesSeleccionado.month - 1);
                      });
                    },
                  ),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _mesSeleccionado,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _mesSeleccionado = DateTime(pickedDate.year, pickedDate.month);
                        });
                      }
                    },
                    child: Text(
                      _obtenerNombreMes(_mesSeleccionado),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    onPressed: () {
                      setState(() {
                        _mesSeleccionado = DateTime(_mesSeleccionado.year, _mesSeleccionado.month + 1);
                      });
                    },
                  ),
                ],
              ),
            ),
            // Lista de movimientos
            _obtenerTransaccionesMes().isEmpty 
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No hay movimientos en este mes. ¡Usa el botón +!'),
                )
              : SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: _obtenerTransaccionesMes().length,
                    itemBuilder: (ctx, i) {
                      final transaccionesMes = _obtenerTransaccionesMes();
                      final t = transaccionesMes[i];
                      // Encontrar el índice en la lista original
                      final indexOriginal = _transacciones.indexOf(t);
                      return Dismissible(
                        key: Key('transaccion_${indexOriginal}_$i'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white, size: 30),
                        ),
                        onDismissed: (direction) {
                          setState(() {
                            _transacciones.removeAt(indexOriginal);
                          });
                          _guardarTransacciones();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Movimiento eliminado')),
                          );
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: t['tipo'] == 'Ingreso' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            child: Text(
                              _categorias[t['categoria']] ?? '❓',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(t['titulo'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${t['categoria']} • ${t['justificacion']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('\$${t['monto']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              IconButton(
                                icon: const Icon(Icons.share, size: 20),
                                onPressed: () async {
                                  try {
                                    // Compartir solo este movimiento como texto
                                    final content = exportToText([t]);
                                    final dir = await getTemporaryDirectory();
                                    final filePath = p.join(dir.path, 'mov_${i + 1}.txt');
                                    final file = File(filePath);
                                    await file.writeAsString(content);
                                    final xfile = XFile(file.path);
                                    await Share.shareXFiles([xfile], text: 'Movimiento ${i + 1}');
                                  } catch (e) {
                                    print('Error compartiendo movimiento: $e');
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () {
                                  // Confirmar eliminación
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Eliminar movimiento'),
                                      content: Text('¿Estás seguro de que deseas eliminar "${t['titulo']}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _transacciones.removeAt(indexOriginal);
                                            });
                                            _guardarTransacciones();
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Movimiento eliminado')),
                                            );
                                          },
                                          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () => _mostrarFormularioConIndice(context, t['tipo'], index: i),
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'ingreso',
            backgroundColor: const Color(0xFF10B981),
            onPressed: () => _mostrarFormulario(context, 'Ingreso'),
            icon: const Icon(Icons.add),
            label: const Text('Ingreso', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'egreso',
            backgroundColor: const Color(0xFFEF4444),
            onPressed: () => _mostrarFormulario(context, 'Egreso'),
            icon: const Icon(Icons.remove),
            label: const Text('Egreso', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// Página separada para los gráficos
class ChartsPage extends StatelessWidget {
  final List<Map<String, dynamic>> transacciones;
  final Function obtenerDatosGraficoMensual;
  final Function obtenerDatosGraficoAnual;
  final Function obtenerDatosEgresosPorCategoria;

  const ChartsPage({
    required this.transacciones,
    required this.obtenerDatosGraficoMensual,
    required this.obtenerDatosGraficoAnual,
    required this.obtenerDatosEgresosPorCategoria,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Gráficos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gráfico de distribución mensual
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Distribución Mensual',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: obtenerDatosGraficoMensual(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Gráfico de distribución anual
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📈 Distribución Anual',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: obtenerDatosGraficoAnual(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Gráfico de egresos por categoría
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💰 Egresos por Categoría',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: obtenerDatosEgresosPorCategoria(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
