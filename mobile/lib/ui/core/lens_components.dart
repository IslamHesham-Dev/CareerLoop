import 'dart:ui';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

class LensLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color? wordmarkColor;

  const LensLogo({
    super.key,
    this.size = 46,
    this.showWordmark = true,
    this.wordmarkColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * .27),
            boxShadow: [
              BoxShadow(
                color: LensColors.indigo.withValues(alpha: .22),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/branding/careerloop-icon.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            semanticLabel: 'CareerLoop',
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 12),
          Text(
            'CareerLoop',
            style: TextStyle(
              color: wordmarkColor ?? LensColors.ink,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              fontSize: size * 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class AuroraBackground extends StatelessWidget {
  final Widget child;
  final bool dark;

  const AuroraBackground({super.key, required this.child, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? LensColors.ink : LensColors.canvas,
      ),
      child: Stack(
        children: [
          // Dynamic Orbs
          Positioned(
            top: -150,
            right: -100,
            child: _GlowOrb(
              size: 450,
              color: (dark ? LensColors.violet : LensColors.indigo)
                  .withValues(alpha: dark ? .18 : .12),
            ),
          ),
          Positioned(
            top: 200,
            left: -180,
            child: _GlowOrb(
              size: 400,
              color: LensColors.aqua.withValues(alpha: dark ? .14 : .08),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: _GlowOrb(
              size: 350,
              color: LensColors.violet.withValues(alpha: dark ? .12 : .06),
            ),
          ),
          // Subtle mesh-like gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  Colors.transparent,
                  (dark ? LensColors.ink : LensColors.canvas)
                      .withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class LensCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final bool isGlass;
  final double blur;

  const LensCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color,
    this.onTap,
    this.isGlass = false,
    this.blur = 12,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
        color ?? (isGlass ? Colors.white.withValues(alpha: 0.6) : Colors.white);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isGlass
              ? Colors.white.withValues(alpha: 0.4)
              : LensColors.line.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: LensColors.ink.withValues(alpha: .04),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );

    if (isGlass) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (onTap == null) return content;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: LensColors.ink.withValues(alpha: .04),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}

class GradientPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool dark;

  const GradientPill({
    super.key,
    required this.label,
    required this.icon,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: .09)
            : LensColors.indigo.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: .12)
              : LensColors.indigo.withValues(alpha: .12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: dark ? LensColors.aqua : LensColors.indigo,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: dark ? Colors.white : LensColors.indigo,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PageHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: LensColors.indigo,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 7),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 14), trailing!],
      ],
    );
  }
}

class LensLoading extends StatelessWidget {
  final String label;

  const LensLoading({super.key, this.label = 'Bringing your data into focus…'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 18),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class LensError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const LensError({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return LensCard(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 34, color: LensColors.rose),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

class CmsAccessNotice extends StatelessWidget {
  final String? message;

  const CmsAccessNotice({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: LensColors.amber.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: LensColors.amber.withValues(alpha: .20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: LensColors.amber.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: LensColors.amber,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CMS access is unavailable',
                  style: TextStyle(
                    color: LensColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message ??
                      'This commonly happens when final-year or graduate '
                          'students no longer have active CMS course access. '
                          'Your portal grades, transcripts, semester history, '
                          'and CareerLoop Copilot will continue to work.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
