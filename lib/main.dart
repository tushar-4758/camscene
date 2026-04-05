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
  cameras = await availableCameras();
  runApp(const CamSceneApp());
}

class CamSceneApp extends StatelessWidget {
  const CamSceneApp({super.key});

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
        title: 'CamScene',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF081120),
          primaryColor: Colors.white,
          cardColor: const Color(0xFF10203B),
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            secondary: Color(0xFF9BB4E0),
            surface: Color(0xFF10203B),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF081120),
            elevation: 0,
            centerTitle: false,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF10203B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: EdgeInsets.zero,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF081120),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF2A4167)),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}