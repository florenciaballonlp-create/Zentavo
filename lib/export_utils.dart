import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

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
            pw.Text('Zentavo', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
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

// Funciones para informes mensuales
Future<List<int>> exportMonthlyReportPdf({
  required DateTime month,
  required List<Map<String, dynamic>> transactions,
  required double ingresos,
  required double egresos,
}) async {
  final pdf = pw.Document();
  final monthName = _getSpanishMonthName(month.month);
  final dateFormatter = DateFormat('dd/MM/yyyy');
  
  // Separar transacciones por tipo
  final ingresosList = transactions.where((t) => t['tipo'] == 'Ingreso').toList();
  final egresosList = transactions.where((t) => t['tipo'] == 'Egreso').toList();
  
  // Agrupar egresos por categoría
  final Map<String, double> egreosPorCategoria = {};
  for (final egreso in egresosList) {
    final cat = egreso['categoria'] ?? 'Otro';
    egreosPorCategoria[cat] = (egreosPorCategoria[cat] ?? 0) + (egreso['monto'] as num).toDouble();
  }

  pdf.addPage(
    pw.MultiPage(
      build: (pw.Context context) {
        return [
          // Encabezado
          pw.Text('INFORME MENSUAL - ZENTAVO', 
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text('$monthName ${month.year}',
            style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
          pw.SizedBox(height: 20),
          
          // Resumen
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              color: PdfColors.grey100,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('RESUMEN DEL MES', 
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('Total Ingresos',
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                        pw.Text('\$${ingresos.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Total Egresos',
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                        pw.Text('\$${egresos.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Balance',
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                        pw.Text('\$${(ingresos - egresos).toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 14, 
                            fontWeight: pw.FontWeight.bold,
                            color: (ingresos - egresos) >= 0 ? PdfColors.green : PdfColors.red,
                          )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Distribución de Egresos por Categoría
          if (egreosPorCategoria.isNotEmpty) ...[
            pw.Text('DISTRIBUCIÓN DE EGRESOS POR CATEGORÍA',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Categoría', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Monto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Porcentaje', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                for (final entry in egreosPorCategoria.entries)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(entry.key, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('\$${entry.value.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('${((entry.value / egresos) * 100).toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Detalle de Ingresos
          if (ingresosList.isNotEmpty) ...[
            pw.Text('INGRESOS',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Descripción', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Monto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Fecha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                  ],
                ),
                for (final t in ingresosList)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(t['titulo'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('\$${t['monto']}', style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          t['fecha'] != null ? dateFormatter.format(DateTime.parse(t['fecha'])) : 'N/A',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Detalle de Egresos
          if (egresosList.isNotEmpty) ...[
            pw.Text('EGRESOS',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Descripción', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Categoría', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Monto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Fecha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                  ],
                ),
                for (final t in egresosList)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(t['titulo'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(t['categoria'] ?? 'Otro', style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('\$${t['monto']}', style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          t['fecha'] != null ? dateFormatter.format(DateTime.parse(t['fecha'])) : 'N/A',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ];
      },
    ),
  );

  return pdf.save();
}

Future<List<int>> exportMonthlyReportExcel({
  required DateTime month,
  required List<Map<String, dynamic>> transactions,
  required double ingresos,
  required double egresos,
}) async {
  final excel = Excel.createExcel();
  
  // Hoja 1: Resumen
  final summarySheet = excel['Resumen'];
  final monthName = _getSpanishMonthName(month.month);
  
  summarySheet.appendRow(['INFORME MENSUAL - ZENTAVO']);
  summarySheet.appendRow(['$monthName ${month.year}']);
  summarySheet.appendRow([]);
  summarySheet.appendRow(['RESUMEN DEL MES']);
  summarySheet.appendRow(['Concepto', 'Monto']);
  summarySheet.appendRow(['Total Ingresos', ingresos]);
  summarySheet.appendRow(['Total Egresos', egresos]);
  summarySheet.appendRow(['Balance', ingresos - egresos]);
  
  // Hoja 2: Egresos por categoría
  final egresosList = transactions.where((t) => t['tipo'] == 'Egreso').toList();
  final Map<String, double> egreosPorCategoria = {};
  for (final egreso in egresosList) {
    final cat = egreso['categoria'] ?? 'Otro';
    egreosPorCategoria[cat] = (egreosPorCategoria[cat] ?? 0) + (egreso['monto'] as num).toDouble();
  }
  
  if (egreosPorCategoria.isNotEmpty) {
    final categorySheet = excel['Categorías'];
    categorySheet.appendRow(['Distribución de Egresos por Categoría']);
    categorySheet.appendRow(['Categoría', 'Monto', 'Porcentaje']);
    for (final entry in egreosPorCategoria.entries) {
      categorySheet.appendRow([
        entry.key,
        entry.value,
        '${((entry.value / egresos) * 100).toStringAsFixed(1)}%',
      ]);
    }
  }
  
  // Hoja 3: Ingresos
  final ingresosList = transactions.where((t) => t['tipo'] == 'Ingreso').toList();
  if (ingresosList.isNotEmpty) {
    final incomesSheet = excel['Ingresos'];
    incomesSheet.appendRow(['Descripción', 'Monto', 'Fecha', 'Observación']);
    for (final t in ingresosList) {
      final fecha = t['fecha'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(t['fecha'])) : 'N/A';
      incomesSheet.appendRow([
        t['titulo'] ?? '',
        t['monto'],
        fecha,
        t['justificacion'] ?? '',
      ]);
    }
  }
  
  // Hoja 4: Egresos
  if (egresosList.isNotEmpty) {
    final expensesSheet = excel['Egresos'];
    expensesSheet.appendRow(['Descripción', 'Categoría', 'Monto', 'Fecha', 'Observación']);
    for (final t in egresosList) {
      final fecha = t['fecha'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(t['fecha'])) : 'N/A';
      expensesSheet.appendRow([
        t['titulo'] ?? '',
        t['categoria'] ?? 'Otro',
        t['monto'],
        fecha,
        t['justificacion'] ?? '',
      ]);
    }
  }
  
  excel.delete('Sheet1');
  return excel.encode() ?? [];
}

String _getSpanishMonthName(int month) {
  const months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];
  return months[month - 1];
}
