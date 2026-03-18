import 'package:flutter/material.dart';

class AppColor {
  static const Color scaffoldLightColor = Colors.white;
  static const Color scaffoldDarkColor = Color(0xFF202057);
  static const Color appBarDarkColor = Color(0xFF00136C);
  static const Color appBarLightColor = Colors.blueAccent;
  static const Color chosenButtonColor = Colors.blue;
  static const Color unchosenButtonColor = Colors.white24;
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
      foregroundColor: Colors.white,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue.shade900,
      foregroundColor: Colors.white,
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
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
    ),
  );
  static ThemeData buildLightTheme(Color accentColor) {
    return lightTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 6,
        highlightElevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: accentColor,
        elevation: 8,
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.grey.shade400;
            } else if (states.contains(WidgetState.pressed)) {
              return _darken(accentColor, 0.12);
            }
            return accentColor;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return _withAlpha(accentColor, 0.35);
          }
          return null;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return null;
        }),
      ),
    );
  }

  static ThemeData buildDarkTheme(Color accentColor) {
    return darkTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 6,
        highlightElevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: AppColor.appBarDarkColor,
        elevation: 8,
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.grey.shade700;
            } else if (states.contains(WidgetState.pressed)) {
              return _darken(accentColor, 0.12);
            }
            return accentColor;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return _withAlpha(accentColor, 0.45);
          }
          return null;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return null;
        }),
      ),
    );
  }

  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }

  static Color _withAlpha(Color color, double opacity) {
    return color.withAlpha((255 * opacity).round());
  }
}
