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
    final academicReady =
        context.watch<AcademicRepository>().transcript != null;
    final cmsReady =
        context.watch<AuthRepository>().session?.cmsConnected ?? false;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Career Studio',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Build from evidence,\nnot from a blank page.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 7),
          const Text(
            'Choose an outcome. CareerLoop will show which sources it needs '
            'and where you stay in control.',
            style: TextStyle(color: LensColors.muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          _ReadinessStrip(
            academicReady: academicReady,
            learningReady: cmsReady,
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Choose a workflow',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Text(
                'Preview',
                style: TextStyle(color: LensColors.muted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LensCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _WorkflowRow(
                  icon: Icons.description_outlined,
                  color: LensColors.indigo,
                  title: 'CV Studio',
                  subtitle: 'Create a role-specific, evidence-backed CV',
                  status: 'Foundation ready',
                  onTap: () => _showWorkflow(
                    context,
                    title: 'CV Studio',
                    outcome:
                        'Turn one verified profile into focused CV versions.',
                    evidence: const [
                      'Academic record',
                      'GitHub projects',
                      'Professional profile',
                      'Existing CV',
                      'Target role',
                    ],
                    checkpoint:
                        'You approve every claim before anything is exported.',
                  ),
                ),
                const Divider(height: 1, indent: 58),
                _WorkflowRow(
                  icon: Icons.radar_rounded,
                  color: LensColors.aqua,
                  title: 'Opportunity Match',
                  subtitle: 'Rank roles and explain why they fit',
                  status: 'Connector next',
                  onTap: () => _showWorkflow(
                    context,
                    title: 'Opportunity Match',
                    outcome:
                        'Get explainable role matches instead of a black-box score.',
                    evidence: const [
                      'Career intent',
                      'Verified skills',
                      'Company websites',
                      'Career-fair roles',
                      'Course history',
                    ],
                    checkpoint:
                        'You decide which opportunities enter your pipeline.',
                  ),
                ),
                const Divider(height: 1, indent: 58),
                _WorkflowRow(
                  icon: Icons.mark_email_read_outlined,
                  color: LensColors.amber,
                  title: 'Application Kit',
                  subtitle: 'Prepare cover letters and outreach',
                  status: 'Approval required',
                  onTap: () => _showWorkflow(
                    context,
                    title: 'Application Kit',
                    outcome:
                        'Draft a tailored letter, email, and evidence pack.',
                    evidence: const [
                      'Target role',
                      'Company language',
                      'Career profile',
                      'Custom constraints',
                      'Preferred tone',
                    ],
                    checkpoint:
                        'Nothing is sent until you inspect and approve it.',
                  ),
                ),
                const Divider(height: 1, indent: 58),
                _WorkflowRow(
                  icon: Icons.record_voice_over_outlined,
                  color: LensColors.violet,
                  title: 'Interview Lab',
                  subtitle: 'Practice against the role and your profile',
                  status: 'Practice layer',
                  onTap: () => _showWorkflow(
                    context,
                    title: 'Interview Lab',
                    outcome:
                        'Practice role-specific questions with grounded coaching.',
                    evidence: const [
                      'Job description',
                      'Company research',
                      'Your projects',
                      'Academic strengths',
                      'Practice history',
                    ],
                    checkpoint:
                        'Feedback separates verified facts from suggested framing.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _HumanControlNote(),
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
              Text(
                outcome,
                style: const TextStyle(color: LensColors.muted),
              ),
              const SizedBox(height: 20),
              const Text(
                'REQUIRED EVIDENCE',
                style: TextStyle(
                  color: LensColors.indigo,
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: evidence
                    .map(
                      (item) => Chip(
                        avatar: const Icon(Icons.add_link_rounded, size: 14),
                        label: Text(item),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 17),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: LensColors.aqua.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: LensColors.aqua,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        checkpoint,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'This workflow remains a preview until its external '
                'connectors are enabled.',
                style: TextStyle(color: LensColors.muted, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadinessStrip extends StatelessWidget {
  final bool academicReady;
  final bool learningReady;

  const _ReadinessStrip({
    required this.academicReady,
    required this.learningReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LensColors.ink,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Text(
            'PROFILE READINESS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 8.5,
              letterSpacing: .8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          _ReadinessItem(label: 'Academics', ready: academicReady),
          const SizedBox(width: 14),
          _ReadinessItem(label: 'Learning', ready: learningReady),
        ],
      ),
    );
  }
}

class _ReadinessItem extends StatelessWidget {
  final String label;
  final bool ready;

  const _ReadinessItem({required this.label, required this.ready});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ready ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 14,
          color: ready ? LensColors.aqua : Colors.white38,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: ready ? Colors.white : Colors.white54,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WorkflowRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback onTap;

  const _WorkflowRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: LensColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 8,
              letterSpacing: .4,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: LensColors.muted,
      ),
      onTap: onTap,
    );
  }
}

class _HumanControlNote extends StatelessWidget {
  const _HumanControlNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.verified_user_outlined,
          color: LensColors.aqua,
          size: 19,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'CareerLoop proposes. You review, modify, and approve before any '
            'external action.',
            style: TextStyle(
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
