import 'package:flutter/material.dart';

abstract final class LensColors {
  static const ink = Color(0xFF101828);
  static const midnight = Color(0xFF1D2939);
  static const indigo = Color(0xFF4654D6);
  static const violet = Color(0xFF7257C7);
  static const aqua = Color(0xFF238B7D);
  static const amber = Color(0xFFD58B2A);
  static const rose = Color(0xFFD8495B);
  static const canvas = Color(0xFFF7F8FA);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFF667085);
  static const line = Color(0xFFE4E7EC);
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
      error: const Color(0xFFD8495B),
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
          fontSize: 34,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: LensColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          height: 1.16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: LensColors.ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
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
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: LensColors.ink,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: LensColors.card,
        surfaceTintColor: LensColors.card,
        foregroundColor: LensColors.ink,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: LensColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LensColors.rose),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LensColors.indigo,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
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
        indicatorColor: LensColors.indigo.withValues(alpha: .12),
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
