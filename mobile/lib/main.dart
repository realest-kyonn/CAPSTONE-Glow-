import 'package:flutter/material.dart';
import 'page_1/page1.dart';

void main() {
  runApp(const GlowApp());
}

class GlowApp extends StatelessWidget {
  const GlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GLOW',
      debugShowCheckedModeBanner: false,
      // App starts at Splash Screen
      home: const SplashScreen(),
    );
  }
}