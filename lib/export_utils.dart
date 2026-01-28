import 'dart:convert';

// Utilidades de exportación reutilizables
String exportToJson(List<Map<String, dynamic>> items) {
  return jsonEncode(items);
}

String exportToCsv(List<Map<String, dynamic>> items) {
  final sb = StringBuffer();
  sb.writeln('titulo,monto,tipo,justificacion');
  for (final t in items) {
    final titulo = (t['titulo'] ?? '').toString().replaceAll('"', '""');
    final just = (t['justificacion'] ?? '').toString().replaceAll('"', '""');
    sb.writeln('"$titulo",${t['monto']},${t['tipo']},"$just"');
  }
  return sb.toString();
}

String exportToText(List<Map<String, dynamic>> items) {
  final sb = StringBuffer();
  for (var i = 0; i < items.length; i++) {
    final t = items[i];
    sb.writeln('${i + 1}. ${t['titulo']} — ${t['tipo']} — \$${t['monto']} — ${t['justificacion']}');
  }
  return sb.toString();
}
