import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class CatarataClassifier {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  int _tiempoCarga = 0;

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
      final sw = Stopwatch()..start();
      _interpreter = await Interpreter.fromAsset('assets/modelo_catarata.tflite');
      sw.stop();
      _tiempoCarga = sw.elapsedMilliseconds;
      _isModelLoaded = true;
    } catch (e) {
      _isModelLoaded = false;
    }
  }

  Future<Map<String, dynamic>> clasificarRetina(File imageFile) async {
    if (!_isModelLoaded || _interpreter == null) {
      return {
        'diagnostico': 'Modelo no inicializado',
        'confianza': 0.0,
        'probabilidades': <String, double>{},
        'nivelConfianza': '',
        'noConcluyente': false,
        'tiempoPreprocesamiento': 0,
        'tiempoInferencia': 0,
        'tiempoTotal': 0,
        'tiempoCarga': _tiempoCarga,
        'fechaHora': DateTime.now().toString(),
        'tamanoImagen': '',
      };
    }

    final swTotal = Stopwatch()..start();
    final swPre = Stopwatch()..start();

    final Uint8List imageBytes = await imageFile.readAsBytes();
    final img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      return {
        'diagnostico': 'Error al procesar la imagen',
        'confianza': 0.0,
        'probabilidades': <String, double>{},
        'nivelConfianza': '',
        'noConcluyente': false,
        'tiempoPreprocesamiento': 0,
        'tiempoInferencia': 0,
        'tiempoTotal': 0,
        'tiempoCarga': _tiempoCarga,
        'fechaHora': DateTime.now().toString(),
        'tamanoImagen': '',
      };
    }

    final String tamanoImagen = '${originalImage.width} x ${originalImage.height} px';
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

    swPre.stop();
    final int tiempoPreprocesamiento = swPre.elapsedMilliseconds;

    var output = List.filled(1, List.filled(4, 0.0));

    final swInf = Stopwatch()..start();
    _interpreter!.run(input, output);
    swInf.stop();
    swTotal.stop();

    final int tiempoInferencia = swInf.elapsedMilliseconds;
    final int tiempoTotal = swTotal.elapsedMilliseconds;

    List<double> probabilidades = output[0];

    int maxIndex = 0;
    double maxProb = -1.0;
    for (int i = 0; i < probabilidades.length; i++) {
      if (probabilidades[i] > maxProb) {
        maxProb = probabilidades[i];
        maxIndex = i;
      }
    }

    final Map<String, double> probMap = {};
    for (int i = 0; i < labels.length; i++) {
      probMap[labels[i]] = probabilidades[i] * 100;
    }

    final double confianza = maxProb * 100;
    String nivelConfianza;
    bool noConcluyente;

    if (confianza >= 90) {
      nivelConfianza = 'Alta';
      noConcluyente = false;
    } else if (confianza >= 70) {
      nivelConfianza = 'Moderada';
      noConcluyente = false;
    } else {
      nivelConfianza = 'Baja';
      noConcluyente = true;
    }

    return {
      'diagnostico': labels[maxIndex],
      'confianza': confianza,
      'probabilidades': probMap,
      'nivelConfianza': nivelConfianza,
      'noConcluyente': noConcluyente,
      'tiempoPreprocesamiento': tiempoPreprocesamiento,
      'tiempoInferencia': tiempoInferencia,
      'tiempoTotal': tiempoTotal,
      'tiempoCarga': _tiempoCarga,
      'fechaHora': DateTime.now().toString().substring(0, 19),
      'tamanoImagen': tamanoImagen,
    };
  }

  void close() {
    _interpreter?.close();
  }
}