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
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Expanded(child: LensLogo(size: 38)),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: LensColors.line),
                      ),
                      child: IconButton(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.tune_rounded, size: 20),
                        color: LensColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 140),
              sliver: SliverList.list(
                children: [
                  const _BentoHeader(),
                  const SizedBox(height: 24),
                  if (session != null && !session.cmsConnected) ...[
                    CmsAccessNotice(message: session.cmsMessage),
                    const SizedBox(height: 18),
                  ],
                  const _FocusHero(),
                  const SizedBox(height: 24),
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
                    _BentoMetricsGrid(academic: academic),
                    const SizedBox(height: 32),
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
                    const SizedBox(height: 32),
                    const _SectionTitle(
                      title: 'Growth loops',
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

class _BentoHeader extends StatelessWidget {
  const _BentoHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: LensColors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'WORKSPACE V1.0',
                style: TextStyle(
                  color: LensColors.indigo,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Academic evidence.\nCareer momentum.',
          style: TextStyle(
            fontSize: 34,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            color: LensColors.ink,
          ),
        ),
      ],
    );
  }
}

class _BentoMetricsGrid extends StatelessWidget {
  final AcademicRepository academic;
  const _BentoMetricsGrid({required this.academic});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: LensCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bubble_chart_rounded,
                    color: LensColors.aqua, size: 24),
                const SizedBox(height: 28),
                Text(
                  academic.transcript?.cumulativeGpaWithGrade ?? '—',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cumulative GPA',
                  style: TextStyle(
                    color: LensColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              LensCard(
                padding: const EdgeInsets.all(18),
                color: LensColors.ink,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_stories_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(height: 16),
                    Text(
                      '${academic.courses.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Signals',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LensCard(
                padding: const EdgeInsets.all(18),
                isGlass: true,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_rounded,
                        color: LensColors.indigo, size: 20),
                    const SizedBox(height: 16),
                    Text(
                      '94%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
            Color(0xFF27272A), // Zinc 800
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: LensColors.ink.withValues(alpha: .2),
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
                  color: Colors.white.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: .1)),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: LensColors.aqua,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agentic Copilot',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Evidence Network Active',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const GradientPill(
                label: 'LIVE',
                icon: Icons.bolt_rounded,
                dark: true,
              ),
            ],
          ),
          const SizedBox(height: 36),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeroNode(
                icon: Icons.school_rounded,
                label: 'Verified Facts',
                color: LensColors.indigo,
              ),
              _HeroConnector(),
              _HeroNode(
                icon: Icons.hub_rounded,
                label: 'Smart Context',
                color: LensColors.aqua,
              ),
              _HeroConnector(),
              _HeroNode(
                icon: Icons.rocket_launch_rounded,
                label: 'Direct Action',
                color: LensColors.violet,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeroNode(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _HeroConnector extends StatelessWidget {
  const _HeroConnector();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0),
              ],
            ),
          ),
        ),
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
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: LensColors.ink,
            ),
          ),
        ),
        if (action != null && onTap != null)
          TextButton(
            onPressed: onTap,
            child: Row(
              children: [
                Text(action!),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 10),
              ],
            ),
          ),
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
        'Analyze skills',
        'Use my full transcript to identify my strongest career-relevant skills.',
        LensColors.indigo
      ),
      (
        Icons.quiz_rounded,
        'Create quiz',
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
                    height: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(prompt.$1, color: prompt.$4, size: 22),
                        const Spacer(),
                        Text(
                          prompt.$2,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.arrow_forward_rounded,
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
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: LensColors.indigo.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_stories_rounded,
                    color: LensColors.indigo),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Academic Growth',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      '$courseCount courses · materials · practice',
                      style: const TextStyle(
                          color: LensColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: LensColors.muted),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LensCard(
          onTap: onCareer,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: LensColors.violet.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.rocket_launch_rounded,
                    color: LensColors.violet),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Career Momentum',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      'Profile · matching · applications',
                      style: TextStyle(color: LensColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: LensColors.muted),
            ],
          ),
        ),
      ],
    );
  }
}
