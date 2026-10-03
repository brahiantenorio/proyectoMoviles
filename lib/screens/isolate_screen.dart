import 'dart:isolate';
import 'package:flutter/material.dart';
import '../services/heavy_computation_service.dart';

class IsolateScreen extends StatefulWidget {
  const IsolateScreen({super.key});

  @override
  State<IsolateScreen> createState() => _IsolateScreenState();
}

class _IsolateScreenState extends State<IsolateScreen>
    with SingleTickerProviderStateMixin {
  // Controlador para animación continua que demuestra si la UI se congela o no
  late AnimationController _animationController;

  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = 'Listo para iniciar tarea pesada.';
  
  // Métricas de ejecución
  String? _startTimeFormatted;
  String? _endTimeFormatted;
  int? _executionDurationMs;
  Map<String, dynamic>? _lastResult;

  // Contador táctil interactivo
  int _uiTapCount = 0;

  // Cantidad de iteraciones configurables (por defecto 50 millones)
  int _selectedIterations = 50000000;

  // Consola de mensajes recibidos por el ReceivePort
  final List<String> _consoleLogs = [];

  // Referencias a los recursos del Isolate para limpieza
  ReceivePort? _receivePort;
  Isolate? _spawnedIsolate;

  @override
  void initState() {
    super.initState();
    // Animación continua a 60 FPS
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cleanupIsolate();
    super.dispose();
  }

  void _cleanupIsolate() {
    if (_receivePort != null) {
      _receivePort!.close();
      _receivePort = null;
    }
    if (_spawnedIsolate != null) {
      _spawnedIsolate!.kill(priority: Isolate.immediate);
      _spawnedIsolate = null;
    }
  }

  void _addLog(String log) {
    print(log);
    setState(() {
      _consoleLogs.add(log);
      if (_consoleLogs.length > 25) {
        _consoleLogs.removeAt(0);
      }
    });
  }

  /// Ejecuta la tarea pesada usando [Isolate.spawn] y comunicación por mensajes
  Future<void> _ejecutarEnIsolate() async {
    if (_isProcessing) return;

    _cleanupIsolate();

    final startTime = DateTime.now();
    final startStr = startTime.toIso8601String().substring(11, 23);

    _addLog('============================================================');
    _addLog('[Isolate/Main] 1. INICIO: Solicitud de tarea pesada con $_selectedIterations operaciones.');
    _addLog('[Isolate/Main] 1. Hora de inicio: $startStr');
    _addLog('[Isolate/Main] 2. Creando ReceivePort en el hilo principal...');

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _startTimeFormatted = startStr;
      _endTimeFormatted = null;
      _executionDurationMs = null;
      _lastResult = null;
      _statusMessage = 'Iniciando Isolate secundario...';
    });

    // Crear el puerto receptor en el hilo principal
    _receivePort = ReceivePort();

    final params = IsolateTaskParams(
      sendPort: _receivePort!.sendPort,
      iterations: _selectedIterations,
    );

    _addLog('[Isolate/Main] 3. Ejecutando Isolate.spawn(HeavyComputationService.heavyWorker)...');
    _spawnedIsolate = await Isolate.spawn<IsolateTaskParams>(
      HeavyComputationService.heavyWorker,
      params,
    );

    // Escuchar mensajes entrantes del Isolate secundario
    _receivePort!.listen((dynamic message) {
      if (message is Map<String, dynamic>) {
        final type = message['type'];

        if (type == 'status') {
          _addLog('[Isolate/Worker] Mensaje recibido: ${message['message']}');
          setState(() {
            _statusMessage = message['message'] as String;
          });
        } else if (type == 'progress') {
          final progress = (message['progress'] as double);
          _addLog('[Isolate/Worker] Mensaje de progreso: ${message['message']}');
          setState(() {
            _progress = progress;
            _statusMessage = message['message'] as String;
          });
        } else if (type == 'completed') {
          final endTime = DateTime.now();
          final endStr = endTime.toIso8601String().substring(11, 23);
          final durationMs = message['durationMs'] as int;

          _addLog('[Isolate/Worker] Mensaje final recibido: ${message['message']}');
          _addLog('[Isolate/Main] 4. FINALIZADO: Hora fin: $endStr | Duración real: $durationMs ms.');
          _addLog('[Isolate/Main] 5. Cerrando ReceivePort y liberando Isolate.');
          _addLog('============================================================');

          setState(() {
            _isProcessing = false;
            _progress = 1.0;
            _endTimeFormatted = endStr;
            _executionDurationMs = durationMs;
            _lastResult = message;
            _statusMessage = 'Tarea completada exitosamente en Isolate.';
          });

          _cleanupIsolate();
        }
      }
    });
  }

  /// Ejecuta la tarea en el hilo principal para evidenciar el bloqueo de la UI
  void _ejecutarEnHiloPrincipal() {
    if (_isProcessing) return;

    final startTime = DateTime.now();
    final startStr = startTime.toIso8601String().substring(11, 23);

    _addLog('------------------------------------------------------------');
    _addLog('[MainThread] ADVERTENCIA: Ejecutando en el hilo principal (UI).');
    _addLog('[MainThread] Inicio: $startStr. La animación y botones se congelarán temporalmente...');

    setState(() {
      _isProcessing = true;
      _startTimeFormatted = startStr;
      _endTimeFormatted = null;
      _executionDurationMs = null;
      _lastResult = null;
      _statusMessage = 'Ejecutando en hilo principal (UI bloqueada)...';
    });

    // Pequeño delay para renderizar el cambio de estado antes de congelar el event loop
    Future.microtask(() {
      final result = HeavyComputationService.executeOnMainThread(_selectedIterations);
      final endTime = DateTime.now();
      final endStr = endTime.toIso8601String().substring(11, 23);

      _addLog('[MainThread] Fin: $endStr | Duración: ${result['durationMs']} ms.');
      _addLog('[MainThread] Event loop desbloqueado.');
      _addLog('------------------------------------------------------------');

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _progress = 1.0;
        _endTimeFormatted = endStr;
        _executionDurationMs = result['durationMs'] as int;
        _lastResult = result;
        _statusMessage = 'Completado en hilo principal (congeló la UI).';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Isolate para Tarea Pesada'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta explicativa
            _buildExplanationCard(),
            const SizedBox(height: 16),

            // Tarjeta de fluidez con animación 60 FPS
            _buildAnimationAndResponsivenessCard(),
            const SizedBox(height: 16),

            // Selector de iteraciones
            _buildIterationSelector(),
            const SizedBox(height: 16),

            // Botones de acción (Isolate vs Main Thread)
            _buildActionButtons(),
            const SizedBox(height: 16),

            // Tarjeta de resultados y tiempos
            _buildResultsCard(),
            const SizedBox(height: 16),

            // Consola de mensajes del Isolate
            _buildConsoleLogsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Card(
      elevation: 0,
      color: Colors.purple.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, color: Colors.purple.shade800),
                const SizedBox(width: 8),
                Text(
                  'Requisito 3: Isolate.spawn & Mensajes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.purple.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Dart es de un solo hilo por defecto. Para tareas CPU-bound pesadas, '
              'se utiliza Isolate.spawn para derivar el cálculo a un hilo separado de CPU, '
              'comunicándose con el hilo principal a través de SendPort y ReceivePort.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationAndResponsivenessCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Engranaje o spinner continuo
                RotationTransition(
                  turns: _animationController,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sync,
                      color: Colors.purple,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monitor de fluidez de la UI (60 FPS)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        _isProcessing
                            ? 'Procesando... ¡Observa cómo gira suavemente!'
                            : 'El giro constante demuestra que el hilo UI está libre.',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.touch_app, color: Colors.indigo),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Toques durante el proceso: $_uiTapCount',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => setState(() => _uiTapCount++),
                  child: const Text('¡Tocar aquí!'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIterationSelector() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Carga de trabajo (Iteraciones de cálculo):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 20000000,
                  label: Text('20 Millones'),
                ),
                ButtonSegment(
                  value: 50000000,
                  label: Text('50 Millones'),
                ),
                ButtonSegment(
                  value: 100000000,
                  label: Text('100 Millones'),
                ),
              ],
              selected: {_selectedIterations},
              onSelectionChanged: _isProcessing
                  ? null
                  : (newSelection) {
                      setState(() {
                        _selectedIterations = newSelection.first;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botón principal: Isolate.spawn
        FilledButton.icon(
          onPressed: _isProcessing ? null : _ejecutarEnIsolate,
          icon: const Icon(Icons.rocket_launch),
          label: const Text(
            'Ejecutar con Isolate.spawn (UI Fluida)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.purple.shade700,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 10),

        // Botón de comparación: Main Thread (congelará la UI temporalmente)
        OutlinedButton.icon(
          onPressed: _isProcessing ? null : _ejecutarEnHiloPrincipal,
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
          label: const Text(
            'Comparar: Ejecutar en Main Thread (Congela UI)',
            style: TextStyle(fontSize: 13, color: Colors.deepOrange),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            side: const BorderSide(color: Colors.deepOrange),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isProcessing ? Icons.hourglass_top : Icons.speed,
                  color: _isProcessing ? Colors.amber.shade800 : Colors.indigo,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tiempos y Resultados en Pantalla',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Barra de progreso y estado
            LinearProgressIndicator(
              value: _isProcessing ? (_progress > 0 ? _progress : null) : 1.0,
              backgroundColor: Colors.grey.shade200,
              color: Colors.purple,
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isProcessing ? Colors.purple.shade800 : Colors.black87,
              ),
            ),
            const Divider(height: 24),

            // Tabla de métricas
            _buildMetricRow('Hora de inicio:', _startTimeFormatted ?? '--:--:--'),
            _buildMetricRow('Hora de finalización:', _endTimeFormatted ?? '--:--:--'),
            _buildMetricRow(
              'Duración del cálculo:',
              _executionDurationMs != null ? '$_executionDurationMs ms' : '-- ms',
              isHighlight: true,
            ),
            if (_lastResult != null) ...[
              const Divider(height: 20),
              _buildMetricRow(
                'Operaciones realizadas:',
                '${_lastResult!['totalIterations']}',
              ),
              _buildMetricRow(
                'Acumulador matemático:',
                '${_lastResult!['accumulator']}',
              ),
              _buildMetricRow(
                'Números primos detectados:',
                '${_lastResult!['primesCount']}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? Colors.purple.shade800 : Colors.black87,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleLogsCard() {
    return Card(
      elevation: 0,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal, color: Colors.cyanAccent, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Consola de Isolate (SendPort / ReceivePort)',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                if (_consoleLogs.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _consoleLogs.clear()),
                    child: const Text(
                      'Limpiar',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              child: _consoleLogs.isEmpty
                  ? const Text(
                      '// Los mensajes enviados por SendPort y recibidos por ReceivePort aparecerán aquí...',
                      style: TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _consoleLogs.length,
                      itemBuilder: (context, index) {
                        final log = _consoleLogs[index];
                        Color textColor = Colors.white;
                        if (log.contains('Isolate/Main')) {
                          textColor = Colors.lightBlueAccent;
                        } else if (log.contains('Isolate/Worker')) {
                          textColor = Colors.greenAccent;
                        } else if (log.contains('MainThread')) {
                          textColor = Colors.orangeAccent;
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
