import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
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
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => academic.loadDashboard(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Expanded(child: LensLogo(size: 39)),
                    IconButton.filledTonal(
                      onPressed: () => context.push('/settings'),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
              sliver: SliverList.list(
                children: [
                  const PageHeading(
                    eyebrow: 'Your CareerLoop',
                    title: 'Academic evidence.\nCareer momentum.',
                    subtitle:
                        'One intelligent loop turns what you learn and achieve into what you can do next.',
                  ),
                  const SizedBox(height: 18),
                  if (session != null && !session.cmsConnected) ...[
                    CmsAccessNotice(message: session.cmsMessage),
                    const SizedBox(height: 18),
                  ],
                  _AdvisorySemesterPicker(academic: academic),
                  const SizedBox(height: 24),
                  const _FocusHero(),
                  const SizedBox(height: 18),
                  if (academic.loadingDashboard &&
                      academic.context == null) ...[
                    const LensCard(child: LensLoading()),
                  ] else if (academic.error != null &&
                      academic.context == null) ...[
                    LensError(
                      message: academic.error!,
                      onRetry: () => academic.loadDashboard(force: true),
                    ),
                  ] else ...[
                    _Metrics(academic: academic),
                    const SizedBox(height: 26),
                    _SectionTitle(
                      title: 'Next best actions',
                      action: 'Open Copilot',
                      onTap: () => context.go('/advisor'),
                    ),
                    const SizedBox(height: 12),
                    _PromptGrid(
                      onPrompt: (prompt) {
                        context.read<AdvisorRepository>().send(prompt);
                        context.go('/advisor');
                      },
                    ),
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: 'Your two growth loops',
                    ),
                    const SizedBox(height: 12),
                    _PillarRoutes(
                      courseCount: academic.courses.length,
                      onLearn: () => context.go('/courses'),
                      onCareer: () => context.go('/career'),
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

  const _AdvisorySemesterPicker({required this.academic});

  @override
  Widget build(BuildContext context) {
    final current = academic.context?.currentSeason ?? 'Winter 2024';
    final options = <String>{current, ...academic.seasons}.toList();
    return DropdownButtonFormField<String>(
      key: ValueKey(current),
      value: current,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Active learning context',
        helperText: 'Controls course evidence and the Copilot context.',
        prefixIcon: Icon(Icons.calendar_month_outlined),
      ),
      items: options
          .map(
            (season) => DropdownMenuItem(
              value: season,
              child: Text(
                season,
                overflow: TextOverflow.ellipsis,
              ),
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
                              ? 'Now advising from $season. CMS courses and '
                                  'the AI context were refreshed.'
                              : 'Now advising from $season. Portal records '
                                  'and the AI context were refreshed.'),
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

class _FocusHero extends StatelessWidget {
  const _FocusHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LensColors.ink,
            Color(0xFF1E293B),
            LensColors.midnight,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: LensColors.indigo.withValues(alpha: .25),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: .15),
                      Colors.white.withValues(alpha: .05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .15),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: LensColors.aqua,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Evidence Loop',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'AI Agentic Assistant',
                      style: TextStyle(
                        color: LensColors.aqua,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const GradientPill(
                label: 'AGENTIC',
                icon: Icons.bolt_rounded,
                dark: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LoopNode(
                icon: Icons.school_rounded,
                label: 'ACADEMIC',
                detail: 'Verified Facts',
                color: LensColors.indigo,
              ),
              _ConnectorLine(color: LensColors.indigo),
              _LoopNode(
                icon: Icons.hub_rounded,
                label: 'COPILOT',
                detail: 'Smart Context',
                color: LensColors.aqua,
              ),
              _ConnectorLine(color: LensColors.violet),
              _LoopNode(
                icon: Icons.rocket_launch_rounded,
                label: 'CAREER',
                detail: 'Direct Action',
                color: LensColors.violet,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.white60, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your evidence is being used to build your defensible professional identity.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .7),
                      height: 1.4,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
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

class _ConnectorLine extends StatelessWidget {
  final Color color;
  const _ConnectorLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.5),
                color.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoopNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final Color color;

  const _LoopNode({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: .4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .2),
                blurRadius: 12,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .5),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Metrics extends StatelessWidget {
  final AcademicRepository academic;

  const _Metrics({required this.academic});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              icon: Icons.auto_stories_rounded,
              value: '${academic.courses.length}',
              label: 'Academic signals',
              color: LensColors.indigo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Metric(
              icon: Icons.bubble_chart_rounded,
              value: academic.transcript?.cumulativeGpaWithGrade ?? '—',
              label: 'Cumulative GPA',
              color: LensColors.aqua,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;

  const _SectionTitle({
    required this.title,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null && onTap != null)
          TextButton(onPressed: onTap, child: Text(action!)),
      ],
    );
  }
}

class _PromptGrid extends StatelessWidget {
  final ValueChanged<String> onPrompt;

  const _PromptGrid({required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    const prompts = [
      (
        Icons.auto_graph_rounded,
        'Analyze my skills',
        'Use my full transcript to identify my strongest career-relevant skills and the evidence for each.',
        LensColors.indigo
      ),
      (
        Icons.quiz_rounded,
        'Create a quiz',
        'Create a 10-question interactive quiz for my weakest current course.',
        LensColors.aqua
      ),
    ];
    return Row(
      children: prompts
          .map(
            (prompt) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: prompt == prompts.first ? 8 : 0,
                  left: prompt == prompts.last ? 8 : 0,
                ),
                child: LensCard(
                  onTap: () => onPrompt(prompt.$3),
                  isGlass: true,
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: prompt.$4.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(prompt.$1, color: prompt.$4, size: 20),
                        ),
                        const Spacer(),
                        Text(
                          prompt.$2,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.arrow_forward,
                            size: 14, color: LensColors.muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PillarRoutes extends StatelessWidget {
  final int courseCount;
  final VoidCallback onLearn;
  final VoidCallback onCareer;

  const _PillarRoutes({
    required this.courseCount,
    required this.onLearn,
    required this.onCareer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LensCard(
          onTap: onLearn,
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: LensColors.indigo.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: LensColors.indigo,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Academic Growth',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$courseCount courses · materials · AI practice',
                      style: const TextStyle(
                        color: LensColors.muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: LensColors.indigo,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LensCard(
          onTap: onCareer,
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: LensColors.violet.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: LensColors.violet,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Career Momentum',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Profile · opportunities · application studio',
                      style: TextStyle(
                        color: LensColors.muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: LensColors.violet,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
