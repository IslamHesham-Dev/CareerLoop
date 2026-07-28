import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../app/theme.dart';
import '../../data/career_profile_repository.dart';
import '../../data/current_cv_repository.dart';
import '../../data/github_profile_repository.dart';
import '../../data/practice_repository.dart';
import '../../data/repositories.dart';
import '../../data/tone_repository.dart';
import '../core/brand_marks.dart';
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
    final careerProfile = context.watch<CareerProfileRepository>();
    final linkedInReady = careerProfile.hasProfile;
    final github = context.watch<GithubProfileRepository>();
    final githubReady = github.hasProfile;
    final resume = context.watch<CurrentCvRepository>();
    final resumeReady = resume.hasProfile;
    final tone = context.watch<ToneRepository>();
    final liveSignals = (academicReady ? 1 : 0) +
        (cmsReady ? 1 : 0) +
        (linkedInReady ? 1 : 0) +
        (githubReady ? 1 : 0) +
        (resumeReady ? 1 : 0);
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
          _LinkedInConnectorCard(
            connected: linkedInReady,
            name: careerProfile.profile?.name,
            onTap: () => context.push('/linkedin-profile'),
          ),
          const SizedBox(height: 9),
          _GithubConnectorCard(
            connected: githubReady,
            login: github.profile?.login,
            repositoryCount: github.profile?.analyzedRepositoryCount ?? 0,
            onTap: () => context.push('/github-profile'),
          ),
          const SizedBox(height: 9),
          _ResumeConnectorCard(
            connected: resumeReady,
            fileName: resume.currentCv?.fileName,
            skillCount: resume.profile?.skills.length ?? 0,
            onTap: () => context.push('/resume-profile'),
          ),
          const SizedBox(height: 26),
          _Header(
            title: 'Personalize your voice',
            detail: tone.hasProfile ? 'Agent ready' : 'Optional',
          ),
          const SizedBox(height: 12),
          _ToneConnectorCard(
            connected: tone.hasProfile,
            answeredCount:
                tone.answers.values.where((a) => a.trim().isNotEmpty).length,
            onTap: () => context.push('/tone-profile'),
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
  final Widget? brand;
  final String title;
  final String subtitle;
  final String status;
  final Color color;
  final VoidCallback? onTap;

  const _EvidenceSource({
    required this.icon,
    this.brand,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: onTap,
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
            child: brand ?? Icon(icon, color: color, size: 20),
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

/// Evidence connector cards, transplanted from what used to be Career
/// Studio's "Professional evidence" section — Profile is now the single
/// home for connecting LinkedIn, GitHub, and resume evidence.
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

/// Entry point for `app.tone` onboarding ("Add your tone"). Deliberately
/// styled apart from the three evidence connectors above - it isn't a
/// verified-evidence source, it's a style preference the agent uses when
/// writing on the student's behalf - so it's not counted in the "N of 5
/// evidence layers" hero metric.
class _ToneConnectorCard extends StatelessWidget {
  final bool connected;
  final int answeredCount;
  final VoidCallback onTap;

  const _ToneConnectorCard({
    required this.connected,
    required this.answeredCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: onTap,
      color: connected ? LensColors.violet.withValues(alpha: .065) : null,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (connected ? LensColors.violet : LensColors.indigo)
                  .withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.record_voice_over_rounded,
              color: connected ? LensColors.violet : LensColors.indigo,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add your tone',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  connected
                      ? '$answeredCount of 4 questions answered · agent ready'
                      : 'Teach the agent to write like you, not a template',
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
                  'Add',
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
