import 'package:flutter/material.dart';

import 'lips_and_shade_filter/lipsandshadefilter.dart';

void main() {
  runApp(const ShadeCheckPreviewApp());
}

class ShadeCheckPreviewApp extends StatelessWidget {
  const ShadeCheckPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shade Check Preview',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF65B5),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LipsAndShadeFilter(),
    );
  }
}