import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/practice_repository.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

enum _ProfileView { academic, career }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  _ProfileView _view = _ProfileView.academic;

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

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'The evidence CareerLoop can safely use.',
                      style: TextStyle(color: LensColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _IdentitySummary(
            gpa: academic.transcript?.cumulativeGpaWithGrade ?? '—',
            courseCount: academic.courses.length,
            liveSources: (academicReady ? 1 : 0) + (cmsReady ? 1 : 0),
          ),
          const SizedBox(height: 18),
          SegmentedButton<_ProfileView>(
            segments: const [
              ButtonSegment(
                value: _ProfileView.academic,
                icon: Icon(Icons.school_outlined, size: 18),
                label: Text('Academic'),
              ),
              ButtonSegment(
                value: _ProfileView.career,
                icon: Icon(Icons.work_outline_rounded, size: 18),
                label: Text('Career'),
              ),
            ],
            selected: {_view},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              setState(() => _view = selection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_view == _ProfileView.academic)
            _AcademicProfile(
              transcriptReady: academicReady,
              cmsReady: cmsReady,
              cmsMessage: session?.cmsMessage,
              courseCount: academic.courses.length,
              practiceCount: practiceCount,
            )
          else
            const _CareerProfile(),
        ],
      ),
    );
  }
}

class _IdentitySummary extends StatelessWidget {
  final String gpa;
  final int courseCount;
  final int liveSources;

  const _IdentitySummary({
    required this.gpa,
    required this.courseCount,
    required this.liveSources,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LensColors.ink,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: LensColors.aqua.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: LensColors.aqua,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gpa,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$courseCount current courses · $liveSources live sources',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .55),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_outlined,
            color: LensColors.aqua,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _AcademicProfile extends StatelessWidget {
  final bool transcriptReady;
  final bool cmsReady;
  final String? cmsMessage;
  final int courseCount;
  final int practiceCount;

  const _AcademicProfile({
    required this.transcriptReady,
    required this.cmsReady,
    required this.cmsMessage,
    required this.courseCount,
    required this.practiceCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Connected evidence',
          detail: '${(transcriptReady ? 1 : 0) + (cmsReady ? 1 : 0)} live',
        ),
        const SizedBox(height: 10),
        LensCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SourceRow(
                icon: Icons.account_balance_outlined,
                title: 'GIU Portal',
                subtitle: transcriptReady
                    ? 'Transcript and $courseCount semester courses'
                    : 'Waiting for transcript data',
                status: transcriptReady ? 'Live' : 'Syncing',
                color: LensColors.indigo,
              ),
              const Divider(height: 1, indent: 56),
              _SourceRow(
                icon: Icons.auto_stories_outlined,
                title: 'GIU CMS',
                subtitle: cmsReady
                    ? 'Course files, recordings, and transcripts'
                    : (cmsMessage ?? 'Unavailable for this account'),
                status: cmsReady ? 'Live' : 'Limited',
                color: cmsReady ? LensColors.aqua : LensColors.amber,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'Your records',
          detail: 'Private to your session',
        ),
        const SizedBox(height: 10),
        _ActionRow(
          icon: Icons.analytics_outlined,
          title: 'Academic record',
          subtitle: 'Browse transcript years and grade history',
          action: 'Open',
          onTap: () => context.push('/transcript'),
        ),
        const SizedBox(height: 9),
        _ActionRow(
          icon: Icons.quiz_outlined,
          title: 'Practice library',
          subtitle: '$practiceCount saved interactive quizzes',
          action: 'Open',
          onTap: () => context.push('/practice'),
        ),
      ],
    );
  }
}

class _CareerProfile extends StatelessWidget {
  const _CareerProfile();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Career evidence',
          detail: 'Connector roadmap',
        ),
        const SizedBox(height: 10),
        const LensCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SourceRow(
                icon: Icons.code_rounded,
                title: 'GitHub',
                subtitle: 'Projects, languages, and contribution signals',
                status: 'Next',
                color: LensColors.violet,
              ),
              Divider(height: 1, indent: 56),
              _SourceRow(
                icon: Icons.badge_outlined,
                title: 'Professional profile',
                subtitle: 'Experience, skills, and approved career claims',
                status: 'Planned',
                color: LensColors.muted,
              ),
              Divider(height: 1, indent: 56),
              _SourceRow(
                icon: Icons.description_outlined,
                title: 'CV repository',
                subtitle: 'Versioned CVs and role-specific constraints',
                status: 'Planned',
                color: LensColors.muted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _CareerStudioEntry(onTap: () => context.push('/career')),
      ],
    );
  }
}

class _SourceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color color;

  const _SourceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 7, 12, 7),
      leading: Icon(icon, color: color, size: 21),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: LensColors.muted, fontSize: 10),
      ),
      trailing: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          letterSpacing: .5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
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
          Icon(icon, color: LensColors.indigo, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            action,
            style: const TextStyle(
              color: LensColors.indigo,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: LensColors.indigo,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _CareerStudioEntry extends StatelessWidget {
  final VoidCallback onTap;

  const _CareerStudioEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: onTap,
      color: LensColors.ink,
      padding: const EdgeInsets.all(17),
      child: const Row(
        children: [
          Icon(Icons.rocket_launch_outlined, color: LensColors.aqua),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open Career Studio',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'See how evidence becomes applications.',
                  style: TextStyle(color: Colors.white60, fontSize: 10.5),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: LensColors.aqua),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String detail;

  const _SectionTitle({required this.title, required this.detail});

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
