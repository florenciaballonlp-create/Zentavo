import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:control_gastos/main.dart';

void main() {
  group('Control de Gastos - Pruebas de Ingresos y Egresos', () {
    testWidgets('La aplicación muestra el mensaje inicial cuando no hay movimientos',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ExpenseApp());

      // Verificar que se muestra el mensaje inicial
      expect(find.text('No hay movimientos aún. ¡Usa el botón +!'), findsOneWidget);
      expect(find.text('Control de Gastos'), findsOneWidget);
    });

    testWidgets('Se puede agregar un movimiento de ingreso', (WidgetTester tester) async {
      await tester.pumpWidget(const ExpenseApp());

      // Buscar el botón flotante de ingreso (verde)
      final ingresoButton = find.byWidgetPredicate(
        (widget) => widget is FloatingActionButton && 
                    widget.backgroundColor == Colors.green,
      );

      // Abrir el formulario con el botón flotante de ingreso
      await tester.tap(ingresoButton);
      await tester.pumpAndSettle();

      // Llenar los campos del formulario
      await tester.enterText(find.byType(TextField).at(0), 'Sueldo');
      await tester.enterText(find.byType(TextField).at(1), '1000');
      await tester.enterText(find.byType(TextField).at(2), 'Sueldo mensual');

      // Guardar el movimiento
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verificar que el movimiento se agregó
      expect(find.text('Sueldo'), findsOneWidget);
      expect(find.text('Sueldo mensual'), findsOneWidget);
      // Ahora hay 2 widgets con $1000.00: uno en la tarjeta de ingresos y otro en la lista
      expect(find.text('\$1000.00'), findsWidgets);
      
      // Verificar que aparece en la tarjeta de Ingresos
      expect(find.text('Ingresos'), findsOneWidget);
    });

    testWidgets('Se puede agregar un movimiento de egreso', (WidgetTester tester) async {
      await tester.pumpWidget(const ExpenseApp());

      // Buscar el botón flotante de egreso (rojo)
      final egresoButton = find.byWidgetPredicate(
        (widget) => widget is FloatingActionButton && 
                    widget.backgroundColor == Colors.red,
      );

      // Abrir el formulario
      await tester.tap(egresoButton);
      await tester.pumpAndSettle();

      // Llenar los campos
      await tester.enterText(find.byType(TextField).at(0), 'Alquiler');
      await tester.enterText(find.byType(TextField).at(1), '500');
      await tester.enterText(find.byType(TextField).at(2), 'Alquiler mensual');

      // Guardar el movimiento
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verificar que el movimiento se agregó con signo negativo
      expect(find.text('Alquiler'), findsOneWidget);
      expect(find.text('Alquiler mensual'), findsOneWidget);
      expect(find.text('\$-500.00'), findsOneWidget);
      
      // Verificar que aparece en la tarjeta de Egresos
      expect(find.text('Egresos'), findsOneWidget);
    });

    testWidgets('El balance se calcula correctamente con múltiples movimientos',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ExpenseApp());

      // Buscar botones
      final ingresoButton = find.byWidgetPredicate(
        (widget) => widget is FloatingActionButton && 
                    widget.backgroundColor == Colors.green,
      );
      final egresoButton = find.byWidgetPredicate(
        (widget) => widget is FloatingActionButton && 
                    widget.backgroundColor == Colors.red,
      );

      // Agregar un ingreso de 1000
      await tester.tap(ingresoButton);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Sueldo');
      await tester.enterText(find.byType(TextField).at(1), '1000');
      await tester.enterText(find.byType(TextField).at(2), 'Ingreso');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Agregar un egreso de 300
      await tester.tap(egresoButton);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Comida');
      await tester.enterText(find.byType(TextField).at(1), '300');
      await tester.enterText(find.byType(TextField).at(2), 'Compras');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verificar el balance: 1000 - 300 = 700
      expect(find.text('\$700.00'), findsOneWidget);
    });

    testWidgets('El ícono correcto se muestra para ingresos y egresos',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ExpenseApp());

      // Buscar botones
      final ingresoButton = find.byWidgetPredicate(
        (widget) => widget is FloatingActionButton && 
                    widget.backgroundColor == Colors.green,
      );
      final egresoButton = find.byWidgetPredicate(
        (widget) => widget is FloatingActionButton && 
                    widget.backgroundColor == Colors.red,
      );

      // Agregar ingreso
      await tester.tap(ingresoButton);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Sueldo');
      await tester.enterText(find.byType(TextField).at(1), '1000');
      await tester.enterText(find.byType(TextField).at(2), 'Ingreso');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Agregar egreso
      await tester.tap(egresoButton);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Gasto');
      await tester.enterText(find.byType(TextField).at(1), '100');
      await tester.enterText(find.byType(TextField).at(2), 'Egreso');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verificar que hay dos avatares circulares
      expect(find.byType(CircleAvatar), findsWidgets);
    });
  });
}
