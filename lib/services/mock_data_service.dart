/// Servicio simulado para demostrar asincronía con Future, async y await.
/// Simula consultas de red o base de datos con retrasos controlados.
class MockDataService {
  /// Consulta simulada de datos.
  /// 
  /// Utiliza [Future.delayed] de 2 a 3 segundos para emular latencia de red.
  /// Imprime en consola el orden de ejecución (antes, durante y después).
  static Future<List<Map<String, dynamic>>> fetchData({bool simulateError = false}) async {
    print('------------------------------------------------------------');
    print('[Future/Servicio] 1. [ANTES]: Iniciando servicio de consulta remota...');
    print('[Future/Servicio] 2. [DURANTE]: Esperando respuesta simulada con Future.delayed (2500 ms)...');
    
    // Retraso no bloqueante de 2.5 segundos
    await Future.delayed(const Duration(milliseconds: 2500));

    if (simulateError) {
      print('[Future/Servicio] 3. [DESPUÉS]: Ocurrió una falla simulada al obtener datos (HTTP 500).');
      print('------------------------------------------------------------');
      throw Exception('Error 500: Fallo en la comunicación con el servidor remoto. Intente nuevamente.');
    }

    print('[Future/Servicio] 3. [DESPUÉS]: Respuesta recibida exitosamente con 4 registros.');
    print('------------------------------------------------------------');
    
    return [
      {
        'id': 'REG-001',
        'titulo': 'Métricas de Tráfico de Red',
        'subtitulo': 'Latencia: 18ms | Ancho de banda: 120 Mbps',
        'categoria': 'Infraestructura',
        'icono': 'network_check',
      },
      {
        'id': 'REG-002',
        'titulo': 'Estado de Base de Datos',
        'subtitulo': 'Conexiones activas: 42 | Replicación sincronizada',
        'categoria': 'Base de Datos',
        'icono': 'storage',
      },
      {
        'id': 'REG-003',
        'titulo': 'Monitor de Servicios Cloud',
        'subtitulo': 'Instancias operativas: 6/6 | Salud: 100%',
        'categoria': 'Cloud',
        'icono': 'cloud_done',
      },
      {
        'id': 'REG-004',
        'titulo': 'Auditoría de Seguridad',
        'subtitulo': 'Certificados SSL válidos | 0 vulnerabilidades críticas',
        'categoria': 'Seguridad',
        'icono': 'security',
      },
    ];
  }
}
