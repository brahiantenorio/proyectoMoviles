import 'dart:async';
import 'package:flutter/material.dart';

/// Estado actual del cronómetro.
enum ChronoState {
  stopped,
  running,
  paused,
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // Timer periódico para actualizar la UI cada 100 milisegundos
  Timer? _timer;

  // Tiempo acumulado en milisegundos
  int _milliseconds = 0;

  // Estado del cronómetro
  ChronoState _state = ChronoState.stopped;

  // Lista de vueltas / laps registradas
  final List<String> _laps = [];

  // Logs en vivo para evidencias
  final List<String> _logs = [];

  void _addLog(String message) {
    print(message);
    setState(() {
      _logs.add(message);
      if (_logs.length > 20) {
        _logs.removeAt(0);
      }
    });
  }

  /// Inicia el cronómetro desde cero
  void _iniciar() {
    if (_state == ChronoState.running) return;

    _addLog('[Timer] INICIAR: Creando Timer.periodic (intervalo: 100ms)...');
    _milliseconds = 0;
    _laps.clear();

    _timer?.cancel(); // Por seguridad cancelamos cualquier timer previo
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _milliseconds += 100;
      });
    });

    setState(() {
      _state = ChronoState.running;
    });
    _addLog('[Timer] Cronómetro en marcha.');
  }

  /// Pausa el conteo y cancela el Timer para no consumir recursos
  void _pausar() {
    if (_state != ChronoState.running) return;

    // CANCELAR EL TIMER AL PAUSAR (Requisito explícito de limpieza de recursos)
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      _addLog('[Timer/Limpieza] PAUSAR: _timer.cancel() ejecutado. Tiempo congelado en ${_formatTime(_milliseconds)}.');
    }

    setState(() {
      _state = ChronoState.paused;
    });
  }

  /// Reanuda el conteo desde el tiempo donde quedó pausado
  void _reanudar() {
    if (_state != ChronoState.paused) return;

    _addLog('[Timer] REANUDAR: Recreando Timer.periodic desde ${_formatTime(_milliseconds)}...');

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _milliseconds += 100;
      });
    });

    setState(() {
      _state = ChronoState.running;
    });
    _addLog('[Timer] Cronómetro reanudado con éxito.');
  }

  /// Reinicia el cronómetro a 0 y cancela el Timer
  void _reiniciar() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      _addLog('[Timer/Limpieza] REINICIAR: _timer.cancel() ejecutado.');
    }

    setState(() {
      _milliseconds = 0;
      _state = ChronoState.stopped;
      _laps.clear();
    });
    _addLog('[Timer] Cronómetro reiniciado a 00:00:00.0.');
  }

  /// Registrar vuelta opcional
  void _marcarVuelta() {
    if (_state == ChronoState.running) {
      final lapFormatted = _formatTime(_milliseconds);
      setState(() {
        _laps.insert(0, 'Vuelta ${_laps.length + 1}: $lapFormatted');
      });
      _addLog('[Timer] Vuelta registrada: $lapFormatted');
    }
  }

  /// Limpieza obligatoria de recursos al salir de la vista
  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      print('[Timer/Lifecycle] DISPOSE: Timer cancelado exitosamente al salir de la pantalla.');
    }
    super.dispose();
  }

  /// Formatea milisegundos a formato estilo marcador digital HH:MM:SS.D
  String _formatTime(int totalMs) {
    final int hours = totalMs ~/ (1000 * 60 * 60);
    final int minutes = (totalMs % (1000 * 60 * 60)) ~/ (1000 * 60);
    final int seconds = (totalMs % (1000 * 60)) ~/ 1000;
    final int tenths = (totalMs % 1000) ~/ 100;

    final String h = hours.toString().padLeft(2, '0');
    final String m = minutes.toString().padLeft(2, '0');
    final String s = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$h:$m:$s.$tenths';
    }
    return '$m:$s.$tenths';
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatTime(_milliseconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronómetro con Timer'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta informativa
            _buildExplanationCard(),
            const SizedBox(height: 20),

            // Marcador digital estilo LCD
            _buildScoreboardCard(formattedTime),
            const SizedBox(height: 24),

            // Panel de control con los 4 botones requeridos
            _buildControlButtons(),
            const SizedBox(height: 24),

            // Lista de vueltas (si las hay)
            if (_laps.isNotEmpty) ...[
              _buildLapsCard(),
              const SizedBox(height: 20),
            ],

            // Consola de eventos y limpieza de memoria
            _buildConsoleLogsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer_outlined, color: Colors.blue.shade800),
                const SizedBox(width: 8),
                Text(
                  'Requisito 2: Timer & Limpieza de Recursos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Usa Timer.periodic cada 100 ms para actualizar el marcador. '
              'Garantiza la cancelación del Timer tanto al pausar como en el ciclo de vida dispose() '
              'para prevenir pérdidas de memoria (memory leaks).',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreboardCard(String formattedTime) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (_state) {
      case ChronoState.running:
        badgeColor = Colors.green;
        badgeText = 'EN MARCHA';
        badgeIcon = Icons.play_arrow;
        break;
      case ChronoState.paused:
        badgeColor = Colors.amber.shade700;
        badgeText = 'EN PAUSA (Timer cancelado)';
        badgeIcon = Icons.pause;
        break;
      case ChronoState.stopped:
        badgeColor = Colors.grey.shade600;
        badgeText = 'DETENIDO';
        badgeIcon = Icons.stop;
        break;
    }

    return Card(
      elevation: 4,
      color: const Color(0xFF0F172A), // Slate 900
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF334155), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 20.0),
        child: Column(
          children: [
            // Estado Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, color: badgeColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Texto Grande estilo Marcador
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formattedTime,
                style: const TextStyle(
                  color: Color(0xFF38BDF8), // Cyan brillante digital
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Color(0x8038BDF8),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Etiquetas de unidades
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'MINUTOS  :  SEGUNDOS  .  DÉCIMAS',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        // Fila 1: Iniciar / Pausar / Reanudar
        Row(
          children: [
            if (_state == ChronoState.stopped)
              Expanded(
                child: FilledButton.icon(
                  onPressed: _iniciar,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar', style: TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

            if (_state == ChronoState.running) ...[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _pausar,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pausar', style: TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: _marcarVuelta,
                icon: const Icon(Icons.flag),
                label: const Text('Vuelta'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],

            if (_state == ChronoState.paused)
              Expanded(
                child: FilledButton.icon(
                  onPressed: _reanudar,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Reanudar', style: TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Fila 2: Botón Reiniciar
        OutlinedButton.icon(
          onPressed: _state == ChronoState.stopped && _milliseconds == 0 ? null : _reiniciar,
          icon: const Icon(Icons.replay),
          label: const Text('Reiniciar', style: TextStyle(fontSize: 15)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: Colors.red.shade700,
            side: BorderSide(
              color: _state == ChronoState.stopped && _milliseconds == 0
                  ? Colors.grey.shade300
                  : Colors.red.shade300,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildLapsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(
                  'Vueltas Registradas (${_laps.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const Divider(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _laps.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      _laps[index],
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
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
                const Icon(Icons.terminal, color: Colors.amberAccent, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Consola de Timer & Limpieza de Recursos',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                if (_logs.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _logs.clear()),
                    child: const Text(
                      'Limpiar',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              child: _logs.isEmpty
                  ? const Text(
                      '// Los eventos de Timer (iniciar, pausar, reanudar, dispose) se reflejarán aquí...',
                      style: TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final isClean = log.contains('Limpieza');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: isClean ? Colors.cyanAccent : Colors.white70,
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
