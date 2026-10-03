import 'dart:isolate';

/// Parámetros enviados al worker del Isolate.
class IsolateTaskParams {
  final SendPort sendPort;
  final int iterations;

  const IsolateTaskParams({
    required this.sendPort,
    required this.iterations,
  });
}

/// Servicio que encapsula tareas intensivas de CPU y su ejecución en Isolates.
class HeavyComputationService {
  /// Función de nivel superior / estática requerida por [Isolate.spawn].
  ///
  /// Ejecuta un algoritmo CPU-bound intensivo (suma cuadrática y verificación modular)
  /// en un hilo del sistema operativo totalmente independiente del Main Isolate.
  static void heavyWorker(IsolateTaskParams params) {
    final sendPort = params.sendPort;
    final total = params.iterations;

    // 1. Mensaje de inicio
    sendPort.send({
      'type': 'status',
      'message': 'Hilo de Isolate iniciado. Comenzando $total iteraciones CPU-bound...',
      'progress': 0.0,
    });

    final stopwatch = Stopwatch()..start();
    double accumulator = 0.0;
    int primesCount = 0;

    // Reportamos progreso en intervalos
    final int step = total ~/ 4;

    for (int i = 1; i <= total; i++) {
      // Operaciones matemáticas pesadas para consumir CPU
      accumulator += (i * 0.0001) % 7.0;

      // Cálculo de residuo para simular carga de trabajo
      if (i % 2 != 0 && i % 3 != 0 && i % 5 != 0) {
        primesCount++;
      }

      // Enviar reporte de progreso por SendPort
      if (step > 0 && i % step == 0) {
        final progress = i / total;
        sendPort.send({
          'type': 'progress',
          'message': 'Isolate procesando: ${(progress * 100).toInt()}% completado...',
          'progress': progress,
        });
      }
    }

    stopwatch.stop();

    // 2. Enviar resultado final empaquetado por mensaje
    sendPort.send({
      'type': 'completed',
      'message': 'Cómputo finalizado exitosamente en Isolate secundario.',
      'totalIterations': total,
      'accumulator': accumulator.toStringAsFixed(2),
      'primesCount': primesCount,
      'durationMs': stopwatch.elapsedMilliseconds,
      'progress': 1.0,
    });
  }

  /// Ejecución de la misma tarea pesada directamente en el hilo principal (Main Thread).
  ///
  /// ADVERTENCIA: Esta función provocará bloqueo/congelamiento temporal de la UI
  /// para demostrar visualmente por qué los Isolates son indispensables para tareas CPU-bound.
  static Map<String, dynamic> executeOnMainThread(int iterations) {
    final stopwatch = Stopwatch()..start();
    double accumulator = 0.0;
    int primesCount = 0;

    for (int i = 1; i <= iterations; i++) {
      accumulator += (i * 0.0001) % 7.0;
      if (i % 2 != 0 && i % 3 != 0 && i % 5 != 0) {
        primesCount++;
      }
    }

    stopwatch.stop();

    return {
      'type': 'completed',
      'totalIterations': iterations,
      'accumulator': accumulator.toStringAsFixed(2),
      'primesCount': primesCount,
      'durationMs': stopwatch.elapsedMilliseconds,
    };
  }
}
