import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/career_profile_repository.dart';
import '../../data/current_cv_repository.dart';
import '../../data/github_profile_repository.dart';
import '../../data/opportunity_repository.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicRepository>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicRepository>();
    final session = context.watch<AuthRepository>().session;
    final careerProfile = context.watch<CareerProfileRepository>();
    final linkedInReady = careerProfile.hasProfile;
    final githubReady = context.watch<GithubProfileRepository>().hasProfile;
    final resume = context.watch<CurrentCvRepository>();
    final resumeReady = resume.hasProfile;
    final opportunities = context.watch<OpportunityRepository>();
    final professionalSources = [linkedInReady, githubReady, resumeReady]
        .where((ready) => ready)
        .length;
    final currentSeason =
        academic.context?.currentSeason ?? session?.currentSeason ?? 'Current';
    final firstName = _firstName(
      careerProfile.profile?.name ?? resume.profile?.name,
    );
    final matchCount = opportunities.result?.jobs.length;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => academic.loadDashboard(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Expanded(child: LensLogo(size: 34)),
                    _SeasonChip(academic: academic, fallback: currentSeason),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              sliver: SliverList.list(
                children: [
                  Text(
                    _greeting(firstName),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _insight(
                      professionalSources: professionalSources,
                      matchCount: matchCount,
                      gpa: academic.transcript?.cumulativeGpaWithGrade,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: LensColors.muted,
                          height: 1.4,
                        ),
                  ),
                  if (session != null && !session.cmsConnected) ...[
                    const SizedBox(height: 16),
                    CmsAccessNotice(message: session.cmsMessage),
                  ],
                  const SizedBox(height: 24),
                  if (academic.loadingDashboard &&
                      academic.context == null) ...[
                    const _Surface(child: LensLoading()),
                  ] else if (academic.error != null &&
                      academic.context == null) ...[
                    LensError(
                      message: academic.error!,
                      onRetry: () => academic.loadDashboard(force: true),
                    ),
                  ] else ...[
                    _Snapshot(
                      gpa: academic.transcript?.cumulativeGpaWithGrade ??
                          '—',
                      courseCount: academic.courses.length,
                      professionalSources: professionalSources,
                    ),
                    const SizedBox(height: 16),
                    _CopilotSpotlight(
                      onTap: () => _askCopilot(context, currentSeason),
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(title: 'Next step'),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final step = _nextStep(
                          professionalSources: professionalSources,
                          matchCount: matchCount,
                        );
                        return _ActionRow(
                          icon: step.icon,
                          iconColor: step.color,
                          title: step.title,
                          subtitle: step.subtitle,
                          onTap: () => step.onTap(context),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _askCopilot(BuildContext context, String season) {
    context.read<AdvisorRepository>().send(
          'Review my $season courses and academic record. What is the '
          'single most important action I should take next, and why?',
        );
    context.go('/advisor');
  }

  static String? _firstName(String? fullName) {
    final trimmed = fullName?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  static String _greeting(String? firstName) {
    final hour = DateTime.now().hour;
    final timeOfDay = hour < 12
        ? 'morning'
        : hour < 17
            ? 'afternoon'
            : 'evening';
    return firstName == null
        ? 'Good $timeOfDay'
        : 'Good $timeOfDay, $firstName';
  }

  static String _insight({
    required int professionalSources,
    required int? matchCount,
    required String? gpa,
  }) {
    if (professionalSources < 3) {
      final remaining = 3 - professionalSources;
      return "You're $remaining ${remaining == 1 ? 'source' : 'sources'} "
          'away from stronger role matches.';
    }
    if (matchCount != null) {
      return matchCount == 0
          ? 'No roles matched your last search — try widening your filters.'
          : '$matchCount role${matchCount == 1 ? '' : 's'} matched your '
              'profile — review them when ready.';
    }
    final gpaPrefix = gpa == null ? '' : 'GPA $gpa, ';
    return '${gpaPrefix}all evidence is ready — time to find your next role.';
  }

  static ({
    IconData icon,
    Color color,
    String title,
    String subtitle,
    void Function(BuildContext) onTap,
  }) _nextStep({
    required int professionalSources,
    required int? matchCount,
  }) {
    if (professionalSources < 3) {
      return (
        icon: Icons.person_add_alt_1_outlined,
        color: LensColors.aqua,
        title: 'Complete your career profile',
        subtitle: '$professionalSources of 3 professional sources are ready.',
        onTap: (context) => context.go('/profile'),
      );
    }
    if (matchCount != null) {
      return (
        icon: Icons.work_outline_rounded,
        color: LensColors.aqua,
        title: 'Review your matched roles',
        subtitle: matchCount == 0
            ? 'No roles matched last time — adjust your filters.'
            : '$matchCount role${matchCount == 1 ? '' : 's'} ready to review.',
        onTap: (context) => context.push('/opportunities'),
      );
    }
    return (
      icon: Icons.search_rounded,
      color: LensColors.aqua,
      title: 'Find roles matched to your profile',
      subtitle: 'LinkedIn, GitHub, and your resume are ready for matching.',
      onTap: (context) => context.push('/opportunities'),
    );
  }
}

class _SeasonChip extends StatelessWidget {
  final AcademicRepository academic;
  final String fallback;

  const _SeasonChip({required this.academic, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final current = academic.context?.currentSeason ?? fallback;
    return Material(
      color: LensColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: const BorderSide(color: LensColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: academic.updatingAdvisorySemester
            ? null
            : () => _pickSeason(context, current),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (academic.updatingAdvisorySemester)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: LensColors.indigo,
                ),
              const SizedBox(width: 7),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: Text(
                  current,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: LensColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickSeason(BuildContext context, String current) async {
    final options = <String>{current, ...academic.seasons}.toList();
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advisory semester',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...options.map(
                (season) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(season),
                  trailing: season == current
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: LensColors.aqua,
                        )
                      : null,
                  onTap: () => Navigator.pop(sheetContext, season),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || selected == current || !context.mounted) return;
    final changed = await academic.selectAdvisorySemester(selected);
    if (!context.mounted) return;
    if (changed) {
      context.read<AdvisorRepository>().clearLocal();
      final cmsConnected =
          context.read<AuthRepository>().session?.cmsConnected ?? false;
      if (cmsConnected) {
        await context.read<CmsRepository>().loadCourses(
              force: true,
              season: selected,
            );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            academic.error ??
                (cmsConnected
                    ? 'Now advising from $selected. Courses and Copilot '
                        'context were refreshed.'
                    : 'Now advising from $selected. Portal records and '
                        'Copilot context were refreshed.'),
          ),
        ),
      );
    } else if (academic.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(academic.error!)),
      );
    }
  }
}

class _CopilotSpotlight extends StatelessWidget {
  final VoidCallback onTap;

  const _CopilotSpotlight({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [LensColors.indigo, LensColors.violet],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: LensColors.indigo.withValues(alpha: .28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask Copilot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'What should I focus on next?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Snapshot extends StatelessWidget {
  final String gpa;
  final int courseCount;
  final int professionalSources;

  const _Snapshot({
    required this.gpa,
    required this.courseCount,
    required this.professionalSources,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface(
      padding: const EdgeInsets.symmetric(vertical: 17),
      child: Row(
        children: [
          Expanded(
            child: _SnapshotValue(
              value: gpa,
              label: 'GPA',
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _SnapshotValue(
              value: '$courseCount',
              label: 'Courses',
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _SnapshotValue(
              value: '$professionalSources/3',
              label: 'Profile',
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotValue extends StatelessWidget {
  final String value;
  final String label;

  const _SnapshotValue({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LensColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: LensColors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 38,
      child: VerticalDivider(width: 1, color: LensColors.line),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: LensColors.muted,
          ),
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: LensColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LensColors.line),
      ),
      child: child,
    );
    if (onTap == null) return surface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: surface,
      ),
    );
  }
}
