import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/career_profile_repository.dart';
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
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
        children: [
          const PageHeading(
            eyebrow: 'Career momentum',
            title: 'Career Studio',
            subtitle:
                'Turn verified evidence into role-specific applications, opportunities, and interview readiness.',
          ),
          const SizedBox(height: 24),
          _CareerHero(
            academicReady: academic.transcript != null,
            cmsConnected: cmsConnected,
            careerReady: careerProfile.hasProfile,
          ),
          const SizedBox(height: 32),
          const _SectionHeader(
            title: 'Professional evidence',
            detail: 'Connect sources',
          ),
          const SizedBox(height: 12),
          _LinkedInConnectorCard(
            connected: careerProfile.hasProfile,
            name: careerProfile.profile?.name,
            onTap: () => context.push('/linkedin-profile'),
          ),
          const SizedBox(height: 32),
          const _SectionHeader(
            title: 'Application workspace',
            detail: 'Agentic tools',
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
            children: [
              _StudioCard(
                icon: Icons.description_outlined,
                title: 'CV Studio',
                subtitle: 'Role-tailored CVs from verified career evidence.',
                accent: LensColors.indigo,
                status: 'Ready',
                onTap: () {},
              ),
              _StudioCard(
                icon: Icons.radar_rounded,
                title: 'Opportunity Match',
                subtitle: 'Jobs and career-fair roles ranked with evidence.',
                accent: LensColors.aqua,
                status: 'Beta',
                onTap: () {},
              ),
              _StudioCard(
                icon: Icons.mark_email_read_outlined,
                title: 'Application Kit',
                subtitle: 'Cover letters and emails in your chosen tone.',
                accent: LensColors.amber,
                status: 'Drafting',
                onTap: () {},
              ),
              _StudioCard(
                icon: Icons.record_voice_over_outlined,
                title: 'Interview Lab',
                subtitle:
                    'Questions grounded in the role and your own evidence.',
                accent: LensColors.violet,
                status: 'Practice',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),
          const _SectionHeader(
            title: 'Human checkpoint',
            detail: 'Approval workflow',
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LensColors.ink, Color(0xFF27272A)],
        ),
        borderRadius: BorderRadius.circular(32),
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
              fontSize: 28,
              height: 1.1,
              letterSpacing: -1.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _SignalNode(label: 'ACADEMICS', live: academicReady),
              _SignalFlow(active: academicReady),
              _SignalNode(label: 'LEARNING', live: cmsConnected),
              _SignalFlow(active: cmsConnected),
              _SignalNode(label: 'CAREER', live: careerReady),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalNode extends StatelessWidget {
  final String label;
  final bool live;

  const _SignalNode({required this.label, required this.live});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
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

class _SignalFlow extends StatelessWidget {
  final bool active;
  const _SignalFlow({this.active = false});

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
                (active ? LensColors.aqua : Colors.white)
                    .withValues(alpha: 0.2),
                (active ? LensColors.aqua : Colors.white)
                    .withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
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
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const LinkedInBrandMark(size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LinkedIn profile',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2),
                ),
                Text(
                  connected
                      ? '${name ?? 'Professional profile'} · Linked'
                      : 'Sync your career evidence',
                  style: const TextStyle(color: LensColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (connected)
            const Icon(Icons.check_circle_rounded,
                color: LensColors.aqua, size: 20)
          else
            const Icon(Icons.add_circle_outline_rounded,
                color: linkedInBlue, size: 20),
        ],
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: LensColors.muted, fontSize: 10.5, height: 1.3),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: 5,
                  height: 5,
                  decoration:
                      BoxDecoration(color: accent, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5),
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
      padding: const EdgeInsets.all(22),
      borderRadius: 24,
      child: Row(
        children: steps
            .map(
              (step) => Expanded(
                child: Column(
                  children: [
                    Icon(step.$1, color: LensColors.aqua, size: 22),
                    const SizedBox(height: 10),
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
      padding: const EdgeInsets.all(20),
      child: const Row(
        children: [
          Icon(Icons.account_circle_outlined, color: LensColors.indigo),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identity source',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.2),
                ),
                Text(
                  'Manage your connected professional data.',
                  style: TextStyle(color: LensColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: LensColors.muted),
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
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          ),
        ),
        Text(
          detail.toUpperCase(),
          style: const TextStyle(
              color: LensColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5),
        ),
      ],
    );
  }
}
