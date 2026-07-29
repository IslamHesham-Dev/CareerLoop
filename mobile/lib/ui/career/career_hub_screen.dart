import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/career_profile_repository.dart';
import '../../data/current_cv_repository.dart';
import '../../data/github_profile_repository.dart';
import '../../data/repositories.dart';

class CareerHubScreen extends StatelessWidget {
  const CareerHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicRepository>();
    final linkedInReady = context.watch<CareerProfileRepository>().hasProfile;
    final githubReady = context.watch<GithubProfileRepository>().hasProfile;
    final resumeReady = context.watch<CurrentCvRepository>().hasProfile;
    final sources = <_ProfileSource>[
      _ProfileSource(
          name: 'Academic record', ready: academic.transcript != null),
      _ProfileSource(name: 'LinkedIn', ready: linkedInReady),
      _ProfileSource(name: 'GitHub', ready: githubReady),
      _ProfileSource(name: 'Resume', ready: resumeReady),
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
        children: [
          Text(
            'Career',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _CareerAction(
            icon: Icons.search_rounded,
            title: 'Find matching roles',
            accent: LensColors.indigo,
            onTap: () => context.push('/opportunities'),
          ),
          const SizedBox(height: 12),
          _CareerAction(
            icon: Icons.forward_to_inbox_outlined,
            title: 'Apply from a post',
            accent: LensColors.amber,
            onTap: () => context.push('/quick-apply'),
          ),
          const SizedBox(height: 28),
          Text(
            'Profile readiness',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          _ReadinessCard(
            sources: sources,
            onManage: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

class _CareerAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final VoidCallback onTap;

  const _CareerAction({
    required this.icon,
    required this.title,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.lens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.lens.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: context.lens.muted,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  final List<_ProfileSource> sources;
  final VoidCallback onManage;

  const _ReadinessCard({
    required this.sources,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final ready = sources.where((source) => source.ready).length;
    final missing = sources
        .where((source) => !source.ready)
        .map((source) => source.name)
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 13, 14),
      decoration: BoxDecoration(
        color: context.lens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.lens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$ready of ${sources.length} sources ready',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      missing.isEmpty
                          ? 'Your academic and professional evidence is ready '
                              'for matching.'
                          : 'Add ${_naturalList(missing)} to improve role '
                              'matching.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onManage,
                child: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ready / sources.length,
              minHeight: 6,
              color: LensColors.aqua,
              backgroundColor: context.lens.line,
            ),
          ),
          const SizedBox(height: 14),
          ...sources.map(
            (source) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Icon(
                    source.ready
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 18,
                    color: source.ready ? LensColors.aqua : context.lens.muted,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      source.name,
                      style: TextStyle(
                        color: source.ready ? context.lens.ink : context.lens.muted,
                        fontSize: 13,
                        fontWeight:
                            source.ready ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Text(
                    source.ready ? 'Ready' : 'Not added',
                    style: TextStyle(
                      color: source.ready ? LensColors.aqua : context.lens.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _naturalList(List<String> values) {
    if (values.length == 1) return values.first;
    if (values.length == 2) return '${values.first} and ${values.last}';
    return '${values.take(values.length - 1).join(', ')}, and ${values.last}';
  }
}

class _ProfileSource {
  final String name;
  final bool ready;

  const _ProfileSource({
    required this.name,
    required this.ready,
  });
}
