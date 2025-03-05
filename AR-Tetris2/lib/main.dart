import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'models/game_model.dart';
import 'screens/game_screen.dart';
import 'services/camera_service.dart';
import 'services/hand_tracking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Keep screen on
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersive,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameModel()),
        Provider(create: (_) => CameraService()),
        Provider(create: (_) => HandTrackingService()),
      ],
      child: MaterialApp(
        title: 'AR Tetris',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
        ),
        home: const GameScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
