import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles/main.dart';

void main() {
  testWidgets('Carga inicial y navegación de la app', (WidgetTester tester) async {
    // Construir la aplicación
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Verificar que los destinos de navegación están presentes
    expect(find.text('Future & Async'), findsOneWidget);
    expect(find.text('Cronómetro'), findsOneWidget);
    expect(find.text('Isolates'), findsOneWidget);
    expect(find.text('Taller 1'), findsOneWidget);

    // Verificar que la primera vista (Future & Async) se muestra inicialmente
    expect(find.text('Asincronía: Future / async / await'), findsOneWidget);

    // Navegar a la pestaña de Cronómetro
    await tester.tap(find.text('Cronómetro'));
    await tester.pump(const Duration(milliseconds: 200));

    // Verificar que la vista de cronómetro está activa con botón Iniciar
    expect(find.text('Cronómetro con Timer'), findsOneWidget);
    expect(find.text('Iniciar'), findsOneWidget);

    // Navegar a la pestaña de Isolates
    await tester.tap(find.text('Isolates'));
    await tester.pump(const Duration(milliseconds: 200));

    // Verificar que la vista de Isolate está activa
    expect(find.text('Isolate para Tarea Pesada'), findsOneWidget);
    expect(find.text('Ejecutar con Isolate.spawn (UI Fluida)'), findsOneWidget);
  });
}
