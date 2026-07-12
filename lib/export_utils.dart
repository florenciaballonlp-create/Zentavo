import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'localization.dart';

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
  AppLanguage language = AppLanguage.spanish,
}) async {
  final pdf = pw.Document();
  final monthName = _getMonthName(month.month, language);
  final dateFormatter = DateFormat('dd/MM/yyyy');
  
  // Separar transacciones por tipo
  final ingresosList = transactions.where((t) => t['tipo'] == 'Ingreso').toList();
  final egresosList = transactions.where((t) => t['tipo'] == 'Egreso').toList();
  
  // Agrupar egresos por categoría
  final Map<String, double> egreosPorCategoria = {};
  for (final egreso in egresosList) {
    final cat = egreso['categoria'] ?? _tr(language, es: 'Otro', en: 'Other', pt: 'Outro', it: 'Altro');
    egreosPorCategoria[cat] = (egreosPorCategoria[cat] ?? 0) + (egreso['monto'] as num).toDouble();
  }

  pdf.addPage(
    pw.MultiPage(
      build: (pw.Context context) {
        return [
          // Encabezado
          pw.Text(_tr(language, es: 'INFORME MENSUAL - ZENTAVO', en: 'MONTHLY REPORT - ZENTAVO', pt: 'RELATÓRIO MENSAL - ZENTAVO', it: 'REPORT MENSILE - ZENTAVO'), 
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
                pw.Text(
                  _tr(
                    language,
                    es: 'RESUMEN MENSUAL',
                    en: 'MONTHLY SUMMARY',
                    pt: 'RESUMO MENSAL',
                    it: 'RIEPILOGO MENSILE',
                  ),
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          _tr(language, es: 'Total Ingresos', en: 'Total Income', pt: 'Total Receitas', it: 'Totale Entrate'),
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          '\$${ingresos.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          _tr(language, es: 'Total Egresos', en: 'Total Expenses', pt: 'Total Despesas', it: 'Totale Spese'),
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          '\$${egresos.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          _tr(language, es: 'Balance', en: 'Balance', pt: 'Saldo', it: 'Saldo'),
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          '\$${(ingresos - egresos).toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: (ingresos - egresos) >= 0 ? PdfColors.green : PdfColors.red,
                          ),
                        ),
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
            pw.Text(_tr(language, es: 'DISTRIBUCIÓN DE EGRESOS POR CATEGORÍA', en: 'EXPENSE DISTRIBUTION BY CATEGORY', pt: 'DISTRIBUIÇÃO DE DESPESAS POR CATEGORIA', it: 'DISTRIBUZIONE DELLE SPESE PER CATEGORIA'),
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
                      child: pw.Text(_tr(language, es: 'Categoría', en: 'Category', pt: 'Categoria', it: 'Categoria'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_tr(language, es: 'Monto', en: 'Amount', pt: 'Valor', it: 'Importo'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_tr(language, es: 'Porcentaje', en: 'Percentage', pt: 'Percentual', it: 'Percentuale'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
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
            pw.Text(_tr(language, es: 'INGRESOS', en: 'INCOME', pt: 'RECEITAS', it: 'ENTRATE'),
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
                      child: pw.Text(_tr(language, es: 'Descripción', en: 'Description', pt: 'Descrição', it: 'Descrizione'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_tr(language, es: 'Monto', en: 'Amount', pt: 'Valor', it: 'Importo'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_tr(language, es: 'Fecha', en: 'Date', pt: 'Data', it: 'Data'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
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
            pw.Text(_tr(language, es: 'EGRESOS', en: 'EXPENSES', pt: 'DESPESAS', it: 'SPESE'),
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
                      child: pw.Text(_tr(language, es: 'Descripción', en: 'Description', pt: 'Descrição', it: 'Descrizione'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_tr(language, es: 'Categoría', en: 'Category', pt: 'Categoria', it: 'Categoria'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_tr(language, es: 'Monto', en: 'Amount', pt: 'Valor', it: 'Importo'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_tr(language, es: 'Fecha', en: 'Date', pt: 'Data', it: 'Data'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
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
                        child: pw.Text(
                          t['categoria'] ?? _tr(language, es: 'Otro', en: 'Other', pt: 'Outro', it: 'Altro'),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
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
  AppLanguage language = AppLanguage.spanish,
}) async {
  final excel = Excel.createExcel();
  
  // Hoja 1: Resumen
  final summarySheet = excel[_tr(language, es: 'Resumen', en: 'Summary', pt: 'Resumo', it: 'Riepilogo')];
  final monthName = _getMonthName(month.month, language);
  
  summarySheet.appendRow([_tr(language, es: 'INFORME MENSUAL - ZENTAVO', en: 'MONTHLY REPORT - ZENTAVO', pt: 'RELATÓRIO MENSAL - ZENTAVO', it: 'REPORT MENSILE - ZENTAVO')]);
  summarySheet.appendRow(['$monthName ${month.year}']);
  summarySheet.appendRow([]);
  summarySheet.appendRow([_tr(language, es: 'RESUMEN DEL MES', en: 'MONTH SUMMARY', pt: 'RESUMO DO MÊS', it: 'RIEPILOGO DEL MESE')]);
  summarySheet.appendRow([_tr(language, es: 'Concepto', en: 'Concept', pt: 'Conceito', it: 'Concetto'), _tr(language, es: 'Monto', en: 'Amount', pt: 'Valor', it: 'Importo')]);
  summarySheet.appendRow([_tr(language, es: 'Total Ingresos', en: 'Total Income', pt: 'Total Receitas', it: 'Totale Entrate'), ingresos]);
  summarySheet.appendRow([_tr(language, es: 'Total Egresos', en: 'Total Expenses', pt: 'Total Despesas', it: 'Totale Spese'), egresos]);
  summarySheet.appendRow([_tr(language, es: 'Balance', en: 'Balance', pt: 'Saldo', it: 'Saldo'), ingresos - egresos]);
  
  // Hoja 2: Egresos por categoría
  final egresosList = transactions.where((t) => t['tipo'] == 'Egreso').toList();
  final Map<String, double> egreosPorCategoria = {};
  for (final egreso in egresosList) {
    final cat = egreso['categoria'] ?? _tr(language, es: 'Otro', en: 'Other', pt: 'Outro', it: 'Altro');
    egreosPorCategoria[cat] = (egreosPorCategoria[cat] ?? 0) + (egreso['monto'] as num).toDouble();
  }
  
  if (egreosPorCategoria.isNotEmpty) {
    final categorySheet = excel[_tr(language, es: 'Categorías', en: 'Categories', pt: 'Categorias', it: 'Categorie')];
    categorySheet.appendRow([_tr(language, es: 'Distribución de Egresos por Categoría', en: 'Expense Distribution by Category', pt: 'Distribuição de Despesas por Categoria', it: 'Distribuzione delle Spese per Categoria')]);
    categorySheet.appendRow([_tr(language, es: 'Categoría', en: 'Category', pt: 'Categoria', it: 'Categoria'), _tr(language, es: 'Monto', en: 'Amount', pt: 'Valor', it: 'Importo'), _tr(language, es: 'Porcentaje', en: 'Percentage', pt: 'Percentual', it: 'Percentuale')]);
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
    final incomesSheet = excel[_tr(language, es: 'Ingresos', en: 'Income', pt: 'Receitas', it: 'Entrate')];
    incomesSheet.appendRow([
      _tr(language, es: 'Descripción', en: 'Description', pt: 'Descrição', it: 'Descrizione'),
      _tr(language, es: 'Monto', en: 'Amount', pt: 'Valor', it: 'Importo'),
      _tr(language, es: 'Fecha', en: 'Date', pt: 'Data', it: 'Data'),
      _tr(language, es: 'Observación', en: 'Note', pt: 'Observação', it: 'Nota'),
    ]);
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
    final expensesSheet = excel[_tr(language, es: 'Egresos', en: 'Expenses', pt: 'Despesas', it: 'Spese')];
    expensesSheet.appendRow([
      _tr(language, es: 'Descripción', en: 'Description', pt: 'Descrição', it: 'Descrizione'),
      _tr(language, es: 'Categoría', en: 'Category', pt: 'Categoria', it: 'Categoria'),
      _tr(language, es: 'Monto', en: 'Amount', pt: 'Valor', it: 'Importo'),
      _tr(language, es: 'Fecha', en: 'Date', pt: 'Data', it: 'Data'),
      _tr(language, es: 'Observación', en: 'Note', pt: 'Observação', it: 'Nota'),
    ]);
    for (final t in egresosList) {
      final fecha = t['fecha'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(t['fecha'])) : 'N/A';
      expensesSheet.appendRow([
        t['titulo'] ?? '',
        t['categoria'] ?? _tr(language, es: 'Otro', en: 'Other', pt: 'Outro', it: 'Altro'),
        t['monto'],
        fecha,
        t['justificacion'] ?? '',
      ]);
    }
  }
  
  excel.delete('Sheet1');
  return excel.encode() ?? [];
}

String _tr(
  AppLanguage language, {
  required String es,
  String? en,
  String? pt,
  String? it,
  String? zh,
  String? ja,
}) {
  switch (language) {
    case AppLanguage.english:
      return en ?? es;
    case AppLanguage.portuguese:
      return pt ?? es;
    case AppLanguage.italian:
      return it ?? es;
    case AppLanguage.chinese:
      return zh ?? es;
    case AppLanguage.japanese:
      return ja ?? es;
    case AppLanguage.spanish:
      return es;
  }
}

String _getMonthName(int month, AppLanguage language) {
  const monthsEs = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];
  const monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  const monthsPt = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];
  const monthsIt = [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
  ];

  switch (language) {
    case AppLanguage.english:
      return monthsEn[month - 1];
    case AppLanguage.portuguese:
      return monthsPt[month - 1];
    case AppLanguage.italian:
      return monthsIt[month - 1];
    case AppLanguage.chinese:
    case AppLanguage.japanese:
    case AppLanguage.spanish:
      return monthsEs[month - 1];
  }
}
