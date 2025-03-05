import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:math';

class HandTrackingService {
  // Value notifiers for hand position and debug info
  final ValueNotifier<Offset> handPosition = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<bool> isPunchGesture = ValueNotifier<bool>(false);
  final ValueNotifier<String> debugInfo =
      ValueNotifier<String>('Initializing hand tracking...');

  // Processing state
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _lastPunchState = false;
  DateTime _lastPunchTime = DateTime.now();
  static const int _punchCooldownMs = 300;

  // Smoothing variables
  final List<Offset> _positionHistory = [];
  final int _historySize = 3;
  Offset? _lastValidPosition;
  int _invalidPositionCount = 0;
  final int _maxInvalidPositions = 3;

  // Hand detection parameters
  static const double _brightnessFactor = 0.65;
  static const double _faceRegionThreshold = 0.35;
  static const double _minMovement = 0.01;
  static const double _maxMovement = 0.2;

  // Initialize hand tracking
  Future<void> initialize() async {
    if (kIsWeb) {
      debugInfo.value = 'Hand tracking not supported on web platform';
      return;
    }

    try {
      _isInitialized = true;
      debugInfo.value = 'Hand tracking initialized';
    } catch (e) {
      debugInfo.value = 'Failed to initialize hand tracking: $e';
      if (kDebugMode) {
        print('Error initializing hand tracking: $e');
      }
    }
  }

  // Process camera image
  Future<void> processImage(CameraImage image) async {
    if (!_isInitialized || _isProcessing) {
      return;
    }

    _isProcessing = true;

    try {
      final yPlane = image.planes[0].bytes;
      final width = image.width;
      final height = image.height;
      final bytesPerRow = image.planes[0].bytesPerRow;

      const gridSize = 8;
      final cellWidth = width ~/ gridSize;
      final cellHeight = height ~/ gridSize;

      var maxBrightness = 0.0;
      var brightestX = width ~/ 2;
      var brightestY = height ~/ 2;

      // Find the brightest point (excluding face region)
      for (int gridY = (gridSize * _faceRegionThreshold).toInt();
          gridY < gridSize;
          gridY++) {
        for (int gridX = 0; gridX < gridSize; gridX++) {
          var totalBrightness = 0.0;
          var samples = 0;

          for (int y = gridY * cellHeight;
              y < (gridY + 1) * cellHeight;
              y += 4) {
            for (int x = gridX * cellWidth;
                x < (gridX + 1) * cellWidth;
                x += 4) {
              final idx = y * bytesPerRow + x;
              if (idx < yPlane.length) {
                totalBrightness += yPlane[idx];
                samples++;
              }
            }
          }

          if (samples > 0) {
            final avgBrightness = totalBrightness / samples;
            if (avgBrightness > maxBrightness) {
              maxBrightness = avgBrightness;
              brightestX = gridX * cellWidth + (cellWidth ~/ 2);
              brightestY = gridY * cellHeight + (cellHeight ~/ 2);
            }
          }
        }
      }

      // Convert to normalized coordinates (mirrored)
      final normalizedX = 1.0 - (brightestX / width);
      final normalizedY = brightestY / height;
      final newPosition = Offset(normalizedX, normalizedY);

      // Validate movement
      bool isValidMovement = true;
      if (_lastValidPosition != null) {
        final movement = (newPosition - _lastValidPosition!).distance;
        if (movement < _minMovement || movement > _maxMovement) {
          isValidMovement = false;
        }
      }

      if (isValidMovement) {
        final smoothedPosition = _smoothPosition(newPosition);
        handPosition.value = smoothedPosition;
        _lastValidPosition = smoothedPosition;
        _invalidPositionCount = 0;
      } else {
        _handleInvalidPosition('Invalid movement detected');
      }
    } catch (e) {
      debugInfo.value = 'Error processing image: $e';
      _handleInvalidPosition('Error processing image');
    } finally {
      _isProcessing = false;
    }
  }

  // Handle invalid position
  void _handleInvalidPosition(String reason) {
    if (kDebugMode && _invalidPositionCount % 10 == 0) {
      debugInfo.value = reason;
    }

    _invalidPositionCount++;

    if (_invalidPositionCount > _maxInvalidPositions) {
      _positionHistory.clear();
      _lastValidPosition = null;
      return;
    }

    if (_lastValidPosition != null) {
      handPosition.value = _lastValidPosition!;
    }
  }

  // Apply smoothing to position
  Offset _smoothPosition(Offset newPosition) {
    _positionHistory.add(newPosition);

    if (_positionHistory.length > _historySize) {
      _positionHistory.removeAt(0);
    }

    if (_positionHistory.length < 2) {
      return newPosition;
    }

    final weight = 0.8;
    final oldWeight = 1.0 - weight;

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
      final newPosition = Offset(x, y);
      final smoothedPosition = _smoothPosition(newPosition);
      handPosition.value = smoothedPosition;
    }
  }

  // Dispose resources
  void dispose() {
    // No resources to dispose in this simplified version
  }
}
