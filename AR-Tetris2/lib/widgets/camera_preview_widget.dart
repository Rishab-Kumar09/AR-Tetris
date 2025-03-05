import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraService cameraService;

  const CameraPreviewWidget({
    Key? key,
    required this.cameraService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize!.height,
            height: controller.value.previewSize!.width,
            child: CameraPreview(
              controller,
              child: ConstrainedBox(
                constraints: const BoxConstraints.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
