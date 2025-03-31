# AR Tetris

A gesture-controlled augmented reality Tetris game. Play Tetris using hand movements captured through your device's camera!

## Features

- Real-time hand tracking using camera input
- Gesture-based controls:
  - Move your hand left/right of screen center to move pieces
  - Quick upward hand movement to rotate pieces
  - Quick downward hand movement for fast drop
- Beautiful UI with camera preview and hand position visualization
- Score tracking and levels
- Increasing difficulty as you progress
- Works on Android devices

## Controls

The game uses intuitive hand gestures for control:

1. **Left/Right Movement**:
   - Move your hand to the left half of the screen to move piece left
   - Move your hand to the right half of the screen to move piece right
   - Movement is instant and responsive

2. **Rotation**:
   - Quick upward hand movement rotates the piece clockwise
   - Has a small cooldown to prevent accidental rotations

3. **Fast Drop**:
   - Quick downward hand movement triggers fast drop
   - Use this to quickly place pieces at the bottom

## Technical Details

- Built with Flutter
- Uses device camera for hand tracking
- Implements brightness-based hand detection
- Optimized for performance with frame skipping
- Face detection avoidance using threshold zones
- Smooth hand tracking with position history

## Requirements

- Android device with camera
- Android SDK version 21 or higher
- Flutter 2.19.0 or higher
- Camera permissions enabled

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/AR-Tetris.git
```

2. Navigate to the project directory:
```bash
cd AR-Tetris/AR-Tetris2
```

3. Get dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

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

## Performance Tips

1. Play in a well-lit environment
2. Keep your hand below face level
3. Make clear, deliberate movements
4. Maintain some distance from the camera
5. Avoid rapid, erratic movements

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Camera plugin contributors
- The Tetris Company for the original game concept

## Contact

For any queries or suggestions, please open an issue in the GitHub repository.
