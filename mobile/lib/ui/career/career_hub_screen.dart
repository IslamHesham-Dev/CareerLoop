import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../app/theme.dart';
import '../../data/career_profile_repository.dart';
import '../../data/current_cv_repository.dart';
import '../../data/github_profile_repository.dart';
import '../../data/repositories.dart';
import '../core/brand_marks.dart';
import '../core/lens_components.dart';

class CareerHubScreen extends StatelessWidget {
  const CareerHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicRepository>();
    final cmsConnected =
        context.watch<AuthRepository>().session?.cmsConnected ?? false;
    final careerProfile = context.watch<CareerProfileRepository>();
    final githubProfile = context.watch<GithubProfileRepository>();
    final resume = context.watch<CurrentCvRepository>();
    final professionalSources = (careerProfile.hasProfile ? 1 : 0) +
        (githubProfile.hasProfile ? 1 : 0) +
        (resume.hasProfile ? 1 : 0);
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
            careerReady: careerProfile.hasProfile ||
                githubProfile.hasProfile ||
                resume.hasProfile,
          ),
          const SizedBox(height: 26),
          _SectionHeader(
            title: 'Professional evidence',
            detail: professionalSources == 0
                ? 'Connect a source'
                : '$professionalSources sources live',
          ),
          const SizedBox(height: 12),
          _LinkedInConnectorCard(
            connected: careerProfile.hasProfile,
            name: careerProfile.profile?.name,
            onTap: () => context.push('/linkedin-profile'),
          ),
          const SizedBox(height: 10),
          _GithubConnectorCard(
            connected: githubProfile.hasProfile,
            login: githubProfile.profile?.login,
            repositoryCount:
                githubProfile.profile?.analyzedRepositoryCount ?? 0,
            onTap: () => context.push('/github-profile'),
          ),
          const SizedBox(height: 10),
          _ResumeConnectorCard(
            connected: resume.hasProfile,
            fileName: resume.currentCv?.fileName,
            skillCount: resume.profile?.skills.length ?? 0,
            onTap: () => context.push('/resume-profile'),
          ),
          const SizedBox(height: 28),
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
                subtitle: 'Live roles ranked against your verified evidence.',
                accent: LensColors.aqua,
                status: 'SWElist live',
                onTap: () => context.push('/opportunities'),
              ),
              _StudioCard(
                icon: Icons.forward_to_inbox_rounded,
                title: 'Post to Application',
                subtitle:
                    'Turn a LinkedIn job post into a reviewed Gmail application.',
                accent: LensColors.amber,
                status: 'Gmail action',
                onTap: () => context.push('/quick-apply'),
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
  final bool careerReady;

  const _CareerHero({
    required this.academicReady,
    required this.cmsConnected,
    required this.careerReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LensColors.ink, Color(0xFF34236E)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: LensColors.violet.withValues(alpha: .24),
            blurRadius: 34,
            offset: const Offset(0, 17),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GradientPill(
            label: 'Evidence network',
            icon: Icons.hub_outlined,
            dark: true,
          ),
          const SizedBox(height: 18),
          const Text(
            'Your profile becomes\nstronger with every signal.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.1,
              letterSpacing: -.6,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Signal(
                label: 'Academics',
                live: academicReady,
              ),
              const _FlowLine(),
              _Signal(
                label: 'Learning',
                live: cmsConnected,
              ),
              const _FlowLine(),
              _Signal(
                label: 'Career',
                live: careerReady,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkedInConnectorCard extends StatelessWidget {
  final bool connected;
  final String? name;
  final VoidCallback onTap;

  const _LinkedInConnectorCard({
    required this.connected,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const linkedInBlue = Color(0xFF0A66C2);
    return LensCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const LinkedInBrandMark(size: 46),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LinkedIn profile',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  connected
                      ? '${name ?? 'Professional profile'} · PDF connected'
                      : 'Import the PDF generated by LinkedIn',
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
          if (connected)
            const Icon(Icons.check_circle_rounded, color: LensColors.aqua)
          else
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Connect',
                  style: TextStyle(
                    color: linkedInBlue,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: linkedInBlue,
                  size: 19,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GithubConnectorCard extends StatelessWidget {
  final bool connected;
  final String? login;
  final int repositoryCount;
  final VoidCallback onTap;

  const _GithubConnectorCard({
    required this.connected,
    required this.login,
    required this.repositoryCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LensColors.ink,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              SimpleIcons.github,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GitHub projects',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  connected
                      ? '@${login ?? 'profile'} · $repositoryCount repositories analyzed'
                      : 'Connect public repositories as skill evidence',
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
          if (connected)
            const Icon(Icons.check_circle_rounded, color: LensColors.aqua)
          else
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Connect',
                  style: TextStyle(
                    color: LensColors.ink,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: LensColors.ink,
                  size: 19,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ResumeConnectorCard extends StatelessWidget {
  final bool connected;
  final String? fileName;
  final int skillCount;
  final VoidCallback onTap;

  const _ResumeConnectorCard({
    required this.connected,
    required this.fileName,
    required this.skillCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: onTap,
      color: connected ? LensColors.aqua.withValues(alpha: .065) : null,
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (connected ? LensColors.aqua : LensColors.indigo)
                  .withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.description_outlined,
              color: connected ? LensColors.aqua : LensColors.indigo,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Resume evidence',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (connected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: LensColors.aqua.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'AGENT READY',
                          style: TextStyle(
                            color: Color(0xFF168D80),
                            fontSize: 7.5,
                            letterSpacing: .6,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  connected
                      ? fileName ?? 'Current resume'
                      : 'Upload a PDF for agent-ready career context',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: connected ? LensColors.ink : LensColors.muted,
                    fontSize: 10.5,
                    fontWeight: connected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (connected) ...[
                  const SizedBox(height: 3),
                  Text(
                    'PDF uploaded · $skillCount skills extracted',
                    style: const TextStyle(
                      color: LensColors.muted,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!connected)
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Import',
                  style: TextStyle(
                    color: LensColors.indigo,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: LensColors.indigo,
                  size: 19,
                ),
              ],
            )
          else
            const Icon(
              Icons.chevron_right_rounded,
              color: LensColors.aqua,
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (live ? LensColors.aqua : Colors.white)
                  .withValues(alpha: live ? .16 : .08),
              shape: BoxShape.circle,
              border: Border.all(
                color: live
                    ? LensColors.aqua
                    : Colors.white.withValues(alpha: .16),
              ),
            ),
            child: Icon(
              live ? Icons.check_rounded : Icons.add_rounded,
              color: live ? LensColors.aqua : Colors.white54,
              size: 19,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: live ? .9 : .5),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowLine extends StatelessWidget {
  const _FlowLine();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1,
        color: Colors.white.withValues(alpha: .16),
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
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: LensColors.muted,
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: accent,
              fontSize: 8.5,
              letterSpacing: .7,
              fontWeight: FontWeight.w900,
            ),
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
