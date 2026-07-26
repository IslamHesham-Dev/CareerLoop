import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/practice_repository.dart';
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
    final practiceCount = context.watch<PracticeRepository>().sets.length;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => academic.loadDashboard(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
          children: [
            Row(
              children: [
                const Expanded(child: LensLogo(size: 38)),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Your workspace',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'See what matters now, then take one useful next step.',
              style: TextStyle(color: LensColors.muted),
            ),
            const SizedBox(height: 18),
            _ContextSelector(academic: academic),
            if (session != null && !session.cmsConnected) ...[
              const SizedBox(height: 12),
              _CompactCmsNotice(message: session.cmsMessage),
            ],
            const SizedBox(height: 18),
            if (academic.loadingDashboard && academic.context == null)
              const LensCard(
                child: LensLoading(label: 'Loading your workspace...'),
              )
            else if (academic.error != null && academic.context == null)
              LensError(
                message: academic.error!,
                onRetry: () => academic.loadDashboard(force: true),
              )
            else ...[
              _SnapshotCard(
                gpa: academic.transcript?.cumulativeGpaWithGrade ?? '—',
                courseCount: academic.courses.length,
                onCopilot: () => context.go('/advisor'),
                onProfile: () => context.go('/profile'),
              ),
              const SizedBox(height: 26),
              const _SectionHeader(title: 'Continue'),
              const SizedBox(height: 10),
              _WorkspaceAction(
                icon: Icons.auto_stories_rounded,
                color: LensColors.indigo,
                title: 'Learning space',
                subtitle:
                    '${academic.courses.length} semester courses and verified materials',
                action: 'Open',
                onTap: () => context.go('/courses'),
              ),
              const SizedBox(height: 9),
              _WorkspaceAction(
                icon: Icons.quiz_outlined,
                color: LensColors.aqua,
                title: 'Practice library',
                subtitle: practiceCount == 0
                    ? 'Create your first source-grounded quiz'
                    : '$practiceCount saved ${practiceCount == 1 ? 'quiz' : 'quizzes'}',
                action: practiceCount == 0 ? 'Create' : 'Practice',
                onTap: practiceCount == 0
                    ? () => _sendPrompt(
                          context,
                          'Create a 10-question interactive quiz for my '
                          'weakest current course.',
                        )
                    : () => context.push('/practice'),
              ),
              const SizedBox(height: 9),
              _WorkspaceAction(
                icon: Icons.rocket_launch_outlined,
                color: LensColors.amber,
                title: 'Career Studio',
                subtitle:
                    'Translate verified evidence into career-ready outputs',
                action: 'Explore',
                onTap: () => context.push('/career'),
              ),
              const SizedBox(height: 26),
              const _SectionHeader(
                title: 'Suggested by CareerLoop',
                detail: 'Uses connected evidence',
              ),
              const SizedBox(height: 10),
              LensCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SuggestionRow(
                      icon: Icons.track_changes_outlined,
                      title: 'Find my strongest career evidence',
                      onTap: () => _sendPrompt(
                        context,
                        'Use my full transcript to identify my strongest '
                        'career-relevant skills and cite the evidence for each.',
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _SuggestionRow(
                      icon: Icons.calendar_view_week_outlined,
                      title: 'Turn my weakest result into a one-week plan',
                      onTap: () => _sendPrompt(
                        context,
                        'Find my weakest verified assessment and build a '
                        'practical one-week improvement plan.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _sendPrompt(BuildContext context, String prompt) {
    context.read<AdvisorRepository>().send(prompt);
    context.go('/advisor');
  }
}

class _ContextSelector extends StatelessWidget {
  final AcademicRepository academic;

  const _ContextSelector({required this.academic});

  @override
  Widget build(BuildContext context) {
    final current = academic.context?.currentSeason ?? 'Winter 2024';
    final options = <String>{current, ...academic.seasons}.toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 7, 8, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LensColors.line),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.layers_outlined,
            size: 19,
            color: LensColors.indigo,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE CONTEXT',
                  style: TextStyle(
                    color: LensColors.muted,
                    fontSize: 8.5,
                    letterSpacing: .9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Courses, CMS, and Copilot',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              borderRadius: BorderRadius.circular(14),
              style: const TextStyle(
                color: LensColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              items: options
                  .map(
                    (season) => DropdownMenuItem(
                      value: season,
                      child: Text(season),
                    ),
                  )
                  .toList(),
              onChanged: academic.updatingAdvisorySemester
                  ? null
                  : (season) async {
                      if (season == null || season == current) return;
                      final changed =
                          await academic.selectAdvisorySemester(season);
                      if (!context.mounted || !changed) return;
                      context.read<AdvisorRepository>().clearLocal();
                      final cmsConnected = context
                              .read<AuthRepository>()
                              .session
                              ?.cmsConnected ??
                          false;
                      if (cmsConnected) {
                        await context.read<CmsRepository>().loadCourses(
                              force: true,
                              season: season,
                            );
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  final String gpa;
  final int courseCount;
  final VoidCallback onCopilot;
  final VoidCallback onProfile;

  const _SnapshotCard({
    required this.gpa,
    required this.courseCount,
    required this.onCopilot,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LensColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: LensColors.aqua,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'VERIFIED SNAPSHOT',
                style: TextStyle(
                  color: LensColors.aqua,
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _SnapshotMetric(value: gpa, label: 'Cumulative GPA'),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withValues(alpha: .12),
              ),
              Expanded(
                child: _SnapshotMetric(
                  value: '$courseCount',
                  label: 'Current courses',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCopilot,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                  label: const Text('Ask Copilot'),
                ),
              ),
              const SizedBox(width: 9),
              IconButton.outlined(
                tooltip: 'Open profile',
                onPressed: onProfile,
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: .25),
                  ),
                ),
                icon: const Icon(Icons.person_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  final String value;
  final String label;

  const _SnapshotMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _WorkspaceAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  const _WorkspaceAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            action,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color, size: 18),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: Icon(icon, color: LensColors.indigo, size: 20),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(
        Icons.arrow_forward_rounded,
        size: 17,
        color: LensColors.muted,
      ),
      onTap: onTap,
    );
  }
}

class _CompactCmsNotice extends StatelessWidget {
  final String? message;

  const _CompactCmsNotice({this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: LensColors.amber,
          size: 18,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message ??
                'CMS may be unavailable for final-year or graduate accounts. '
                    'Portal records and local practice still work.',
            style: const TextStyle(
              color: LensColors.muted,
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? detail;

  const _SectionHeader({required this.title, this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (detail != null)
          Text(
            detail!,
            style: const TextStyle(color: LensColors.muted, fontSize: 10),
          ),
      ],
    );
  }
}
