import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../app/theme.dart';
import '../../data/career_profile_repository.dart';
import '../../data/current_cv_repository.dart';
import '../../data/github_profile_repository.dart';
import '../../data/repositories.dart';
import '../../data/tone_profile_repository.dart';
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
    final academicReady = academic.transcript != null;
    final careerProfile = context.watch<CareerProfileRepository>();
    final linkedInReady = careerProfile.hasProfile;
    final github = context.watch<GithubProfileRepository>();
    final githubReady = github.hasProfile;
    final resume = context.watch<CurrentCvRepository>();
    final resumeReady = resume.hasProfile;
    final tone = context.watch<ToneProfileRepository>();
    final liveSignals = (academicReady ? 1 : 0) +
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
                      'The information CareerLoop can use on your behalf.',
                      style: TextStyle(color: LensColors.muted),
                    ),
                  ],
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
            totalSignals: 4,
            gpa: academic.transcript?.cumulativeGpaWithGrade ?? '—',
          ),
          const SizedBox(height: 26),
          _Header(
            title: 'Evidence sources',
            detail: '$liveSignals of 4 connected',
          ),
          const SizedBox(height: 12),
          _EvidenceSource(
            icon: Icons.school_outlined,
            title: 'Academic record',
            subtitle: 'Transcript, grades, and semester history',
            status: academicReady ? 'LIVE' : 'SYNCING',
            color: LensColors.indigo,
            onTap: () => context.push('/transcript'),
          ),
          const SizedBox(height: 9),
          _GithubConnectorCard(
            connected: githubReady,
            login: github.profile?.login,
            repositoryCount: github.profile?.analyzedRepositoryCount ?? 0,
            onTap: () => context.push('/github-profile'),
          ),
          const SizedBox(height: 9),
          _LinkedInConnectorCard(
            connected: linkedInReady,
            name: careerProfile.profile?.name,
            onTap: () => context.push('/linkedin-profile'),
          ),
          const SizedBox(height: 9),
          _ResumeConnectorCard(
            connected: resumeReady,
            fileName: resume.currentCv?.fileName,
            skillCount: resume.profile?.skills.length ?? 0,
            onTap: () => context.push('/resume-profile'),
          ),
          const SizedBox(height: 26),
          const _Header(title: 'Preferences and tools', detail: ''),
          const SizedBox(height: 12),
          _ToneConnectorCard(
            connected: tone.configured,
            answeredCount:
                tone.answers.values.where((a) => a.trim().isNotEmpty).length,
            onTap: () => context.push('/writing-voice'),
          ),
          const SizedBox(height: 9),
          _EvidenceSource(
            icon: Icons.auto_awesome_rounded,
            title: 'Master resume',
            subtitle: resumeReady
                ? 'Build or refine from your complete profile'
                : 'Create a resume from your connected evidence',
            status: 'OPEN',
            color: LensColors.indigo,
            onTap: () => context.push('/master-resume'),
          ),
          const SizedBox(height: 9),
          _EvidenceSource(
            icon: Icons.mail_outline_rounded,
            title: 'Email composer',
            subtitle: 'Draft with context, review it, then send with Gmail',
            status: 'OPEN',
            color: LensColors.violet,
            onTap: () => context.push('/email-studio'),
          ),
          const SizedBox(height: 26),
          const _Header(
            title: 'Account',
            detail: '',
          ),
          const SizedBox(height: 12),
          _EvidenceSource(
            icon: Icons.settings_outlined,
            title: 'Settings and integrations',
            subtitle: 'Notion, privacy, data controls, and sign out',
            status: 'OPEN',
            color: LensColors.muted,
            onTap: () => context.push('/settings'),
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
    return LensCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 66,
            height: 66,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 62,
                  height: 62,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: LensColors.line,
                    color: LensColors.aqua,
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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
                Text(
                  '$liveSignals of $totalSignals sources connected',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Current GPA $gpa',
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 12,
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
  final VoidCallback? onTap;

  const _EvidenceSource({
    required this.icon,
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
            alignment: Alignment.center,
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
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status.toLowerCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: LensColors.muted,
                  size: 19,
                ),
            ],
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
                    fontSize: 11,
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
                    fontSize: 11,
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
                    fontSize: 11,
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
                    fontSize: 11,
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
                            fontSize: 11,
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
                    fontSize: 11,
                    fontWeight: connected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (connected) ...[
                  const SizedBox(height: 3),
                  Text(
                    'PDF uploaded · $skillCount skills extracted',
                    style: const TextStyle(
                      color: LensColors.muted,
                      fontSize: 11,
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
                    fontSize: 11,
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
                    fontSize: 11,
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
                    fontSize: 11,
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
          style: const TextStyle(color: LensColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}
