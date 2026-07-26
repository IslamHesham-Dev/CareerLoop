import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/practice_repository.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    final academicReady = academic.transcript != null;
    final cmsReady = session?.cmsConnected ?? false;
    final liveSignals = (academicReady ? 1 : 0) + (cmsReady ? 1 : 0);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          Row(
            children: [
              const Expanded(
                child: PageHeading(
                  eyebrow: 'Unified candidate profile',
                  title: 'Your evidence,\none identity.',
                  subtitle:
                      'Academic achievements and career signals stay traceable, reusable, and under your control.',
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Settings',
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ProfileHero(
            liveSignals: liveSignals,
            totalSignals: 5,
            gpa: academic.transcript?.cumulativeGpaWithGrade ?? '—',
          ),
          const SizedBox(height: 26),
          _Header(
            title: 'Evidence sources',
            detail: '$liveSignals live · 5 designed',
          ),
          const SizedBox(height: 12),
          _EvidenceSource(
            icon: Icons.school_outlined,
            title: 'Academic record',
            subtitle: 'Transcript, grades, and semester history',
            status: academicReady ? 'LIVE' : 'SYNCING',
            color: LensColors.indigo,
          ),
          const SizedBox(height: 9),
          _EvidenceSource(
            icon: Icons.auto_stories_outlined,
            title: 'Learning evidence',
            subtitle: cmsReady
                ? 'CMS materials, video transcripts, and practice'
                : 'CMS access limited; local practice remains available',
            status: cmsReady ? 'LIVE' : 'LIMITED',
            color: cmsReady ? LensColors.aqua : LensColors.amber,
          ),
          const SizedBox(height: 9),
          const _EvidenceSource(
            icon: Icons.code_rounded,
            title: 'Projects & repositories',
            subtitle: 'GitHub skills, languages, and project momentum',
            status: 'NEXT',
            color: LensColors.violet,
          ),
          const SizedBox(height: 9),
          const _EvidenceSource(
            icon: Icons.badge_outlined,
            title: 'Professional identity',
            subtitle: 'LinkedIn experience, skills, and positioning',
            status: 'PLANNED',
            color: LensColors.muted,
          ),
          const SizedBox(height: 9),
          const _EvidenceSource(
            icon: Icons.description_outlined,
            title: 'Career documents',
            subtitle: 'CV versions, constraints, and approved claims',
            status: 'PLANNED',
            color: LensColors.muted,
          ),
          const SizedBox(height: 26),
          const _Header(
            title: 'Profile layers',
            detail: 'One source of truth',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LayerCard(
                  icon: Icons.analytics_outlined,
                  title: 'Academic',
                  value: '${academic.courses.length} courses',
                  color: LensColors.indigo,
                  onTap: () => context.push('/transcript'),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _LayerCard(
                  icon: Icons.quiz_outlined,
                  title: 'Practice',
                  value: '$practiceCount saved sets',
                  color: LensColors.violet,
                  onTap: () => context.push('/practice'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _CareerIntentCard(
            onTap: () => context.go('/career'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final int liveSignals;
  final int totalSignals;
  final String gpa;

  const _ProfileHero({
    required this.liveSignals,
    required this.totalSignals,
    required this.gpa,
  });

  @override
  Widget build(BuildContext context) {
    final progress = liveSignals / totalSignals;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LensColors.ink, Color(0xFF223D57)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    backgroundColor: Colors.white.withValues(alpha: .09),
                    color: LensColors.aqua,
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROFILE SIGNALS',
                  style: TextStyle(
                    color: LensColors.aqua,
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$liveSignals of $totalSignals evidence layers connected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Current academic GPA $gpa',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .58),
                    fontSize: 11,
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

class _EvidenceSource extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color color;

  const _EvidenceSource({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(14),
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
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _LayerCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 18),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(color: LensColors.muted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _CareerIntentCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CareerIntentCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: onTap,
      color: LensColors.indigo,
      padding: const EdgeInsets.all(18),
      child: const Row(
        children: [
          Icon(Icons.explore_outlined, color: Colors.white),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shape your career intent',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Roles, companies, constraints, and preferred direction.',
                  style: TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String detail;

  const _Header({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Text(
          detail,
          style: const TextStyle(color: LensColors.muted, fontSize: 10),
        ),
      ],
    );
  }
}
