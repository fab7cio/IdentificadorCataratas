import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class CatarataClassifier {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  final List<String> labels = [
    'Catarata Cortical',
    'Normal',
    'Catarata Nuclear',
    'Catarata Subcapsular',
  ];

  CatarataClassifier() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/modelo_catarata.tflite');
      _isModelLoaded = true;
      print("¡Modelo cargado con éxito en Flutter!"); //ignore: avoid_print
    } catch (e) {
      print("Error al cargar el modelo tflite: $e"); // ignore: avoid_print
    }
  }

  Future<Map<String, dynamic>> clasificarRetina(File imageFile) async {
    if (!_isModelLoaded || _interpreter == null) {
      return {'resultado': 'Modelo no inicializado', 'latencia': 0};
    }

    final Uint8List imageBytes = await imageFile.readAsBytes();
    final img.Image? originalImage = img.decodeImage(imageBytes);
    
    if (originalImage == null) {
      return {'resultado': 'Error al procesar la imagen', 'latencia': 0};
    }

    final img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);

    var input = List.generate(
      1,
      (_) => List.generate(
        224,
        (_) => List.generate(
          224,
          (_) => List.filled(3, 0.0),
        ),
      ),
    );

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resizedImage.getPixel(x, y);
        input[0][y][x][0] = (pixel.r / 255.0 - 0.485) / 0.229;
        input[0][y][x][1] = (pixel.g / 255.0 - 0.456) / 0.224;
        input[0][y][x][2] = (pixel.b / 255.0 - 0.406) / 0.225;
      }
    }

    var output = List.filled(1, List.filled(4, 0.0));

    final stopwatch = Stopwatch()..start();
  
    _interpreter!.run(input, output);
    
    stopwatch.stop();
    final int latencia = stopwatch.elapsedMilliseconds;

    List<double> probabilidades = output[0];
    
    int maxIndex = 0;
    double maxProb = -1.0;
    for (int i = 0; i < probabilidades.length; i++) {
      if (probabilidades[i] > maxProb) {
        maxProb = probabilidades[i];
        maxIndex = i;
      }
    }

    String diagnosticoFinal = labels[maxIndex];
    double porcentajeCerteza = maxProb * 100;

    return {
      'resultado': '$diagnosticoFinal (${porcentajeCerteza.toStringAsFixed(2)}%)',
      'latencia': latencia
    };
  }

  void close() {
    _interpreter?.close();
  }
}