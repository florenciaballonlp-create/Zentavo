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

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Control de Gastos',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
  late SharedPreferences _prefs;
  String _exportDefault = 'ask'; // 'ask' or 'documents'

  @override
  void initState() {
    super.initState();
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

  double _calcularIngresos() {
    return _transacciones
        .where((t) => t['tipo'] == 'Ingreso')
        .fold(0, (sum, item) => sum + item['monto']);
  }

  double _calcularEgresos() {
    return _transacciones
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
        'justificacion': razon,
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
    if (index != null) {
      final existing = _transacciones[index];
      _tituloController.text = existing['titulo'] ?? '';
      // monto puede ser negativo para egresos
      _montoController.text = (existing['monto'] ?? 0).abs().toString();
      _justificacionController.text = existing['justificacion'] ?? '';
    } else {
      _tituloController.clear();
      _montoController.clear();
      _justificacionController.clear();
      _tipoSeleccionado = tipo;
    }

    showModalBottomSheet(
      context: ctx,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                index == null ? (tipo == 'Ingreso' ? 'Nuevo Ingreso' : 'Nuevo Egreso') : 'Editar Movimiento',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(controller: _tituloController, decoration: const InputDecoration(labelText: 'Título (ej. Sueldo, Alquiler)')),
              TextField(controller: _montoController, decoration: const InputDecoration(labelText: 'Monto \$'), keyboardType: TextInputType.number),
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
        'justificacion': razon,
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
        title: const Text('Control de Gastos'),
        centerTitle: true,
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
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'exportar', child: Text('Exportar')),
              const PopupMenuItem(value: 'guardar', child: Text('Guardar como')),
              const PopupMenuItem(value: 'descargar', child: Text('Descargar')),
              const PopupMenuItem(value: 'compartir', child: Text('Compartir')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'prefs', child: Text('Preferencias')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Tarjetas de ingresos y egresos
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Tarjeta de Ingresos
                  Expanded(
                    child: Card(
                      elevation: 4,
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.add_circle, color: Colors.green, size: 24),
                                SizedBox(width: 8),
                                Text('Ingresos', style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('\$${ingresos.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tarjeta de Egresos
                  Expanded(
                    child: Card(
                      elevation: 4,
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.remove_circle, color: Colors.red, size: 24),
                                SizedBox(width: 8),
                                Text('Egresos', style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('\$${egresos.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
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
              elevation: 4,
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Balance:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('\$${balance.toStringAsFixed(2)}', 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: balance >= 0 ? Colors.green : Colors.red)),
                  ],
                ),
              ),
            ),
            // Gráfico de torta
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Distribución Mensual',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _obtenerDatosGraficoMensual(),
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
            // Gráfico de torta anual
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Distribución Anual',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _obtenerDatosGraficoAnual(),
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
            // Lista de movimientos
            _transacciones.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No hay movimientos aún. ¡Usa el botón +!'),
                )
              : SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: _transacciones.length,
                    itemBuilder: (ctx, i) {
                      final t = _transacciones[i];
                      return Dismissible(
                        key: Key('transaccion_$i'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white, size: 30),
                        ),
                        onDismissed: (direction) {
                          setState(() {
                            _transacciones.removeAt(i);
                          });
                          _guardarTransacciones();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Movimiento eliminado')),
                          );
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: t['tipo'] == 'Ingreso' ? Colors.green : Colors.red,
                            child: Icon(t['tipo'] == 'Ingreso' ? Icons.add : Icons.remove, color: Colors.white),
                          ),
                          title: Text(t['titulo'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(t['justificacion']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('\$${t['monto']}', style: const TextStyle(fontSize: 16)),
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
          FloatingActionButton(
            heroTag: 'ingreso',
            backgroundColor: Colors.green,
            onPressed: () => _mostrarFormulario(context, 'Ingreso'),
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'egreso',
            backgroundColor: Colors.red,
            onPressed: () => _mostrarFormulario(context, 'Egreso'),
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
