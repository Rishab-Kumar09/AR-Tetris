import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  final ValueNotifier<CameraImage?> currentFrame =
      ValueNotifier<CameraImage?>(null);
  bool _isProcessing = false;
  int _frameSkipCount = 0;
  static const int _frameSkipTarget = 1; // Process every other frame

  // Initialize camera
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('Camera service not supported on web platform');
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return;
      }

      // Find front camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();

      // Start image stream
      await _controller!.startImageStream((image) {
        if (_frameSkipCount >= _frameSkipTarget) {
          if (!_isProcessing) {
            _isProcessing = true;
            currentFrame.value = image;
            _isProcessing = false;
          }
          _frameSkipCount = 0;
        } else {
          _frameSkipCount++;
        }
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  // Get camera controller
  CameraController? get controller => _controller;

  // Dispose resources
  void dispose() {
    _controller?.dispose();
  }
}
