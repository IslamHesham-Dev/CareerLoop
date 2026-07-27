import 'package:flutter/material.dart';

abstract final class LensColors {
  static const ink = Color(0xFF09090B); // Zinc 950
  static const midnight = Color(0xFF18181B); // Zinc 900
  static const indigo = Color(0xFF6366F1);
  static const violet = Color(0xFF8B5CF6);
  static const aqua = Color(0xFF06B6D4);
  static const amber = Color(0xFFF59E0B);
  static const rose = Color(0xFFF43F5E);
  static const canvas = Color(0xFFFAFAFA); // Zinc 50
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFF71717A); // Zinc 500
  static const line = Color(0xFFE4E4E7); // Zinc 200
  static const border = Color(0xFFF4F4F5); // Zinc 100
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
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 36,
          height: 1.1,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          color: LensColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 32,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
          color: LensColors.ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: LensColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: LensColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: LensColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: LensColors.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: LensColors.muted,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
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
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
          borderSide: const BorderSide(color: LensColors.indigo, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LensColors.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          elevation: 0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: LensColors.ink.withValues(alpha: 0.05),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? LensColors.ink
                : LensColors.muted,
          ),
        ),
      ),
    );
  }
}
