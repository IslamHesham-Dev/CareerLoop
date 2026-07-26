import 'package:flutter/material.dart';

abstract final class LensColors {
  static const ink = Color(0xFF030712);
  static const midnight = Color(0xFF0F172A);
  static const indigo = Color(0xFF4F46E5);
  static const violet = Color(0xFF8B5CF6);
  static const aqua = Color(0xFF06B6D4);
  static const amber = Color(0xFFF59E0B);
  static const rose = Color(0xFFF43F5E);
  static const canvas = Color(0xFFF8FAFC);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
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
      fontFamily: 'Inter', // Assuming standard system fonts fallback or Inter is added
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 36,
          height: 1.1,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
          color: LensColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 30,
          height: 1.2,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: LensColors.ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: LensColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: LensColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
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
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LensColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LensColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LensColors.indigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LensColors.rose),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LensColors.indigo,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          elevation: 0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: LensColors.indigo.withValues(alpha: .08),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? LensColors.indigo
                : LensColors.muted,
          ),
        ),
      ),
    );
  }
}
