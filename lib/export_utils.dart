import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

// Utilidades de exportación reutilizables
String exportToJson(List<Map<String, dynamic>> items) {
  return jsonEncode(items);
}

String exportToCsv(List<Map<String, dynamic>> items) {
  final sb = StringBuffer();
  sb.writeln('titulo,monto,tipo,categoria,justificacion');
  for (final t in items) {
    final titulo = (t['titulo'] ?? '').toString().replaceAll('"', '""');
    final cat = (t['categoria'] ?? 'Otro').toString().replaceAll('"', '""');
    final just = (t['justificacion'] ?? '').toString().replaceAll('"', '""');
    sb.writeln('"$titulo",${t['monto']},${t['tipo']},"$cat","$just"');
  }
  return sb.toString();
}

String exportToText(List<Map<String, dynamic>> items) {
  final sb = StringBuffer();
  for (var i = 0; i < items.length; i++) {
    final t = items[i];
    final cat = t['categoria'] ?? 'Otro';
    sb.writeln('${i + 1}. ${t['titulo']} — ${t['tipo']} — $cat — \$${t['monto']} — ${t['justificacion']}');
  }
  return sb.toString();
}

Future<List<int>> exportToPdf(List<Map<String, dynamic>> items) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Control de Gastos', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Text('Título', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Monto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Tipo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Justificación', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                for (final t in items)
                  pw.TableRow(
                    children: [
                      pw.Text(t['titulo'] ?? ''),
                      pw.Text('\$${t['monto']}'),
                      pw.Text(t['tipo'] ?? ''),
                      pw.Text(t['justificacion'] ?? ''),
                    ],
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

Future<List<int>> exportToExcel(List<Map<String, dynamic>> items) async {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];

  // Encabezados
  sheet.appendRow(['Título', 'Monto', 'Tipo', 'Justificación']);

  // Datos
  for (final t in items) {
    sheet.appendRow([
      t['titulo'] ?? '',
      t['monto'],
      t['tipo'] ?? '',
      t['justificacion'] ?? '',
    ]);
  }

  return excel.encode() ?? [];
}
