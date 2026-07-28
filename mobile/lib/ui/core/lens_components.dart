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
            border: Border.all(color: LensColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/branding/careerloop-icon.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            semanticLabel: 'Career Loop',
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 12),
          Text(
            'Career Loop',
            style: TextStyle(
              color: wordmarkColor ?? LensColors.ink,
              fontWeight: FontWeight.w900,
              letterSpacing: -.55,
              fontSize: size * .46,
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
      child: child,
    );
  }
}

class LensCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  const LensCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? LensColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LensColors.line),
        boxShadow: [
          BoxShadow(
            color: LensColors.ink.withValues(alpha: .025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: content,
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
        color: dark ? Colors.white.withValues(alpha: .08) : LensColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: .16) : LensColors.line,
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
                fontSize: 11.5,
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
                eyebrow,
                style: const TextStyle(
                  color: LensColors.indigo,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .1,
                  fontSize: 13,
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
                          'and Career Loop Copilot will continue to work.',
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
