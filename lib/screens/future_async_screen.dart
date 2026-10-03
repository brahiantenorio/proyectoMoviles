import 'package:flutter/material.dart';
import '../services/mock_data_service.dart';

/// Posibles estados del flujo asíncrono.
enum FutureState {
  initial,
  loading,
  success,
  error,
}

class FutureAsyncScreen extends StatefulWidget {
  const FutureAsyncScreen({super.key});

  @override
  State<FutureAsyncScreen> createState() => _FutureAsyncScreenState();
}

class _FutureAsyncScreenState extends State<FutureAsyncScreen> {
  FutureState _state = FutureState.initial;
  List<Map<String, dynamic>> _data = [];
  String? _errorMessage;
  final List<String> _consoleLogs = [];
  int _tapCounter = 0; // Prueba de que la UI no se bloquea

  void _addLog(String log) {
    print(log);
    setState(() {
      _consoleLogs.add(log);
      if (_consoleLogs.length > 25) {
        _consoleLogs.removeAt(0);
      }
    });
  }

  /// Ejecuta la consulta usando async / await
  Future<void> _consultarDatos({required bool simularFallo}) async {
    // 1. ANTES DE LA EJECUCIÓN
    final horaInicio = DateTime.now();
    _addLog('[Future/UI] 1. [ANTES]: Usuario solicita consulta (${simularFallo ? "Con Error" : "Con Éxito"}). Hora: ${horaInicio.toIso8601String().substring(11, 19)}');
    _addLog('[Future/UI] 1. [ANTES]: Actualizando estado de la UI a "Cargando..."');

    setState(() {
      _state = FutureState.loading;
      _errorMessage = null;
    });

    // 2. DURANTE LA EJECUCIÓN
    _addLog('[Future/UI] 2. [DURANTE]: Esperando respuesta del servidor con "await MockDataService.fetchData()"...');
    _addLog('[Future/UI] 2. [DURANTE]: El hilo principal (UI) permanece totalmente libre y responsivo.');

    try {
      final resultado = await MockDataService.fetchData(simulateError: simularFallo);

      // 3. DESPUÉS DE LA EJECUCIÓN (ÉXITO)
      final horaFin = DateTime.now();
      final duracion = horaFin.difference(horaInicio).inMilliseconds;
      _addLog('[Future/UI] 3. [DESPUÉS]: Éxito recibido en $duracion ms. Procesando ${resultado.length} registros.');
      _addLog('[Future/UI] 3. [DESPUÉS]: Actualizando estado a "Éxito".');

      if (!mounted) return;
      setState(() {
        _state = FutureState.success;
        _data = resultado;
      });
    } catch (error) {
      // 3. DESPUÉS DE LA EJECUCIÓN (ERROR)
      final horaFin = DateTime.now();
      final duracion = horaFin.difference(horaInicio).inMilliseconds;
      _addLog('[Future/UI] 3. [DESPUÉS]: Error capturado tras $duracion ms: $error');
      _addLog('[Future/UI] 3. [DESPUÉS]: Actualizando estado a "Error".');

      if (!mounted) return;
      setState(() {
        _state = FutureState.error;
        _errorMessage = error.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _limpiarEstado() {
    _addLog('[Future/UI] Estado reiniciado a Inicial.');
    setState(() {
      _state = FutureState.initial;
      _data = [];
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asincronía: Future / async / await'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restablecer',
            onPressed: _state == FutureState.loading ? null : _limpiarEstado,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner explicativo
            _buildExplanationCard(),
            const SizedBox(height: 16),

            // Prueba interactiva de fluidez (UI no bloqueada)
            _buildResponsivenessTestCard(),
            const SizedBox(height: 16),

            // Botones de acción
            _buildActionButtons(),
            const SizedBox(height: 16),

            // Estado actual
            _buildStateCard(),
            const SizedBox(height: 16),

            // Registro de consola en pantalla
            _buildConsoleLogsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Requisito 1: Future & async/await',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Simula una consulta de red con retraso de 2.5s usando Future.delayed. '
              'Gracias a async/await, Flutter suspende la ejecución de esta función sin congelar '
              'la interfaz gráfica ni la renderización.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsivenessTestCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.touch_app, color: Colors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prueba de fluidez (UI No Bloqueada):',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    'Toques registrados: $_tapCounter',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                setState(() => _tapCounter++);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tocar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final isLoading = _state == FutureState.loading;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isLoading ? null : () => _consultarDatos(simularFallo: false),
                icon: const Icon(Icons.cloud_download),
                label: const Text('Consultar (Éxito)'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.indigo,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : () => _consultarDatos(simularFallo: true),
                icon: const Icon(Icons.error_outline, color: Colors.deepOrange),
                label: const Text('Simular Error'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.deepOrange),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStateCard() {
    switch (_state) {
      case FutureState.initial:
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                Icon(Icons.cloud_sync, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'Estado: Inicial / En Espera',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Presione uno de los botones superiores para iniciar la consulta asíncrona.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        );

      case FutureState.loading:
        return Card(
          elevation: 2,
          color: Colors.amber.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.amber.shade400),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(strokeWidth: 4, color: Colors.amber),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Estado: Cargando...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esperando resolución del Future (2.5 segundos)...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                const LinearProgressIndicator(color: Colors.amber),
              ],
            ),
          ),
        );

      case FutureState.success:
        return Card(
          elevation: 2,
          color: Colors.green.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.green.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 28),
                    const SizedBox(width: 10),
                    const Text(
                      'Estado: Éxito',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Spacer(),
                    Chip(
                      label: Text('${_data.length} elementos'),
                      backgroundColor: Colors.green.shade100,
                    ),
                  ],
                ),
                const Divider(height: 24),
                ..._data.map((item) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 0,
                      color: Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(Icons.data_usage, color: Colors.green),
                        ),
                        title: Text(
                          item['titulo'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(item['subtitulo'] ?? ''),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            item['id'] ?? '',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        );

      case FutureState.error:
        return Card(
          elevation: 2,
          color: Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.red.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Estado: Error',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Ocurrió un error inesperado al procesar la petición.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () => _consultarDatos(simularFallo: false),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar con éxito'),
                  style: FilledButton.styleFrom(foregroundColor: Colors.red.shade900),
                ),
              ],
            ),
          ),
        );
    }
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
                const Icon(Icons.terminal, color: Colors.greenAccent, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Consola de Ejecución (Orden de eventos)',
                  style: TextStyle(
                    color: Colors.greenAccent,
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
              constraints: const BoxConstraints(maxHeight: 180),
              child: _consoleLogs.isEmpty
                  ? const Text(
                      '// Los eventos de consola (antes, durante y después) aparecerán aquí y en la terminal...',
                      style: TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _consoleLogs.length,
                      itemBuilder: (context, index) {
                        final log = _consoleLogs[index];
                        Color textColor = Colors.white;
                        if (log.contains('1. [ANTES]')) {
                          textColor = Colors.lightBlueAccent;
                        } else if (log.contains('2. [DURANTE]')) {
                          textColor = Colors.amberAccent;
                        } else if (log.contains('3. [DESPUÉS]')) {
                          textColor = log.contains('Error') ? Colors.redAccent : Colors.lightGreenAccent;
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
