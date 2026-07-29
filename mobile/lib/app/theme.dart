import 'package:flutter/material.dart';

/// Brand accent colors — shared across light and dark mode, same as the
/// login screen's own accent pair. Only neutrals (surface/text) flip with
/// brightness; see [LensSurface].
abstract final class LensColors {
  static const indigo = Color(0xFF4654D6);
  static const violet = Color(0xFF7257C7);
  static const aqua = Color(0xFF238B7D);
  static const amber = Color(0xFFD58B2A);
  static const rose = Color(0xFFD8495B);
}

/// Theme-reactive neutrals (background/surface/border/text). Access via
/// `context.lens` rather than a static constant so widgets rebuild when the
/// light/dark preference changes.
@immutable
class LensSurface extends ThemeExtension<LensSurface> {
  final Color canvas;
  final Color card;
  final Color line;
  final Color ink;
  final Color muted;

  const LensSurface({
    required this.canvas,
    required this.card,
    required this.line,
    required this.ink,
    required this.muted,
  });

  factory LensSurface.light() => const LensSurface(
        canvas: Color(0xFFF7F8FA),
        card: Color(0xFFFFFFFF),
        line: Color(0xFFE4E7EC),
        ink: Color(0xFF101828),
        muted: Color(0xFF667085),
      );

  factory LensSurface.dark() => const LensSurface(
        canvas: Color(0xFF0B0D14),
        card: Color(0xFF14171F),
        line: Color(0xFF262B38),
        ink: Color(0xFFF3F4F8),
        muted: Color(0xFF9298AA),
      );

  @override
  LensSurface copyWith({
    Color? canvas,
    Color? card,
    Color? line,
    Color? ink,
    Color? muted,
  }) {
    return LensSurface(
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
    );
  }

  @override
  LensSurface lerp(ThemeExtension<LensSurface>? other, double t) {
    if (other is! LensSurface) return this;
    return LensSurface(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

extension LensThemeX on BuildContext {
  LensSurface get lens => Theme.of(this).extension<LensSurface>()!;
}

abstract final class CareerLoopTheme {
  static ThemeData light() => _build(Brightness.light, LensSurface.light());

  static ThemeData dark() => _build(Brightness.dark, LensSurface.dark());

  static ThemeData _build(Brightness brightness, LensSurface surface) {
    final scheme = ColorScheme.fromSeed(
      seedColor: LensColors.indigo,
      brightness: brightness,
    ).copyWith(
      primary: LensColors.indigo,
      secondary: LensColors.aqua,
      tertiary: LensColors.violet,
      error: LensColors.rose,
      surface: surface.card,
      onSurface: surface.ink,
      outline: surface.line,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface.canvas,
      extensions: [surface],
      textTheme: TextTheme(
        displaySmall: TextStyle(
          fontSize: 34,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: surface.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          height: 1.16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: surface.ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35,
          color: surface.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: surface.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: surface.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: surface.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: surface.muted,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: surface.ink,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: surface.card,
        surfaceTintColor: surface.card,
        foregroundColor: surface.ink,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: surface.ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: surface.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: surface.line),
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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LensColors.indigo,
          minimumSize: const Size(0, 50),
          side: BorderSide(color: surface.line),
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
        backgroundColor: surface.card,
        indicatorColor: LensColors.indigo.withValues(alpha: .12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? LensColors.indigo
                : surface.muted,
          ),
        ),
      ),
    );
  }
}
