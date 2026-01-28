import 'package:flutter_test/flutter_test.dart';
import 'package:control_gastos/export_utils.dart';

void main() {
  final sample = [
    {
      'titulo': 'Sueldo',
      'monto': 1000.0,
      'tipo': 'Ingreso',
      'categoria': 'Servicios',
      'justificacion': 'Pago mensual',
    },
    {
      'titulo': 'Alquiler',
      'monto': -300.0,
      'tipo': 'Egreso',
      'categoria': 'Vivienda',
      'justificacion': 'Casa',
    },
  ];

  test('exportToJson produces valid JSON', () {
    final json = exportToJson(sample);
    expect(json, isNotEmpty);
    expect(json.contains('Sueldo'), isTrue);
    expect(json.contains('Alquiler'), isTrue);
  });

  test('exportToCsv produces expected header and rows', () {
    final csv = exportToCsv(sample);
    expect(csv, contains('titulo,monto,tipo,categoria,justificacion'));
    expect(csv, contains('Sueldo'));
    expect(csv, contains('Alquiler'));
  });

  test('exportToText produces lines for each item', () {
    final txt = exportToText(sample);
    expect(txt.split('\n').length, greaterThanOrEqualTo(2));
    expect(txt, contains('Sueldo'));
  });
}
