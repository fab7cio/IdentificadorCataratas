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
      home: const SplashScreen(),
    );
  }
}

class ResultadoLote {
  final String nombreArchivo;
  final String diagnostico;
  final double confianza;
  final String nivelConfianza;
  final bool noConcluyente;
  final int tiempoInferencia;

  ResultadoLote({
    required this.nombreArchivo,
    required this.diagnostico,
    required this.confianza,
    required this.nivelConfianza,
    required this.noConcluyente,
    required this.tiempoInferencia,
  });
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const DiagnosticScreen(),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(75),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(75),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/ojocatarata.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Identificador de Cataratas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Universidad Privada Antenor Orrego',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
  bool _loading = false;
  int _ramUsada = 0;

  String _diagnostico = '';
  double _confianza = 0;
  Map<String, double> _probabilidades = {};
  String _nivelConfianza = '';
  bool _noConcluyente = false;
  int _tiempoPreprocesamiento = 0;
  int _tiempoInferencia = 0;
  int _tiempoTotal = 0;
  int _tiempoCarga = 0;
  String _fechaHora = '';
  String _tamanoImagen = '';

  List<ResultadoLote> _resultadosLote = [];
  bool _modoLote = false;
  String _fechaHoraLote = '';
  int _tiempoCargaLote = 0;

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
        _diagnostico = '';
        _modoLote = false;
        _resultadosLote = [];
      });

      _mostrarModalProgreso(mensaje: 'Analizando imagen...', progreso: null);

      final analisis = await _classifier.clasificarRetina(_image!);

      try {
        final int ram = ProcessInfo.currentRss ~/ (1024 * 1024);
        setState(() => _ramUsada = ram);
      } catch (e) {
        debugPrint('Error RAM: $e');
      }

      if (mounted) Navigator.of(context).pop();

      setState(() {
        _diagnostico = analisis['diagnostico'];
        _confianza = analisis['confianza'];
        _probabilidades = Map<String, double>.from(analisis['probabilidades']);
        _nivelConfianza = analisis['nivelConfianza'];
        _noConcluyente = analisis['noConcluyente'];
        _tiempoPreprocesamiento = analisis['tiempoPreprocesamiento'];
        _tiempoInferencia = analisis['tiempoInferencia'];
        _tiempoTotal = analisis['tiempoTotal'];
        _tiempoCarga = analisis['tiempoCarga'];
        _fechaHora = analisis['fechaHora'];
        _tamanoImagen = analisis['tamanoImagen'];
        _loading = false;
      });
    }
  }

  Future<void> _seleccionarLote() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(limit: 50);

    if (pickedFiles.isEmpty) return;

    final String fechaInicio = DateTime.now().toString().substring(0, 19);

    setState(() {
      _loading = true;
      _modoLote = true;
      _diagnostico = '';
      _image = null;
      _resultadosLote = [];
      _fechaHoraLote = fechaInicio;
    });

    final int total = pickedFiles.length;
    final List<ResultadoLote> resultados = [];

    for (int i = 0; i < total; i++) {
      if (!mounted) break;

      _mostrarOActualizarModal(
        mensaje: 'Procesando imagen ${i + 1} de $total...',
        progreso: (i + 1) / total,
        actual: i + 1,
        total: total,
      );

      final archivo = File(pickedFiles[i].path);
      final analisis = await _classifier.clasificarRetina(archivo);

      if (i == 0) {
        setState(() => _tiempoCargaLote = analisis['tiempoCarga']);
      }

      resultados.add(ResultadoLote(
        nombreArchivo: pickedFiles[i].name,
        diagnostico: analisis['diagnostico'],
        confianza: analisis['confianza'],
        nivelConfianza: analisis['nivelConfianza'],
        noConcluyente: analisis['noConcluyente'],
        tiempoInferencia: analisis['tiempoInferencia'],
      ));

      setState(() => _resultadosLote = List.from(resultados));
    }

    if (mounted) Navigator.of(context).pop();

    try {
      final int ram = ProcessInfo.currentRss ~/ (1024 * 1024);
      setState(() => _ramUsada = ram);
    } catch (e) {
      debugPrint('Error RAM: $e');
    }

    setState(() => _loading = false);
  }

  bool _modalAbierto = false;

  void _mostrarModalProgreso({required String mensaje, required double? progreso}) {
    if (_modalAbierto) return;
    _modalAbierto = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ModalProgreso(mensaje: mensaje, progreso: progreso),
    ).then((_) => _modalAbierto = false);
  }

  void _mostrarOActualizarModal({
    required String mensaje,
    required double progreso,
    required int actual,
    required int total,
  }) {
    if (!_modalAbierto) {
      _modalAbierto = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            _actualizarModal = setModalState;
            _mensajeModal = mensaje;
            _progresoModal = progreso;
            _actualModal = actual;
            _totalModal = total;
            return _buildModalLote();
          },
        ),
      ).then((_) => _modalAbierto = false);
    } else {
      if (_actualizarModal != null) {
        _actualizarModal!(() {
          _mensajeModal = mensaje;
          _progresoModal = progreso;
          _actualModal = actual;
          _totalModal = total;
        });
      }
    }
  }

  StateSetter? _actualizarModal;
  String _mensajeModal = '';
  double _progresoModal = 0;
  int _actualModal = 0;
  int _totalModal = 0;

  Widget _buildModalLote() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_search, size: 48, color: Colors.teal),
            const SizedBox(height: 16),
            Text(
              _mensajeModal,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progresoModal,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_actualModal / $_totalModal imágenes',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _eliminarImagen() {
    setState(() {
      _image = null;
      _diagnostico = '';
      _confianza = 0;
      _probabilidades = {};
      _nivelConfianza = '';
      _noConcluyente = false;
      _tiempoPreprocesamiento = 0;
      _tiempoInferencia = 0;
      _tiempoTotal = 0;
      _ramUsada = 0;
      _fechaHora = '';
      _tamanoImagen = '';
      _resultadosLote = [];
      _modoLote = false;
      _fechaHoraLote = '';
      _tiempoCargaLote = 0;
    });
  }

  Color _colorConfianza(String nivel) {
    if (nivel == 'Alta') return Colors.green;
    if (nivel == 'Moderada') return Colors.orange;
    return Colors.red;
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
              if (!_modoLote)
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
                            Icon(Icons.remove_red_eye_outlined, size: 80, color: Colors.teal),
                            SizedBox(height: 10),
                            Text('No hay imagen cargada', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),

              if (!_modoLote) const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _seleccionarImagen,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Cargar imagen', style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _seleccionarLote,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Cargar lote', style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: (_image != null || _resultadosLote.isNotEmpty) && !_loading
                        ? _eliminarImagen
                        : null,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Limpiar', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (!_modoLote && _diagnostico.isNotEmpty) ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                        const Divider(height: 25),
                        Text('Resultado:', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(
                          _diagnostico,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _diagnostico.contains('Normal') ? Colors.green : Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('Confianza: ', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                            Text(
                              '${_confianza.toStringAsFixed(2)}%',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _colorConfianza(_nivelConfianza)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _colorConfianza(_nivelConfianza).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _colorConfianza(_nivelConfianza)),
                              ),
                              child: Text(_nivelConfianza,
                                  style: TextStyle(fontSize: 12, color: _colorConfianza(_nivelConfianza))),
                            ),
                          ],
                        ),
                        if (_noConcluyente) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Resultado no concluyente. Se recomienda evaluar otra imagen.',
                                    style: TextStyle(fontSize: 13, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text('Probabilidades:', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        ...(_probabilidades.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value)))
                            .map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(entry.key, style: const TextStyle(fontSize: 13)),
                                          Text('${entry.value.toStringAsFixed(2)}%',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: entry.value / 100,
                                          minHeight: 8,
                                          backgroundColor: Colors.grey[200],
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            entry.key == _diagnostico
                                                ? Colors.teal
                                                : Colors.teal.withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.analytics_outlined, color: Colors.teal),
                            SizedBox(width: 10),
                            Text('Panel Técnico',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                        const Divider(height: 25),
                        _filaTecnica('Modelo', 'MobileNetV2 – TFLite v1.0', Icons.model_training),
                        _filaTecnica('Backend', 'CPU', Icons.memory),
                        _filaTecnica('Fecha y hora', _fechaHora, Icons.access_time),
                        _filaTecnica('Tamaño imagen', _tamanoImagen, Icons.photo_size_select_large),
                        _filaTecnica('Carga del modelo', '$_tiempoCarga ms', Icons.download_outlined),
                        _filaTecnica('Preprocesamiento', '$_tiempoPreprocesamiento ms', Icons.tune),
                        _filaTecnica('Inferencia', '$_tiempoInferencia ms', Icons.speed),
                        _filaTecnica('Tiempo total', '$_tiempoTotal ms', Icons.timer_outlined),
                        _filaTecnica('RAM utilizada', '$_ramUsada MB', Icons.storage),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: _tiempoTotal <= 200 ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _tiempoTotal <= 200
                                  ? 'Latencia dentro del umbral (< 200ms)'
                                  : 'Latencia fuera del umbral (> 200ms)',
                              style: TextStyle(
                                fontSize: 13,
                                color: _tiempoTotal <= 200 ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_modoLote && _resultadosLote.isNotEmpty) ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.batch_prediction, color: Colors.teal),
                            const SizedBox(width: 10),
                            Text(
                              'Resultados del lote (${_resultadosLote.length} imágenes)',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ],
                        ),
                        const Divider(height: 25),
                        _resumenLote(),
                        const SizedBox(height: 16),
                        const Text('Detalle por imagen:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._resultadosLote.asMap().entries.map((entry) {
                          final i = entry.key;
                          final r = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text('${i + 1}',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.nombreArchivo,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        r.diagnostico,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: r.diagnostico.contains('Normal') ? Colors.green : Colors.red[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${r.confianza.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _colorConfianza(r.nivelConfianza),
                                      ),
                                    ),
                                    Text(
                                      '${r.tiempoInferencia} ms',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.analytics_outlined, color: Colors.teal),
                            SizedBox(width: 10),
                            Text('Panel Técnico – Lote',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                        const Divider(height: 25),
                        _filaTecnica('Modelo', 'MobileNetV2 – TFLite v1.0', Icons.model_training),
                        _filaTecnica('Backend', 'CPU', Icons.memory),
                        _filaTecnica('Fecha y hora', _fechaHoraLote, Icons.access_time),
                        _filaTecnica('Total de imágenes', '${_resultadosLote.length}', Icons.photo_library_outlined),
                        _filaTecnica('Carga del modelo', '$_tiempoCargaLote ms', Icons.download_outlined),
                        _filaTecnica('Inferencia promedio', '${_resultadosLote.isEmpty ? 0 : (_resultadosLote.map((r) => r.tiempoInferencia).reduce((a, b) => a + b) / _resultadosLote.length).round()} ms', Icons.speed),
                        _filaTecnica('Inferencia total', '${_resultadosLote.map((r) => r.tiempoInferencia).fold(0, (a, b) => a + b)} ms', Icons.timer_outlined),
                        _filaTecnica('RAM utilizada', '$_ramUsada MB', Icons.storage),
                        const SizedBox(height: 8),
                        Builder(builder: (context) {
                          final promedio = _resultadosLote.isEmpty
                              ? 0
                              : (_resultadosLote.map((r) => r.tiempoInferencia).reduce((a, b) => a + b) / _resultadosLote.length).round();
                          return Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 18,
                                color: promedio <= 200 ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                promedio <= 200
                                    ? 'Inferencia promedio dentro del umbral (< 200ms)'
                                    : 'Inferencia promedio fuera del umbral (> 200ms)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: promedio <= 200 ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],

              if (!_loading && !_modoLote && _diagnostico.isEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                        const Divider(height: 25),
                        Text(
                          'Seleccione una imagen para iniciar el análisis.',
                          style: TextStyle(fontSize: 15, color: Colors.grey[500]),
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

  Widget _resumenLote() {
    final Map<String, int> conteo = {};
    int noConcluyentes = 0;
    int tiempoTotalMs = 0;

    for (final r in _resultadosLote) {
      conteo[r.diagnostico] = (conteo[r.diagnostico] ?? 0) + 1;
      if (r.noConcluyente) noConcluyentes++;
      tiempoTotalMs += r.tiempoInferencia;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resumen:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...conteo.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: const TextStyle(fontSize: 13)),
                  Text('${e.value} imagen${e.value > 1 ? 'es' : ''}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
        if (noConcluyentes > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'No concluyentes: $noConcluyentes',
              style: const TextStyle(fontSize: 13, color: Colors.red),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Tiempo total de inferencia: $tiempoTotalMs ms',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Text(
          'RAM utilizada: $_ramUsada MB',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _filaTecnica(String label, String valor, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icono, size: 18, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
          Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ModalProgreso extends StatelessWidget {
  final String mensaje;
  final double? progreso;

  const _ModalProgreso({required this.mensaje, required this.progreso});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_search, size: 48, color: Colors.teal),
            const SizedBox(height: 16),
            Text(
              mensaje,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}