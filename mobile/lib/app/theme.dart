import 'package:flutter/material.dart';

abstract final class LensColors {
  static const ink = Color(0xFF172033);
  static const midnight = Color(0xFF24304A);
  static const indigo = Color(0xFF3457D5);
  static const violet = Color(0xFF7057A8);
  static const aqua = Color(0xFF1F9D86);
  static const amber = Color(0xFFC58A24);
  static const rose = Color(0xFFD95D6F);
  static const canvas = Color(0xFFF5F5F1);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFF667085);
  static const line = Color(0xFFE5E7E2);
}

abstract final class CareerLoopTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: LensColors.indigo,
      brightness: Brightness.light,
      surface: LensColors.card,
    ).copyWith(
      primary: LensColors.indigo,
      secondary: LensColors.aqua,
      tertiary: LensColors.violet,
      error: LensColors.rose,
      surface: LensColors.card,
      onSurface: LensColors.ink,
      outline: LensColors.line,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: LensColors.canvas,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 36,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.4,
          color: LensColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 27,
          height: 1.16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
          color: LensColors.ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 21,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35,
          color: LensColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: LensColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: LensColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: LensColors.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: LensColors.muted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: LensColors.ink,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LensColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LensColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LensColors.indigo, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LensColors.rose),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LensColors.indigo,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: LensColors.indigo.withValues(alpha: .10),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? LensColors.indigo
                : LensColors.muted,
          ),
        ),
      ),
    );
  }
}
