import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/links_provider.dart';
import 'providers/upload_provider.dart';
import 'screens/home_screen.dart';

void main() {
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
          scaffoldBackgroundColor: const Color(0xFF0F0F10),
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            secondary: Color(0xFFB0B0B0),
            surface: Color(0xFF1B1B1D),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F0F10),
            elevation: 0,
            centerTitle: false,
          ),
          cardTheme: widget(
            child: CardTheme(
              color: const Color(0xFF1B1B1D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: EdgeInsets.zero,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF3A3A3D)),
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