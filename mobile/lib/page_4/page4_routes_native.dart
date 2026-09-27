import 'package:flutter/material.dart';

import '../page_5/page5.dart';
import '../page_14_favorites/favorites.dart';
import '../page_about/about_screen.dart';
import '../page_settings/settings_screen.dart';
import '../page_skin_quiz/bare_face_tutorial_screen.dart';
import '../lips_and_shade_filter/lipsandshadefilter.dart';

Widget analysisScreen() => const ScanPrepScreen();

Widget skinQuizScreen() => const BareFaceTutorialScreen();

Widget shadeScreen() => const LipsAndShadeFilter();

Widget favoritesScreen() => const FavoritesScreen();

Widget aboutScreen() => const AboutScreen();

Widget settingsScreen() => const SettingsScreen();