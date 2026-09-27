import 'package:flutter/material.dart';

import 'page_4/page4.dart';

void main() {
  runApp(const HomePreviewApp());
}

class HomePreviewApp extends StatelessWidget {
  const HomePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GLOW Home Preview',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6EB4),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomeDashboard(),
    );
  }
}