import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Tetris piece shapes
enum TetrisShape {
  I,
  O,
  T,
  S,
  Z,
  J,
  L,
}

// Tetris piece rotations
class TetrisPiece {
  final TetrisShape shape;
  final Color color;
  int rotation; // 0, 1, 2, or 3 for 0°, 90°, 180°, 270°
  int x; // Grid position X
  int y; // Grid position Y

  TetrisPiece({
    required this.shape,
    required this.color,
    this.rotation = 0,
    this.x = 0,
    this.y = 0,
  });

  // Get the blocks that make up this piece in its current rotation
  List<List<int>> get blocks {
    switch (shape) {
      case TetrisShape.I:
        switch (rotation % 4) {
          case 0:
            return [
              [0, 0, 0, 0],
              [1, 1, 1, 1],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
            ];
          case 1:
            return [
              [0, 0, 1, 0],
              [0, 0, 1, 0],
              [0, 0, 1, 0],
              [0, 0, 1, 0],
            ];
          case 2:
            return [
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [1, 1, 1, 1],
              [0, 0, 0, 0],
            ];
          case 3:
            return [
              [0, 1, 0, 0],
              [0, 1, 0, 0],
              [0, 1, 0, 0],
              [0, 1, 0, 0],
            ];
        }
        return [];

      case TetrisShape.O:
        return [
          [1, 1],
          [1, 1],
        ];

      case TetrisShape.T:
        switch (rotation % 4) {
          case 0:
            return [
              [0, 1, 0],
              [1, 1, 1],
              [0, 0, 0],
            ];
          case 1:
            return [
              [0, 1, 0],
              [0, 1, 1],
              [0, 1, 0],
            ];
          case 2:
            return [
              [0, 0, 0],
              [1, 1, 1],
              [0, 1, 0],
            ];
          case 3:
            return [
              [0, 1, 0],
              [1, 1, 0],
              [0, 1, 0],
            ];
        }
        return [];

      case TetrisShape.S:
        switch (rotation % 2) {
          case 0:
            return [
              [0, 1, 1],
              [1, 1, 0],
              [0, 0, 0],
            ];
          case 1:
            return [
              [0, 1, 0],
              [0, 1, 1],
              [0, 0, 1],
            ];
        }
        return [];

      case TetrisShape.Z:
        switch (rotation % 2) {
          case 0:
            return [
              [1, 1, 0],
              [0, 1, 1],
              [0, 0, 0],
            ];
          case 1:
            return [
              [0, 0, 1],
              [0, 1, 1],
              [0, 1, 0],
            ];
        }
        return [];

      case TetrisShape.J:
        switch (rotation % 4) {
          case 0:
            return [
              [1, 0, 0],
              [1, 1, 1],
              [0, 0, 0],
            ];
          case 1:
            return [
              [0, 1, 1],
              [0, 1, 0],
              [0, 1, 0],
            ];
          case 2:
            return [
              [0, 0, 0],
              [1, 1, 1],
              [0, 0, 1],
            ];
          case 3:
            return [
              [0, 1, 0],
              [0, 1, 0],
              [1, 1, 0],
            ];
        }
        return [];

      case TetrisShape.L:
        switch (rotation % 4) {
          case 0:
            return [
              [0, 0, 1],
              [1, 1, 1],
              [0, 0, 0],
            ];
          case 1:
            return [
              [0, 1, 0],
              [0, 1, 0],
              [0, 1, 1],
            ];
          case 2:
            return [
              [0, 0, 0],
              [1, 1, 1],
              [1, 0, 0],
            ];
          case 3:
            return [
              [1, 1, 0],
              [0, 1, 0],
              [0, 1, 0],
            ];
        }
        return [];
    }
  }
}

class GameModel extends ChangeNotifier {
  // Game state
  bool _isPlaying = false;
  int _score = 0;
  int _highScore = 0;
  int _level = 1;
  int _linesCleared = 0;
  static const int _gridWidth = 10;
  static const int _gridHeight = 20;
  late List<List<Color?>> _grid = List.generate(
    _gridHeight,
    (y) => List.generate(_gridWidth, (x) => null),
  );
  TetrisPiece? _currentPiece;
  TetrisPiece? _nextPiece;
  Timer? _gameTimer;
  final Random _random = Random();

  // Game settings
  final Map<TetrisShape, Color> _pieceColors = {
    TetrisShape.I: Colors.cyan,
    TetrisShape.O: Colors.yellow,
    TetrisShape.T: Colors.purple,
    TetrisShape.S: Colors.green,
    TetrisShape.Z: Colors.red,
    TetrisShape.J: Colors.blue,
    TetrisShape.L: Colors.orange,
  };

  // Hand tracking
  double _lastHandX = 0.5;
  double _lastHandY = 0.5;
  bool _isRotating = false;
  DateTime _lastMoveTime = DateTime.now();
  DateTime _lastDropTime = DateTime.now();
  static const double _leftThreshold = 0.35; // Left side of screen
  static const double _rightThreshold = 0.65; // Right side of screen
  static const double _dropThreshold = 0.7; // Bottom area for dropping
  static const double _rotateThreshold = 0.3; // Top area for rotation
  static const int _moveDelayMs = 150;
  static const int _dropDelayMs = 250;
  static const int _rotateDelayMs = 300;

  // Getters
  bool get isPlaying => _isPlaying;
  int get score => _score;
  int get highScore => _highScore;
  int get level => _level;
  List<List<Color?>> get grid => _grid;
  TetrisPiece? get currentPiece => _currentPiece;
  TetrisPiece? get nextPiece => _nextPiece;

  // Start the game
  void startGame() {
    if (_isPlaying) return;

    _isPlaying = true;
    _score = 0;
    _level = 1;
    _linesCleared = 0;
    _lastHandX = 0.5;
    _lastHandY = 0.5;
    _isRotating = false;

    // Initialize empty grid
    _grid = List.generate(
      _gridHeight,
      (y) => List.generate(_gridWidth, (x) => null),
    );

    // Spawn first piece
    _spawnNewPiece();

    // Start game timer
    _startGameTimer();

    notifyListeners();
  }

  // Stop the game
  void stopGame() {
    if (!_isPlaying) return;
    _endGame();
  }

  // End the game
  void _endGame() {
    _isPlaying = false;
    _gameTimer?.cancel();

    // Update high score
    if (_score > _highScore) {
      _highScore = _score;
    }

    notifyListeners();
  }

  // Start game timer
  void _startGameTimer() {
    _gameTimer?.cancel();

    // Calculate drop interval based on level (2.5x slower)
    final dropInterval = max(250, 2500 - (_level * 125)); // ms between drops

    _gameTimer = Timer.periodic(Duration(milliseconds: dropInterval), (timer) {
      if (!_isPlaying) return;
      _dropPiece();
    });
  }

  // Spawn a new piece
  void _spawnNewPiece() {
    // Use next piece if available, otherwise create new
    _currentPiece = _nextPiece ?? _createRandomPiece();
    _nextPiece = _createRandomPiece();

    // Position at top center
    _currentPiece!.x = (_gridWidth - _currentPiece!.blocks[0].length) ~/ 2;
    _currentPiece!.y = 0;

    // Check for game over
    if (!_canMovePiece(_currentPiece!, 0, 0)) {
      _endGame();
      return;
    }

    notifyListeners();
  }

  // Create a random piece
  TetrisPiece _createRandomPiece() {
    final shape =
        TetrisShape.values[_random.nextInt(TetrisShape.values.length)];
    return TetrisPiece(
      shape: shape,
      color: _pieceColors[shape]!,
    );
  }

  // Check if piece can move to new position
  bool _canMovePiece(TetrisPiece piece, int deltaX, int deltaY) {
    final blocks = piece.blocks;
    for (int y = 0; y < blocks.length; y++) {
      for (int x = 0; x < blocks[y].length; x++) {
        if (blocks[y][x] == 1) {
          final newX = piece.x + x + deltaX;
          final newY = piece.y + y + deltaY;

          // Check bounds
          if (newX < 0 || newX >= _gridWidth || newY >= _gridHeight) {
            return false;
          }

          // Check collision with placed pieces
          if (newY >= 0 && _grid[newY][newX] != null) {
            return false;
          }
        }
      }
    }
    return true;
  }

  // Drop piece one step
  void _dropPiece() {
    if (!_isPlaying || _currentPiece == null) return;

    if (_canMovePiece(_currentPiece!, 0, 1)) {
      _currentPiece!.y++;
      notifyListeners();
    } else {
      _placePiece();
      _clearLines();
      _spawnNewPiece();
    }
  }

  // Place piece on grid
  void _placePiece() {
    final blocks = _currentPiece!.blocks;
    for (int y = 0; y < blocks.length; y++) {
      for (int x = 0; x < blocks[y].length; x++) {
        if (blocks[y][x] == 1) {
          final gridY = _currentPiece!.y + y;
          final gridX = _currentPiece!.x + x;
          if (gridY >= 0 &&
              gridY < _gridHeight &&
              gridX >= 0 &&
              gridX < _gridWidth) {
            _grid[gridY][gridX] = _currentPiece!.color;
          }
        }
      }
    }
  }

  // Clear completed lines
  void _clearLines() {
    int linesCleared = 0;

    for (int y = _gridHeight - 1; y >= 0; y--) {
      if (_grid[y].every((cell) => cell != null)) {
        // Move all lines above down
        for (int moveY = y; moveY > 0; moveY--) {
          _grid[moveY] = List.from(_grid[moveY - 1]);
        }
        // Clear top line
        _grid[0] = List.generate(_gridWidth, (x) => null);
        linesCleared++;
        y++; // Check same line again as lines have moved down
      }
    }

    if (linesCleared > 0) {
      _linesCleared += linesCleared;
      _score += _calculateScore(linesCleared);
      _level = (_linesCleared ~/ 10) + 1;
      _startGameTimer(); // Update game speed
      notifyListeners();
    }
  }

  // Calculate score for cleared lines
  int _calculateScore(int lines) {
    switch (lines) {
      case 1:
        return 100 * _level;
      case 2:
        return 300 * _level;
      case 3:
        return 500 * _level;
      case 4:
        return 800 * _level;
      default:
        return 0;
    }
  }

  // Update hand position
  void updateHandPosition(double x, double y) {
    if (!_isPlaying || _currentPiece == null) return;

    final now = DateTime.now();

    // Handle movement based on hand position
    if (now.difference(_lastMoveTime).inMilliseconds > _moveDelayMs) {
      if (x < _leftThreshold) {
        // Move left when hand is on the left side
        if (_canMovePiece(_currentPiece!, 1, 0)) {
          _currentPiece!.x++;
          _lastMoveTime = now;
          notifyListeners();
        }
      } else if (x > _rightThreshold) {
        // Move right when hand is on the right side
        if (_canMovePiece(_currentPiece!, -1, 0)) {
          _currentPiece!.x--;
          _lastMoveTime = now;
          notifyListeners();
        }
      }
    }

    // Handle dropping when hand is in the bottom area
    if (y > _dropThreshold &&
        now.difference(_lastDropTime).inMilliseconds > _dropDelayMs) {
      _dropPiece();
      _lastDropTime = now;
    }

    _lastHandX = x;
    _lastHandY = y;
  }

  // Handle punch/fist gesture for rotation
  void handlePunchGesture() {
    if (!_isPlaying || _currentPiece == null) return;

    final now = DateTime.now();
    if (now.difference(_lastDropTime).inMilliseconds > _rotateDelayMs) {
      final newRotation = (_currentPiece!.rotation + 1) % 4;
      final originalRotation = _currentPiece!.rotation;
      _currentPiece!.rotation = newRotation;

      if (!_canMovePiece(_currentPiece!, 0, 0)) {
        _currentPiece!.rotation = originalRotation;
      } else {
        _lastDropTime = now;
        notifyListeners();
      }
    }
  }
}
