import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taller 1',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      appBar: AppBar(title: Text(_titulo)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Widget adicional 1: Image
            Image.asset('assets/images/logo.jpg', height: 120),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cambiarTitulo,
              child: const Text('Cambiar título'),
            ),
            const SizedBox(height: 24),
            // Widget adicional 2: SwitchListTile
            SwitchListTile(
              title: const Text('Activar opción'),
              value: _modoActivo,
              onChanged: (valor) {
                setState(() {
                  _modoActivo = valor;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}