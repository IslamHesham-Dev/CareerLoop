import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/career_profile_repository.dart';
import '../../data/current_cv_repository.dart';
import '../../data/github_profile_repository.dart';
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
    final linkedInReady = context.watch<CareerProfileRepository>().hasProfile;
    final githubReady = context.watch<GithubProfileRepository>().hasProfile;
    final resumeReady = context.watch<CurrentCvRepository>().hasProfile;
    final professionalSources = [linkedInReady, githubReady, resumeReady]
        .where((ready) => ready)
        .length;
    final currentSeason =
        academic.context?.currentSeason ?? session?.currentSeason ?? 'Current';

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => academic.loadDashboard(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              sliver: SliverToBoxAdapter(
                child: LensLogo(size: 36),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Today',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  _AdvisorySemesterPicker(
                    academic: academic,
                    fallbackSeason: currentSeason,
                  ),
                  if (session != null && !session.cmsConnected) ...[
                    const SizedBox(height: 14),
                    CmsAccessNotice(message: session.cmsMessage),
                  ],
                  const SizedBox(height: 20),
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
                          'Not loaded',
                      courseCount: academic.courses.length,
                      professionalSources: professionalSources,
                    ),
                    const SizedBox(height: 26),
                    const _SectionTitle(title: 'Next up'),
                    const SizedBox(height: 10),
                    _ActionRow(
                      icon: Icons.menu_book_outlined,
                      iconColor: LensColors.indigo,
                      title: academic.courses.isEmpty
                          ? 'Review your academic record'
                          : 'Open your $currentSeason courses',
                      subtitle: academic.courses.isEmpty
                          ? 'Your transcript and course history are ready to review.'
                          : '${academic.courses.length} current courses are available.',
                      onTap: () => context.go('/courses'),
                    ),
                    const SizedBox(height: 10),
                    _ActionRow(
                      icon: professionalSources == 3
                          ? Icons.work_outline_rounded
                          : Icons.person_add_alt_1_outlined,
                      iconColor: LensColors.aqua,
                      title: professionalSources == 3
                          ? 'Find roles matched to your profile'
                          : 'Complete your career profile',
                      subtitle: professionalSources == 3
                          ? 'LinkedIn, GitHub, and your resume can support role matching.'
                          : '$professionalSources of 3 professional sources are ready.',
                      onTap: () => professionalSources == 3
                          ? context.push('/opportunities')
                          : context.go('/profile'),
                    ),
                    const SizedBox(height: 26),
                    const _SectionTitle(title: 'Quick actions'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/transcript'),
                            icon: const Icon(Icons.school_outlined),
                            label: const Text('Transcript'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              side: const BorderSide(color: LensColors.line),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              context.read<AdvisorRepository>().send(
                                    'Review my $currentSeason courses and '
                                    'academic record. What is the single most '
                                    'important action I should take next, and '
                                    'why?',
                                  );
                              context.go('/advisor');
                            },
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('Ask Copilot'),
                          ),
                        ),
                      ],
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
}

class _AdvisorySemesterPicker extends StatelessWidget {
  final AcademicRepository academic;
  final String fallbackSeason;

  const _AdvisorySemesterPicker({
    required this.academic,
    required this.fallbackSeason,
  });

  @override
  Widget build(BuildContext context) {
    final current = academic.context?.currentSeason ?? fallbackSeason;
    final options = <String>{current, ...academic.seasons}.toList();
    return DropdownButtonFormField<String>(
      key: ValueKey(current),
      value: current,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Advisory semester',
        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        suffixIcon: academic.updatingAdvisorySemester
            ? const Padding(
                padding: EdgeInsets.all(15),
                child: SizedBox.square(
                  dimension: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      items: options
          .map(
            (season) => DropdownMenuItem(
              value: season,
              child: Text(season, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: academic.updatingAdvisorySemester
          ? null
          : (season) async {
              if (season == null || season == current) return;
              final changed = await academic.selectAdvisorySemester(season);
              if (!context.mounted) return;
              if (changed) {
                context.read<AdvisorRepository>().clearLocal();
                final cmsConnected =
                    context.read<AuthRepository>().session?.cmsConnected ??
                        false;
                if (cmsConnected) {
                  await context.read<CmsRepository>().loadCourses(
                        force: true,
                        season: season,
                      );
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      academic.error ??
                          (cmsConnected
                              ? 'Now advising from $season. Courses and '
                                  'Copilot context were refreshed.'
                              : 'Now advising from $season. Portal records '
                                  'and Copilot context were refreshed.'),
                    ),
                  ),
                );
              } else if (academic.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(academic.error!)),
                );
              }
            },
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
