# AR Bubble Pop

An augmented reality bubble popping game built with Flutter. Pop colorful bubbles using your hand movements (on mobile) or mouse (on web) to score points and advance through levels!

## Features

- **Cross-platform support**: Works on both mobile devices (using camera and hand tracking) and web browsers (using mouse input)
- **Augmented reality**: Uses Google ML Kit for pose detection to track hand movements on mobile devices
- **Responsive design**: Adapts to different screen sizes and orientations
- **Progressive difficulty**: Game gets more challenging as you advance through levels
- **Visual effects**: Animated bubbles, pop effects, and visual feedback
- **Score tracking**: Keep track of your score and high score

## How to Play

### Mobile Devices
1. Allow camera permissions when prompted
2. Hold your hand in front of the camera
3. Move your hand to pop bubbles
4. Score points by popping as many bubbles as possible
5. Advance through levels by reaching score thresholds
6. Game ends when time runs out

### Web Browsers
1. Move your mouse cursor to pop bubbles
2. Click to pop bubbles more effectively
3. Score points and advance through levels
4. Game ends when time runs out

## Game Mechanics

- **Bubbles**: Different sizes and colors, smaller bubbles are worth more points
- **Scoring**: Pop bubbles to earn points
- **Levels**: Advance to the next level by reaching score thresholds
- **Time**: Each level starts with 60 seconds, gain bonus time when leveling up
- **Difficulty**: Bubbles move faster and spawn more frequently in higher levels

## Technical Details

This game is built using:
- Flutter for cross-platform UI
- Google ML Kit for pose detection
- Provider for state management
- Flutter Animate for animations

## Platform-specific Implementation

The game uses different input methods depending on the platform:
- On mobile devices, it uses the device's camera and Google ML Kit to track hand movements
- On web browsers, it uses mouse position and clicks for interaction

## Getting Started

### Prerequisites
- Flutter SDK
- Android Studio or VS Code with Flutter extensions
- For mobile development: Android or iOS device/emulator
- For web development: Chrome browser

### Installation
1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to launch the app on your connected device
4. For web: Run `flutter run -d chrome` to launch in Chrome

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Google ML Kit for pose detection capabilities 