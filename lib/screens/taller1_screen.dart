import 'package:flutter/material.dart';

/// Pantalla correspondiente al Taller 1 previo.
/// Se preserva intacta para mantener el historial y funcionalidades completas de la materia.
class Taller1Screen extends StatefulWidget {
  const Taller1Screen({super.key});

  @override
  State<Taller1Screen> createState() => _Taller1ScreenState();
}

class _Taller1ScreenState extends State<Taller1Screen> {
  bool _cambiado = false;
  bool _modoActivo = false;

  String get _titulo => _cambiado ? 'Título cambiado' : 'Título inicial';

  void _cambiarTitulo() {
    setState(() {
      _cambiado = !_cambiado;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('El título cambió a: $_titulo')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulo),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Widget adicional 1: Image
              Image.asset('assets/images/logo.jpg', height: 120),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _cambiarTitulo,
                icon: const Icon(Icons.edit),
                label: const Text('Cambiar título'),
              ),
              const SizedBox(height: 24),
              // Widget adicional 2: SwitchListTile
              Card(
                child: SwitchListTile(
                  title: const Text('Activar opción'),
                  subtitle: Text(_modoActivo ? 'Opción activada' : 'Opción desactivada'),
                  value: _modoActivo,
                  onChanged: (valor) {
                    setState(() {
                      _modoActivo = valor;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
