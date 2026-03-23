import 'package:flutter/material.dart';

class AppColor {
  static const Color scaffoldLightColor = Colors.white;
  static const Color scaffoldDarkColor = Color(0xFF202057);
  static const Color appBarDarkColor = Color(0xFF00136C);
  static const Color appBarLightColor = Colors.blueAccent;
  static const Color chosenButtonColor = Colors.blue;
  static const Color unchosenButtonColor = Colors.white24;
}

class themeColors {
  static const Color red = Colors.redAccent;
  static const Color green = Colors.greenAccent;
  static const Color blue = Colors.blueAccent;
}

class AppTheme {
  //==========================
  // Jasny motyw
  //==========================
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColor.scaffoldLightColor,

    // ColorScheme generowany z głównego koloru
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.light,
    ),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: 8,
      backgroundColor: AppColor.appBarLightColor,
      foregroundColor: Colors.white,
    ),

    // FAB Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      elevation: 6,
      highlightElevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    ),

    // BottomAppBar Theme
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: AppColor.appBarLightColor,
      height: 80,
      elevation: 8,
    ),

    // Button Theme (TextButton, ElevatedButton, itp.)
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey.shade400;
          } else if (states.contains(WidgetState.pressed)) {
            return Colors.blue.shade700;
          }
          return Colors.blueAccent;
        }),
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
    ),
  );

  //==========================
  // Ciemny motyw
  //==========================
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColor.scaffoldDarkColor,

    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.dark,
    ),

    appBarTheme: const AppBarTheme(
      elevation: 8,
      backgroundColor: AppColor.appBarDarkColor,
      foregroundColor: Color(0xFF00136C),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue.shade900,
      foregroundColor: Color(0xFF00136C),
      elevation: 6,
      highlightElevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    ),

    bottomAppBarTheme: const BottomAppBarThemeData(
      color: AppColor.appBarDarkColor,
      elevation: 8,
    ),

    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey.shade700;
          } else if (states.contains(WidgetState.pressed)) {
            return Colors.blue.shade700;
          }
          return Colors.blue.shade900;
        }),
        foregroundColor: WidgetStateProperty.all(Color(0xFF00136C)),
      ),
    ),
  );
}
