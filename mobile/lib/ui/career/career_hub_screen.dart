import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class CareerHubScreen extends StatelessWidget {
  const CareerHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicRepository>();
    final cmsConnected =
        context.watch<AuthRepository>().session?.cmsConnected ?? false;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          const PageHeading(
            eyebrow: 'Career momentum',
            title: 'Career Studio',
            subtitle:
                'Turn verified evidence into role-specific applications, opportunities, and interview readiness.',
          ),
          const SizedBox(height: 20),
          _CareerHero(
            academicReady: academic.transcript != null,
            cmsConnected: cmsConnected,
          ),
          const SizedBox(height: 26),
          _SectionHeader(
            title: 'Application workspace',
            detail: 'Designed around your profile',
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 11,
            crossAxisSpacing: 11,
            childAspectRatio: .78,
            children: [
              _StudioCard(
                icon: Icons.description_outlined,
                title: 'CV Studio',
                subtitle: 'Role-tailored CVs from verified career evidence.',
                accent: LensColors.indigo,
                status: 'Foundation ready',
                onTap: () => _showWorkflow(
                  context,
                  title: 'CV Studio',
                  outcome:
                      'One source profile → many role-specific CV versions',
                  evidence: const [
                    'Academic record',
                    'GitHub projects',
                    'LinkedIn experience',
                    'Existing CV',
                    'Target job',
                  ],
                  checkpoint:
                      'You review every generated claim before a CV is exported.',
                ),
              ),
              _StudioCard(
                icon: Icons.radar_rounded,
                title: 'Opportunity Match',
                subtitle: 'Jobs and career-fair roles ranked with evidence.',
                accent: LensColors.aqua,
                status: 'Connector next',
                onTap: () => _showWorkflow(
                  context,
                  title: 'Opportunity Match',
                  outcome:
                      'Explainable matches instead of an unexplained percentage',
                  evidence: const [
                    'Career intent',
                    'Verified skills',
                    'Company websites',
                    'GIU/GUC career fair',
                    'Course history',
                  ],
                  checkpoint:
                      'You choose which opportunities enter your application pipeline.',
                ),
              ),
              _StudioCard(
                icon: Icons.mark_email_read_outlined,
                title: 'Application Kit',
                subtitle: 'Cover letters and emails in your chosen tone.',
                accent: LensColors.amber,
                status: 'Human-approved',
                onTap: () => _showWorkflow(
                  context,
                  title: 'Application Kit',
                  outcome:
                      'A tailored letter, outreach email, and reusable evidence pack',
                  evidence: const [
                    'Target role',
                    'Company language',
                    'Career profile',
                    'Custom constraints',
                    'Preferred tone',
                  ],
                  checkpoint:
                      'Nothing is sent until you inspect, modify, and approve it.',
                ),
              ),
              _StudioCard(
                icon: Icons.record_voice_over_outlined,
                title: 'Interview Lab',
                subtitle:
                    'Questions grounded in the role and your own evidence.',
                accent: LensColors.violet,
                status: 'Practice layer',
                onTap: () => _showWorkflow(
                  context,
                  title: 'Interview Lab',
                  outcome:
                      'Role-specific practice with evidence-backed answer coaching',
                  evidence: const [
                    'Job description',
                    'Company research',
                    'Your projects',
                    'Academic strengths',
                    'Prior practice',
                  ],
                  checkpoint:
                      'Feedback distinguishes facts about you from suggested framing.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionHeader(
            title: 'The human checkpoint',
            detail: 'Agentic, never autonomous by surprise',
          ),
          const SizedBox(height: 12),
          const _ApprovalFlow(),
          const SizedBox(height: 26),
          _ProfileBridge(
            onTap: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showWorkflow(
    BuildContext context, {
    required String title,
    required String outcome,
    required List<String> evidence,
    required String checkpoint,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(outcome, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              const Text(
                'EVIDENCE PIPELINE',
                style: TextStyle(
                  color: LensColors.indigo,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: evidence
                    .map(
                      (item) => Chip(
                        avatar: const Icon(Icons.add_link_rounded, size: 15),
                        label: Text(item),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: LensColors.aqua.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: LensColors.aqua,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        checkpoint,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'This workspace is staged for the next connector sprint. CareerLoop labels readiness honestly until its source tools are connected.',
                style: TextStyle(color: LensColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CareerHero extends StatelessWidget {
  final bool academicReady;
  final bool cmsConnected;

  const _CareerHero({
    required this.academicReady,
    required this.cmsConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LensColors.ink, Color(0xFF1E1B4B)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: LensColors.violet.withValues(alpha: .28),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GradientPill(
            label: 'EVIDENCE NETWORK',
            icon: Icons.hub_rounded,
            dark: true,
          ),
          const SizedBox(height: 24),
          const Text(
            'Your identity becomes\ndefensible with data.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1.1,
              letterSpacing: -0.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _Signal(
                label: 'ACADEMICS',
                live: academicReady,
              ),
              _FlowLine(active: academicReady),
              _Signal(
                label: 'LEARNING',
                live: cmsConnected,
              ),
              _FlowLine(active: cmsConnected),
              const _Signal(
                label: 'CAREER',
                live: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Signal extends StatelessWidget {
  final String label;
  final bool live;

  const _Signal({required this.label, required this.live});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (live ? LensColors.aqua : Colors.white)
                  .withValues(alpha: live ? .2 : .08),
              shape: BoxShape.circle,
              border: Border.all(
                color: live
                    ? LensColors.aqua.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: .1),
                width: 1.5,
              ),
              boxShadow: live
                  ? [
                      BoxShadow(
                        color: LensColors.aqua.withValues(alpha: 0.2),
                        blurRadius: 10,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              live ? Icons.verified_rounded : Icons.add_rounded,
              color: live ? LensColors.aqua : Colors.white24,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: live ? .9 : .4),
              fontSize: 9,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowLine extends StatelessWidget {
  final bool active;
  const _FlowLine({this.active = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (active ? LensColors.aqua : Colors.white).withValues(alpha: 0.2),
              (active ? LensColors.aqua : Colors.white).withValues(alpha: 0.05),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudioCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color accent;
  final VoidCallback onTap;

  const _StudioCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: onTap,
      isGlass: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: LensColors.muted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: accent,
                  fontSize: 9,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApprovalFlow extends StatelessWidget {
  const _ApprovalFlow();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.auto_awesome_rounded, 'Propose'),
      (Icons.rate_review_outlined, 'Review'),
      (Icons.task_alt_rounded, 'Approve'),
      (Icons.send_rounded, 'Act'),
    ];
    return LensCard(
      color: LensColors.ink,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: steps
            .map(
              (step) => Expanded(
                child: Column(
                  children: [
                    Icon(step.$1, color: LensColors.aqua, size: 20),
                    const SizedBox(height: 8),
                    Text(
                      step.$2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProfileBridge extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileBridge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: const Row(
        children: [
          Icon(Icons.account_circle_outlined, color: LensColors.indigo),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your profile powers every workspace',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Inspect the evidence CareerLoop can use today.',
                  style: TextStyle(color: LensColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: LensColors.indigo),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String detail;

  const _SectionHeader({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Flexible(
          child: Text(
            detail,
            textAlign: TextAlign.end,
            style: const TextStyle(color: LensColors.muted, fontSize: 10),
          ),
        ),
      ],
    );
  }
}
