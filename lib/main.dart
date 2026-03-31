import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/links_provider.dart';
import 'providers/upload_provider.dart';
import 'screens/home_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Camera error: $e');
  }
  runApp(const CamsceneApp());
}

class CamsceneApp extends StatelessWidget {
  const CamsceneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LinksProvider()),
        ChangeNotifierProvider(create: (_) => UploadProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Camscene',
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}