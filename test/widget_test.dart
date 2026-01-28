import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:control_gastos/main.dart';
import 'package:control_gastos/export_utils.dart';

void main() {
  group('Control de Gastos - Pruebas de Ingresos y Egresos', () {
    testWidgets('La aplicación muestra el mensaje inicial cuando no hay movimientos',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ExpenseApp());

      // Verificar que se muestra el mensaje inicial
      expect(find.text('No hay movimientos en este mes. ¡Usa el botón +!'), findsOneWidget);
      expect(find.text('💰 Control de Gastos'), findsOneWidget);
    });

    testWidgets('Se puede ver los Cards de Ingresos y Egresos',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ExpenseApp());

      // Verificar que aparecen los cards de totales
      expect(find.text('Ingresos'), findsOneWidget);
      expect(find.text('Egresos'), findsOneWidget);
      expect(find.text('Balance Total:'), findsOneWidget);
    });

    testWidgets('Se ve el AppBar con emoji',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ExpenseApp());

      // Verificar que el AppBar tiene el emoji 💰
      expect(find.text('💰 Control de Gastos'), findsOneWidget);
    });

    test('exportToCsv incluye la columna categoria',
        () {
      final sample = [
        {
          'titulo': 'Sueldo',
          'monto': 1000.0,
          'tipo': 'Ingreso',
          'categoria': 'Servicios',
          'justificacion': 'Pago mensual',
        },
      ];
      
      final csv = exportToCsv(sample);
      expect(csv.contains('categoria'), isTrue);
      expect(csv.contains('titulo,monto,tipo,categoria,justificacion'), isTrue);
    });

    test('exportToText incluye la categoria',
        () {
      final sample = [
        {
          'titulo': 'Sueldo',
          'monto': 1000.0,
          'tipo': 'Ingreso',
          'categoria': 'Servicios',
          'justificacion': 'Pago mensual',
        },
      ];
      
      final txt = exportToText(sample);
      expect(txt.contains('Servicios'), isTrue);
      expect(txt.contains('Sueldo'), isTrue);
    });

    test('exportToJson maneja categorias correctamente',
        () {
      final sample = [
        {
          'titulo': 'Almuerzo',
          'monto': -50.0,
          'tipo': 'Egreso',
          'categoria': 'Comida',
          'justificacion': 'Restaurante',
        },
      ];
      
      final json = exportToJson(sample);
      expect(json.contains('Comida'), isTrue);
      expect(json.contains('Almuerzo'), isTrue);
    });
  });
}




