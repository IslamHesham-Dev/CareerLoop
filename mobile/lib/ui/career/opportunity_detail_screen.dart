import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/api_client.dart';
import '../../data/career_document_repository.dart';
import '../../data/models.dart';
import '../core/brand_marks.dart';
import '../core/content_ai_overlay.dart';
import '../core/lens_components.dart';
import 'career_document_viewer_screen.dart';

class OpportunityDetailArgs {
  final JobOpportunity job;
  final OpportunityEvidence evidence;
  final List<CareerCourseRecommendation> courses;
  final List<String> limitations;

  const OpportunityDetailArgs({
    required this.job,
    required this.evidence,
    required this.courses,
    required this.limitations,
  });
}

class CompanyLogo extends StatelessWidget {
  final String company;
  final Uri? logoUrl;
  final double size;

  const CompanyLogo({
    super.key,
    required this.company,
    required this.logoUrl,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.apartment_rounded,
      color: LensColors.indigo,
      size: size * .48,
    );
    final url = logoUrl?.toString() ?? '';
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * .25),
        border: Border.all(color: LensColors.line),
      ),
      child: url.isEmpty
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

String _evidenceVerdict(JobOpportunity job) {
  final citations = job.evidenceCitations.length;
  final gaps = job.inferredSkillGaps.length;
  if (citations >= 4 && gaps <= 2) return 'Strong evidence';
  if (citations >= 2) return 'Mixed evidence';
  if (citations == 1) return 'Limited evidence';
  return 'Unverified match';
}

class OpportunityDetailScreen extends StatefulWidget {
  final OpportunityDetailArgs args;

  const OpportunityDetailScreen({super.key, required this.args});

  @override
  State<OpportunityDetailScreen> createState() =>
      _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  final _copilot = ContentAiOverlayController();

  OpportunityDetailArgs get args => widget.args;
  JobOpportunity get job => args.job;

  @override
  Widget build(BuildContext context) {
    final courses = args.courses
        .where((course) => job.recommendedCourseIds.contains(course.id))
        .toList();
    return Scaffold(
      backgroundColor: LensColors.canvas,
      appBar: AppBar(
        backgroundColor: LensColors.canvas,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 1,
        leading: IconButton(
          tooltip: 'Back to matches',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Job match'),
      ),
      bottomNavigationBar: _ActionBar(
        onAskAi: _copilot.open,
        onApply: () => _open(job.url),
      ),
      body: ContentAiOverlay(
        key: ValueKey('job-copilot-${job.id}'),
        controller: _copilot,
        title: 'Ask CareerLoop',
        subtitle: '${job.title} · ${job.company}',
        contextInstruction: _jobContext(courses),
        showLauncher: false,
        welcomeDescription:
            'Ask about this role, your profile match, or how to strengthen your application.',
        quickActions: [
          ContentAiQuickAction(
            icon: Icons.fact_check_outlined,
            label: 'Explain my match',
            prompt:
                'Explain why this role matches my verified profile. Cite the '
                'academic and career evidence behind each important claim.',
          ),
          ContentAiQuickAction(
            icon: Icons.balance_rounded,
            label: 'Challenge the evaluation',
            prompt:
                'Evaluate me brutally and without bias for this role. Identify '
                'unsupported assumptions and the strongest evidence against '
                'my readiness.',
          ),
          ContentAiQuickAction(
            icon: Icons.route_outlined,
            label: 'Build my qualification plan',
            prompt:
                'Build a focused qualification plan for this exact role using '
                'the suggested courses shown on this page and my verified '
                'profile evidence.',
          ),
          ContentAiQuickAction(
            icon: Icons.description_outlined,
            label: 'Plan the application',
            prompt: 'Give me a tailored application strategy for this opening, '
                'including which verified projects, courses, and experience '
                'to emphasize.',
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
          children: [
            _PositionHeader(job: job),
            const SizedBox(height: 14),
            _ListingFacts(job: job),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Why this role matches'),
            const SizedBox(height: 11),
            _FitCard(
              job: job,
              limitations: args.limitations,
            ),
            const SizedBox(height: 24),
            _ApplicationDocuments(job: job),
            const SizedBox(height: 24),
            _QualificationPath(
              courses: courses,
              gaps: job.inferredSkillGaps,
            ),
          ],
        ),
      ),
    );
  }

  String _jobContext(List<CareerCourseRecommendation> courses) {
    final evidence = [
      if (args.evidence.academicTranscript) 'complete academic transcript',
      if (args.evidence.linkedInPdf) 'imported LinkedIn profile PDF',
      if (args.evidence.resume) 'imported resume evidence',
      if (args.evidence.github) 'connected GitHub project evidence',
    ];
    final courseContext = courses.isEmpty
        ? 'No course recommendation is currently displayed.'
        : courses
            .map(
              (course) => '${course.title} by ${course.provider} on '
                  '${course.platform}; level ${course.level}; duration '
                  '${course.duration}; skills '
                  '${course.skills.join(', ')}; strengthens '
                  '${course.addressesSkills.join(', ')}; URL ${course.url}',
            )
            .join('\n- ');
    final citationContext = job.evidenceCitations.isEmpty
        ? 'No source-level citation is currently available.'
        : job.evidenceCitations
            .map(
              (citation) => '${citation.skill}: ${citation.title} '
                  '[${citation.sourceLabel}] — ${citation.detail}',
            )
            .join('\n- ');
    return '''
You are the in-page CareerLoop job copilot for one specific opening. Keep every
answer anchored to this opening and the student's verified evidence.

OPENING
- Role: ${job.title}
- Company: ${job.company}
- Location: ${job.location}
- Role family: ${job.roleFamily}
- Category: ${job.category ?? 'not supplied'}
- Sponsorship: ${job.sponsorship ?? 'not supplied'}
- Degrees: ${job.degrees.isEmpty ? 'not supplied' : job.degrees.join(', ')}
- Application URL: ${job.url}
- Current match reasons: ${job.matchReasons.join('; ')}
- Keyword matches: ${job.keywordMatches.join(', ')}
- Profile skill matches: ${job.profileSkillMatches.join(', ')}
- Inferred skill gaps: ${job.inferredSkillGaps.join(', ')}

AVAILABLE PROFILE EVIDENCE
${evidence.isEmpty ? 'No profile source is marked available.' : evidence.join(', ')}

VERIFIED SOURCE CITATIONS
- $citationContext

SUGGESTED COURSES ON THIS PAGE
- $courseContext

For personalized answers, inspect the complete transcript and every available
career-profile source using the appropriate tools. Treat the opening metadata,
match reasons, and skill gaps as prior inferences to verify rather than facts.
Use the suggested courses as concrete options even when the student is already
qualified. Clearly separate job facts, profile evidence, inference, and advice.
Known source limitations: ${args.limitations.join('; ')}
''';
  }

  static Future<void> _open(Uri uri) async {
    if (uri.toString().isEmpty) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _PositionHeader extends StatelessWidget {
  final JobOpportunity job;

  const _PositionHeader({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LensColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyLogo(
                company: job.company,
                logoUrl: job.companyLogoUrl,
                size: 58,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.company,
                      style: const TextStyle(
                        color: LensColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      job.title,
                      style: const TextStyle(
                        color: LensColors.ink,
                        fontSize: 21,
                        height: 1.18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 17,
                color: LensColors.muted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  job.location,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: LensColors.indigo.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _evidenceVerdict(job),
                  style: const TextStyle(
                    color: LensColors.indigo,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListingFacts extends StatelessWidget {
  final JobOpportunity job;

  const _ListingFacts({required this.job});

  @override
  Widget build(BuildContext context) {
    final facts = <({IconData icon, String label, String value})>[
      if ((job.category ?? '').isNotEmpty)
        (
          icon: Icons.work_outline_rounded,
          label: 'Category',
          value: job.category!,
        ),
      if (job.postedAt != null)
        (
          icon: Icons.schedule_rounded,
          label: 'Posted',
          value: _formatDate(job.postedAt!),
        ),
      if (job.updatedAt != null && job.updatedAt != job.postedAt)
        (
          icon: Icons.update_rounded,
          label: 'Updated',
          value: _formatDate(job.updatedAt!),
        ),
      if ((job.sponsorship ?? '').isNotEmpty)
        (
          icon: Icons.public_rounded,
          label: 'Sponsorship',
          value: job.sponsorship!,
        ),
      if (job.degrees.isNotEmpty)
        (
          icon: Icons.school_outlined,
          label: 'Degree',
          value: job.degrees.join(', '),
        ),
      (
        icon: Icons.verified_outlined,
        label: 'Status',
        value: job.active ? 'Active listing' : 'Status unavailable',
      ),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LensColors.line),
      ),
      child: Column(
        children: [
          for (var index = 0; index < facts.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    facts[index].icon,
                    size: 19,
                    color: LensColors.indigo,
                  ),
                  const SizedBox(width: 11),
                  SizedBox(
                    width: 88,
                    child: Text(
                      facts[index].label,
                      style: const TextStyle(
                        color: LensColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      facts[index].value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (index != facts.length - 1) const Divider(height: 1, indent: 30),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}

class _FitCard extends StatelessWidget {
  final JobOpportunity job;
  final List<String> limitations;

  const _FitCard({
    required this.job,
    required this.limitations,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Verified evidence',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: LensColors.indigo.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _evidenceVerdict(job),
                  style: const TextStyle(
                    color: LensColors.indigo,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (job.evidenceCitations.isEmpty)
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: LensColors.amber.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: LensColors.amber.withValues(alpha: .22),
                ),
              ),
              child: const Text(
                'CareerLoop found no source-level proof for this match. Treat '
                'the role as a discovery result, not evidence that you are '
                'qualified.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            )
          else
            ...job.evidenceCitations.map(
              (citation) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EvidenceCitationCard(citation: citation),
              ),
            ),
          if (job.inferredSkillGaps.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 13),
            const Text(
              'What weakens the match',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 9),
            ...job.inferredSkillGaps.take(4).map(
                  (gap) => _ReasonRow(
                    icon: Icons.remove_circle_outline_rounded,
                    color: LensColors.rose,
                    text: 'No verified evidence found for $gap.',
                  ),
                ),
          ],
          if (limitations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              limitations.first,
              style: const TextStyle(
                color: LensColors.muted,
                fontSize: 10.5,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvidenceCitationCard extends StatelessWidget {
  final JobEvidenceCitation citation;

  const _EvidenceCitationCard({required this.citation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LensColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LensColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EvidenceSourceMark(source: citation.source),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        citation.sourceLabel,
                        style: const TextStyle(
                          color: LensColors.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: LensColors.aqua.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        citation.skill,
                        style: const TextStyle(
                          color: LensColors.aqua,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  citation.title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (citation.detail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    citation.detail,
                    style: const TextStyle(
                      color: LensColors.muted,
                      fontSize: 10.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceSourceMark extends StatelessWidget {
  final String source;

  const _EvidenceSourceMark({required this.source});

  @override
  Widget build(BuildContext context) {
    if (source == 'linkedin') {
      return const LinkedInBrandMark(size: 30);
    }
    final (icon, color) = switch (source) {
      'github' => (SimpleIcons.github, LensColors.ink),
      'academic' => (Icons.school_rounded, LensColors.indigo),
      _ => (Icons.description_outlined, LensColors.violet),
    };
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ReasonRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationDocuments extends StatelessWidget {
  final JobOpportunity job;

  const _ApplicationDocuments({required this.job});

  @override
  Widget build(BuildContext context) {
    return Consumer<CareerDocumentRepository>(
      builder: (context, repository, _) {
        final resume = repository.documentFor(job, 'resume');
        final coverLetter = repository.documentFor(job, 'cover_letter');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Application documents'),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: LensColors.line),
              ),
              child: Column(
                children: [
                  _DocumentRow(
                    icon: Icons.description_outlined,
                    title: 'Tailored resume',
                    subtitle: resume == null
                        ? 'Projects, experience, and skills selected for this role'
                        : 'Version ${resume.version} · PDF ready',
                    ready: resume != null,
                    loading: repository.isBusy(job, 'resume'),
                    onTap: () => _open(
                      context,
                      repository,
                      kind: 'resume',
                      document: resume,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _DocumentRow(
                    icon: Icons.mail_outline_rounded,
                    title: 'Tailored cover letter',
                    subtitle: coverLetter == null
                        ? 'Your evidence aligned to ${job.company}'
                        : 'Version ${coverLetter.version} · PDF ready',
                    ready: coverLetter != null,
                    loading: repository.isBusy(job, 'cover_letter'),
                    onTap: () => _open(
                      context,
                      repository,
                      kind: 'cover_letter',
                      document: coverLetter,
                    ),
                  ),
                  if (repository.error != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        repository.error!,
                        style: const TextStyle(
                          color: LensColors.rose,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _open(
    BuildContext context,
    CareerDocumentRepository repository, {
    required String kind,
    required CareerDocument? document,
  }) async {
    var generated = document ?? await repository.generate(job, kind);
    if (generated == null || !context.mounted) return;
    try {
      var file = await repository.download(generated);
      if (!context.mounted) return;
      await context.push(
        '/career-document',
        extra: CareerDocumentViewerArgs(
          job: job,
          document: generated,
          localPath: file.path,
        ),
      );
    } on ApiException catch (exception) {
      if (exception.statusCode == 404 && document != null) {
        generated = await repository.generate(job, kind);
        if (generated == null || !context.mounted) return;
        final file = await repository.download(generated);
        if (!context.mounted) return;
        await context.push(
          '/career-document',
          extra: CareerDocumentViewerArgs(
            job: job,
            document: generated,
            localPath: file.path,
          ),
        );
        return;
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exception.message)),
      );
    }
  }
}

class _DocumentRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool ready;
  final bool loading;
  final VoidCallback onTap;

  const _DocumentRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ready,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LensColors.canvas,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: LensColors.indigo.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: LensColors.indigo, size: 20),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: LensColors.muted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (loading)
                const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  ready ? 'Open' : 'Generate',
                  style: const TextStyle(
                    color: LensColors.indigo,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QualificationPath extends StatelessWidget {
  final List<CareerCourseRecommendation> courses;
  final List<String> gaps;

  const _QualificationPath({required this.courses, required this.gaps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Recommended learning'),
        const SizedBox(height: 11),
        if (courses.isEmpty)
          const LensCard(
            child: Text(
              'No catalogue course maps strongly to this role yet. Ask AI for a focused preparation plan.',
              style: TextStyle(color: LensColors.muted, height: 1.4),
            ),
          )
        else
          ...courses.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CourseStep(
                    number: entry.key + 1,
                    course: entry.value,
                    gaps: gaps,
                  ),
                ),
              ),
      ],
    );
  }
}

class _CourseStep extends StatelessWidget {
  final int number;
  final CareerCourseRecommendation course;
  final List<String> gaps;

  const _CourseStep({
    required this.number,
    required this.course,
    required this.gaps,
  });

  @override
  Widget build(BuildContext context) {
    final gapSkills = course.addressesSkills
        .where(
          (skill) => gaps.any(
            (gap) => gap.toLowerCase() == skill.toLowerCase(),
          ),
        )
        .toList();
    return LensCard(
      onTap: () => launchUrl(
        course.url,
        mode: LaunchMode.externalApplication,
      ),
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 45,
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF0056D2).withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  SimpleIcons.coursera,
                  color: Color(0xFF0056D2),
                  size: 23,
                ),
              ),
              Positioned(
                right: -4,
                top: -5,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: LensColors.ink,
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course.provider,
                        style: const TextStyle(
                          color: LensColors.indigo,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (gapSkills.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: LensColors.rose.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Bridges your gap',
                          style: TextStyle(
                            color: LensColors.rose,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${course.level} · ${course.duration}',
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 11,
                  ),
                ),
                if (course.addressesSkills.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    gapSkills.isEmpty
                        ? 'Builds ${course.addressesSkills.join(', ')}'
                        : 'Targets ${gapSkills.join(', ')}',
                    style: const TextStyle(
                      color: LensColors.aqua,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.arrow_outward_rounded, size: 18),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class _ActionBar extends StatelessWidget {
  final VoidCallback onAskAi;
  final VoidCallback onApply;

  const _ActionBar({required this.onAskAi, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: LensColors.line)),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAskAi,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Ask CareerLoop'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('View opening'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
