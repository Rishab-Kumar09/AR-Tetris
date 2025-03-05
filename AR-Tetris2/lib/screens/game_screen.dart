import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/game_model.dart';
import '../services/camera_service.dart';
import '../services/hand_tracking_service.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/tetris_grid.dart';
import '../widgets/next_piece_preview.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late CameraService _cameraService;
  late HandTrackingService _handTrackingService;
  bool _isCameraInitialized = false;
  bool _isWebPlatform = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _isWebPlatform = kIsWeb;
    _handTrackingService = HandTrackingService();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    if (!_isWebPlatform) {
      _cameraService = CameraService();
      try {
        await _cameraService.initialize();
        await _handTrackingService.initialize();

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }

        // Process camera frames
        _cameraService.currentFrame.addListener(() {
          if (!mounted) return;
          final frame = _cameraService.currentFrame.value;
          if (frame != null) {
            _handTrackingService.processImage(frame);
          }
        });

        // Update game model with hand position and gestures
        _handTrackingService.handPosition.addListener(() {
          if (!mounted) return;
          final gameModel = Provider.of<GameModel>(context, listen: false);
          final handPosition = _handTrackingService.handPosition.value;
          gameModel.updateHandPosition(handPosition.dx, handPosition.dy);
        });

        // Handle punch gesture for rotation
        _handTrackingService.isPunchGesture.addListener(() {
          if (!mounted) return;
          final gameModel = Provider.of<GameModel>(context, listen: false);
          if (_handTrackingService.isPunchGesture.value) {
            gameModel.handlePunchGesture();
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to initialize camera: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _isWebPlatform) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Stop game and release camera resources when app is inactive or paused
      Provider.of<GameModel>(context, listen: false).stopGame();
      _cleanupResources();
    } else if (state == AppLifecycleState.resumed) {
      // Re-initialize camera when app is resumed
      _initializeServices();
      WakelockPlus.enable();
    }
  }

  void _cleanupResources() {
    if (!_isWebPlatform && _isCameraInitialized) {
      setState(() {
        _isCameraInitialized = false;
      });
      _cameraService.dispose();
      _handTrackingService.dispose();
      WakelockPlus.disable();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized && !_isWebPlatform) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Provider<HandTrackingService>.value(
      value: _handTrackingService,
      child: Scaffold(
        body: _isWebPlatform ? _buildWebGameScreen() : _buildGameScreen(),
      ),
    );
  }

  Widget _buildWebGameScreen() {
    return MouseRegion(
      onHover: (event) {
        final screenSize = MediaQuery.of(context).size;
        final normalizedX = event.position.dx / screenSize.width;
        final normalizedY = event.position.dy / screenSize.height;
        _handTrackingService.setHandPosition(normalizedX, normalizedY);
      },
      child: _buildGameScreen(),
    );
  }

  Widget _buildGameScreen() {
    return Consumer<GameModel>(
      builder: (context, gameModel, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview or background for web
            _isWebPlatform
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.shade900,
                          Colors.purple.shade900,
                        ],
                      ),
                    ),
                  )
                : _isCameraInitialized
                    ? CameraPreviewWidget(
                        cameraService: _cameraService,
                      )
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),

            // Game overlay
            Container(
              color: Colors.black.withOpacity(0.3),
            ),

            // Game grid
            Center(
              child: TetrisGrid(
                grid: gameModel.grid,
                currentPiece: gameModel.currentPiece,
              ),
            ),

            // Hand position dot
            Consumer<HandTrackingService>(
              builder: (context, handTrackingService, child) {
                return ValueListenableBuilder<Offset>(
                  valueListenable: handTrackingService.handPosition,
                  builder: (context, handPosition, child) {
                    final screenSize = MediaQuery.of(context).size;
                    return Stack(
                      children: [
                        // Outer glow
                        Positioned(
                          left: handPosition.dx * screenSize.width - 30,
                          top: handPosition.dy * screenSize.height - 30,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.red.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Main dot
                        Positioned(
                          left: handPosition.dx * screenSize.width - 15,
                          top: handPosition.dy * screenSize.height - 15,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            // Score and next piece overlay
            Positioned(
              top: 40,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Score: ${gameModel.score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Level: ${gameModel.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (gameModel.nextPiece != null) ...[
                    const Text(
                      'Next:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    NextPiecePreview(piece: gameModel.nextPiece!),
                  ],
                ],
              ),
            ),

            // Start/Game Over overlay
            if (!gameModel.isPlaying)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        gameModel.score > 0 ? 'Game Over!' : 'AR Tetris',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (gameModel.score > 0) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Score: ${gameModel.score}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'High Score: ${gameModel.highScore}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () => gameModel.startGame(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                        ),
                        child: Text(
                          gameModel.score > 0 ? 'Play Again' : 'Start Game',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
