import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wotd/src/routes.dart';

class WordOfTheDayApp extends ConsumerWidget {
  const WordOfTheDayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.read(routesProvider),
      theme: _getTheme(),
    );
  }
}

ThemeData _getTheme() {
  var colorScheme = const ColorScheme.dark();
  var baseTheme = ThemeData.dark();
  return baseTheme.copyWith(
    colorScheme: colorScheme,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
      ),
      alignLabelWithHint: true,
      fillColor: colorScheme.surface,
      filled: true,
    ),
    textTheme: baseTheme.textTheme.copyWith(
      labelLarge: const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
