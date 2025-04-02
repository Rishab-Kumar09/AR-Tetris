# AR Tetris

A gesture-controlled augmented reality Tetris game built with native Android/Kotlin. Play Tetris using hand movements captured through your device's camera!

## Features

- Real-time hand tracking using MediaPipe
- Gesture-based controls:
  - Move pieces left/right by positioning your index finger in different screen zones
  - Make a fist to instantly drop the current piece
  - Show two fingers (index and middle) to rotate pieces
- Beautiful native UI with camera preview and hand position visualization
- Score tracking and levels
- Increasing difficulty as you progress
- Optimized performance using native Android APIs

## Technical Stack

- Native Android development with Kotlin
- MediaPipe for hand tracking and gesture recognition
- CameraX API for efficient camera handling
- Android SurfaceView for optimized rendering
- ViewBinding for UI components

## Controls

The game uses intuitive hand gestures for control:

1. **Left/Right Movement**:
   - Position your index finger in the left zone to move piece left
   - Position your index finger in the right zone to move piece right
   - Center zone keeps the piece in place

2. **Rotation**:
   - Show two fingers (index and middle) to rotate the piece
   - Responsive and accurate gesture detection

3. **Fast Drop**:
   - Make a fist (close all fingers) to instantly drop the piece
   - Quick and precise response

## Requirements

- Android device with camera
- Android SDK version 30 or higher
- Camera permissions enabled
- Sufficient lighting for hand detection

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/AR-Tetris.git
```

2. Open in Android Studio

3. Build and run on your device

## Game Rules

- Standard Tetris rules apply
- Clear lines by filling them completely
- Score increases based on lines cleared:
  - 1 line = 100 × level
  - 2 lines = 300 × level
  - 3 lines = 500 × level
  - 4 lines = 800 × level
- Level increases every 10 lines cleared
- Game speed increases with each level
- Game ends if pieces stack to the top

## Performance Features

1. Native Implementation Benefits:
   - Direct access to Android APIs
   - Optimized camera processing with CameraX
   - Efficient hand tracking using MediaPipe
   - Low-latency gesture recognition

2. Best Practices:
   - Hardware-accelerated rendering
   - Efficient memory management
   - Background thread processing
   - Frame rate optimization

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- MediaPipe team for the hand tracking SDK
- CameraX team for the camera API
- The Tetris Company for the original game concept
