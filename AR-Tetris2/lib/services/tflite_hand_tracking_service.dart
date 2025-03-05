import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img_lib;

class TFLiteHandTrackingService {
  // Value notifiers for hand position and debug info
  final ValueNotifier<Offset> handPosition = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<String> debugInfo =
      ValueNotifier<String>('Initializing TFLite hand tracking...');

  // TFLite interpreter
  Interpreter? _interpreter;
  bool _isInitialized = false;
  bool _isProcessing = false;
  int _frameSkipCount = 0;
  final int _frameSkipTarget = 1; // Process every 2nd frame

  // Model parameters
  final int _inputSize = 256; // Input size for the model
  final int _numKeypoints = 21; // Number of hand keypoints

  // Smoothing variables
  final List<Offset> _positionHistory = [];
  final int _historySize = 2;
  Offset? _lastValidPosition;
  int _invalidPositionCount = 0;
  final int _maxInvalidPositions = 3;

  // Initialize TFLite hand tracking
  Future<void> initialize() async {
    if (kIsWeb) {
      debugInfo.value = 'TFLite hand tracking not supported on web platform';
      return;
    }

    try {
      // Load the TFLite model
      final options = InterpreterOptions();

      // Use GPU delegate if available
      if (Platform.isAndroid) {
        options.addDelegate(GpuDelegateV2());
      } else if (Platform.isIOS) {
        options.addDelegate(GpuDelegate());
      }

      // Set number of threads for CPU
      options.threads = 4;

      // Load the model
      _interpreter = await Interpreter.fromAsset(
        'assets/models/hand_landmark.tflite',
        options: options,
      );

      _isInitialized = true;
      debugInfo.value = 'TFLite hand tracking initialized';
    } catch (e) {
      debugInfo.value = 'Failed to initialize TFLite: $e';
      if (kDebugMode) {
        print('Error initializing TFLite: $e');
      }
    }
  }

  // Process camera image
  @override
  Future<void> processImage(CameraImage cameraImage) async {
    if (!_isInitialized) {
      debugInfo.value = 'TFLite hand tracking not initialized';
      return;
    }

    try {
      // Skip processing if we're already processing an image
      if (_isProcessing) {
        return;
      }
      _isProcessing = true;

      // Convert camera image to input format for TFLite
      final inputImage = _preprocessCameraImage(cameraImage);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      // Run inference
      if (_interpreter == null) {
        debugInfo.value = 'Interpreter is null';
        _isProcessing = false;
        return;
      }

      // Prepare input and output tensors
      final input = [inputImage];
      final output = {
        0: [
          List<List<double>>.filled(
            21,
            List<double>.filled(3, 0.0),
          )
        ]
      };

      // Run inference
      _interpreter!.runForMultipleInputs(input, output);

      // Process outputs
      final landmarks = output[0]![0];

      // Check if hand is detected with sufficient confidence
      bool handDetected = false;
      double avgConfidence = 0;

      for (var landmark in landmarks) {
        avgConfidence += landmark[2];
      }
      avgConfidence /= landmarks.length;

      handDetected =
          avgConfidence > 0.2; // Lower threshold for better responsiveness

      if (handDetected) {
        // Use index finger tip (landmark 8) for tracking
        final indexTip = landmarks[8];

        // Normalize coordinates to 0-1 range
        // Flip x-coordinate since camera is mirrored
        double normalizedX = 1.0 - indexTip[0];
        double normalizedY = indexTip[1];

        // Update hand position immediately without smoothing
        handPosition.value = Offset(normalizedX, normalizedY);

        debugInfo.value =
            'Hand detected: ${normalizedX.toStringAsFixed(2)}, ${normalizedY.toStringAsFixed(2)}';
      } else {
        debugInfo.value = 'No hand detected';
      }

      _isProcessing = false;
    } catch (e) {
      debugInfo.value = 'Error processing image: $e';
      _isProcessing = false;
    }
  }

  // Preprocess camera image for TFLite
  List<List<List<double>>>? _preprocessCameraImage(CameraImage image) {
    try {
      // Convert YUV to RGB
      final img = _convertYUV420ToImage(image);
      if (img == null) return null;

      // Resize to input size
      final resizedImg = img_lib.copyResize(
        img,
        width: _inputSize,
        height: _inputSize,
      );

      // Convert to normalized float values
      final inputData = List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resizedImg.getPixel(x, y);
            // For image library 4.5.3, we need to use the rgba getters
            final r = pixel.r / 255.0;
            final g = pixel.g / 255.0;
            final b = pixel.b / 255.0;
            return [r, g, b];
          },
        ),
      );

      return inputData;
    } catch (e) {
      if (kDebugMode) {
        print('Error preprocessing image: $e');
      }
      return null;
    }
  }

  // Convert YUV420 format to RGB Image
  img_lib.Image? _convertYUV420ToImage(CameraImage image) {
    try {
      final width = image.width;
      final height = image.height;

      // Create output image
      final rgbImage = img_lib.Image(width: width, height: height);

      // Get image planes
      final yPlane = image.planes[0].bytes;
      final uPlane = image.planes[1].bytes;
      final vPlane = image.planes[2].bytes;

      final yRowStride = image.planes[0].bytesPerRow;
      final uvRowStride = image.planes[1].bytesPerRow;
      final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

      // Convert YUV to RGB
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yIndex = y * yRowStride + x;
          final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

          // YUV to RGB conversion
          int Y = yPlane[yIndex];
          final U = uPlane[uvIndex];
          final V = vPlane[uvIndex];

          // Convert YUV to RGB
          final r = max(0, min(255, (Y + 1.402 * (V - 128)).toInt()));
          final g = max(
              0,
              min(255,
                  (Y - 0.344136 * (U - 128) - 0.714136 * (V - 128)).toInt()));
          final b = max(0, min(255, (Y + 1.772 * (U - 128)).toInt()));

          // Set pixel in output image
          rgbImage.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      return rgbImage;
    } catch (e) {
      if (kDebugMode) {
        print('Error converting YUV to RGB: $e');
      }
      return null;
    }
  }

  // Handle invalid position
  void _handleInvalidPosition(String reason) {
    // Only update debug info occasionally to reduce overhead
    if (kDebugMode && _invalidPositionCount % 10 == 0) {
      debugInfo.value = reason;
    }

    _invalidPositionCount++;

    // If we've had too many consecutive invalid positions, reset
    if (_invalidPositionCount > _maxInvalidPositions) {
      _positionHistory.clear();
      _lastValidPosition = null;
      return;
    }

    // If we have a last valid position, keep using it
    if (_lastValidPosition != null) {
      handPosition.value = _lastValidPosition!;
    }
  }

  // Apply smoothing to position - simplified for faster response
  Offset _smoothPosition(Offset newPosition) {
    // Add new position to history
    _positionHistory.add(newPosition);

    // Keep history at max size
    if (_positionHistory.length > _historySize) {
      _positionHistory.removeAt(0);
    }

    // If we don't have enough history yet, just return the new position
    if (_positionHistory.length < 2) {
      return newPosition;
    }

    // Weighted average with more weight to the newest position
    final weight = 0.7; // 70% weight to newest position
    final oldWeight = 1.0 - weight;

    // Calculate weighted average
    final latest = _positionHistory.last;
    final previous = _positionHistory.first;

    return Offset(
      latest.dx * weight + previous.dx * oldWeight,
      latest.dy * weight + previous.dy * oldWeight,
    );
  }

  // Method to manually set hand position (used for web)
  void setHandPosition(double x, double y) {
    if (kIsWeb) {
      // For web, apply minimal smoothing for faster response
      final newPosition = Offset(x, y);
      final smoothedPosition = _smoothPosition(newPosition);

      handPosition.value = smoothedPosition;

      // Update debug info less frequently
      if (kDebugMode && DateTime.now().millisecondsSinceEpoch % 500 < 100) {
        debugInfo.value =
            'Web hand position: (${smoothedPosition.dx.toStringAsFixed(2)}, ${smoothedPosition.dy.toStringAsFixed(2)})';
      }
    }
  }

  // Dispose resources
  void dispose() {
    _interpreter?.close();
  }
}
