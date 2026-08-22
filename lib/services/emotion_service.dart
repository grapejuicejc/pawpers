import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class EmotionResult {
  final String petType;
  final String emotion;
  final double confidence;

  EmotionResult({
    required this.petType,
    required this.emotion,
    required this.confidence,
  });
}

class EmotionService {
  static Interpreter? _catInterpreter;
  static Interpreter? _dogInterpreter;

  static const List<String> catClasses = [
    'aggressive',
    'sad',
    'happy',
    'relaxed',
  ];

  static const List<String> dogClasses = [
    'angry',
    'sad',
    'happy',
    'relaxed',
  ];

  static Future<void> initialize() async {
    _catInterpreter = await Interpreter.fromAsset(
      'assets/models/cat_emotion_resnet50v2.tflite',
    );

    _dogInterpreter = await Interpreter.fromAsset(
      'assets/models/dog_emotion_resnet50v2.tflite',
    );
  }

  static Future<EmotionResult> analyzePetEmotion({
    required File image,
    required String petType,
  }) async {
    final type = petType.toLowerCase();

    final interpreter =
        type == 'cat'
            ? _catInterpreter
            : type == 'dog'
                ? _dogInterpreter
                : null;

    if (interpreter == null) {
      throw Exception('Invalid pet type or model not initialized.');
    }

    final bytes = await image.readAsBytes();

    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw Exception('Unable to read image.');
    }

    // Resize to the same size used during training.
    final resizedImage = img.copyResize(
      decodedImage,
      width: 299,
      height: 299,
    );

    // Create float32 input: [1, 299, 299, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        299,
        (y) => List.generate(
          299,
          (x) {
            final pixel = resizedImage.getPixel(x, y);

            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    // Output shape: [1, 4]
    final output = List.generate(
      1,
      (_) => List.filled(4, 0.0),
    );

    interpreter.run(input, output);

    final predictions = output[0];

    int predictedIndex = 0;

    for (int i = 1; i < predictions.length; i++) {
      if (predictions[i] > predictions[predictedIndex]) {
        predictedIndex = i;
      }
    }

    final classes = type == 'cat' ? catClasses : dogClasses;

    String emotion = classes[predictedIndex];

    // Normalize cat aggressive → angry
    if (emotion == 'aggressive') {
      emotion = 'angry';
    }

    return EmotionResult(
      petType: type,
      emotion: emotion,
      confidence: predictions[predictedIndex],
    );
  }
}