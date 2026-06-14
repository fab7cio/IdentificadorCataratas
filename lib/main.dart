import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'catarata_classifier.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplicación Móvil de Cataratas UPAO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const DiagnosticScreen(),
    );
  }
}

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  File? _image;
  String _resultado = "Seleccione una imagen para iniciar el análisis.";
  int _latencia = 0;
  int _ramUsada = 0;
  bool _loading = false;

  late CatarataClassifier _classifier;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _classifier = CatarataClassifier();
  }

  @override
  void dispose() {
    _classifier.close();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _loading = true;
        _resultado = "Analizando imagen...";
      });

      final analisis = await _classifier.clasificarRetina(_image!);

      try {
        final int ramUsada = ProcessInfo.currentRss ~/ (1024 * 1024);
        setState(() {
          _ramUsada = ramUsada;
        });
      } catch (e) {
        debugPrint('Error al obtener RAM: $e');
      }

      setState(() {
        _resultado = analisis['resultado'];
        _latencia = analisis['latencia'];
        _loading = false;
      });
    }
  }

  void _eliminarImagen() {
    setState(() {
      _image = null;
      _resultado = "Seleccione una imagen para iniciar el análisis.";
      _latencia = 0;
      _ramUsada = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identificador de Cataratas',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.5)),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_red_eye_outlined,
                              size: 80, color: Colors.teal),
                          SizedBox(height: 10),
                          Text('No hay imagen cargada',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
              const SizedBox(height: 15),

              // Botones cargar y eliminar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _seleccionarImagen,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Cargar imagen',
                          style: TextStyle(fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _image != null && !_loading ? _eliminarImagen : null,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar',
                        style: TextStyle(fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.assignment_outlined, color: Colors.teal),
                          SizedBox(width: 10),
                          Text('Reporte Clínico',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal)),
                        ],
                      ),
                      const Divider(height: 25),

                      // Diagnóstico
                      Text('Diagnóstico:',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 5),
                      Text(
                        _resultado,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _resultado.contains('Normal')
                              ? Colors.green
                              : Colors.red[800],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Latencia
                      Text('Velocidad de Procesamiento:',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.speed,
                            size: 20,
                            color: _latencia > 0 && _latencia <= 200
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$_latencia ms',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _latencia > 0 && _latencia <= 200
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_latencia > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _latencia <= 200
                                    ? Colors.green[50]
                                    : Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _latencia <= 200
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              child: Text(
                                _latencia <= 200 ? '✓ < 200ms' : '✗ > 200ms',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _latencia <= 200
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // RAM
                      Text('Uso de RAM:',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.memory, size: 20, color: Colors.purple),
                          const SizedBox(width: 5),
                          Text(
                            _ramUsada > 0 ? 'RAM usada: $_ramUsada MB' : '-- MB',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}