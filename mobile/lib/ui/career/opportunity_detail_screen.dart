import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/api_client.dart';
import '../../data/career_document_repository.dart';
import '../../data/models.dart';
import '../core/content_ai_overlay.dart';
import '../core/lens_components.dart';
import 'career_document_viewer_screen.dart';

class OpportunityDetailArgs {
  final JobOpportunity job;
  final OpportunityEvidence evidence;
  final List<String> limitations;

  const OpportunityDetailArgs({
    required this.job,
    required this.evidence,
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
    return Semantics(
      label: '$company logo',
      image: true,
      child: Container(
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
      ),
    );
  }
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
        title: const Text('Job details'),
      ),
      bottomNavigationBar: _ActionBar(
        onAskAi: _copilot.open,
        onApply: () => _open(job.url),
      ),
      body: ContentAiOverlay(
        key: ValueKey('job-copilot-${job.id}'),
        controller: _copilot,
        title: 'Job Copilot',
        subtitle: '${job.title} · ${job.company}',
        contextInstruction: _copilotContext,
        quickActions: [
          ContentAiQuickAction(
            icon: Icons.fact_check_outlined,
            label: 'Explain why this fits me',
            prompt:
                'Explain why ${job.title} at ${job.company} fits my profile. '
                'Cite the profile source behind each supported claim and mark '
                'anything inferred.',
          ),
          ContentAiQuickAction(
            icon: Icons.manage_search_rounded,
            label: 'Review the requirements',
            prompt: 'Review this opening against my profile evidence. Tell me '
                'what is clearly supported and what I should verify on the '
                'employer page.',
          ),
          ContentAiQuickAction(
            icon: Icons.edit_document,
            label: 'Prepare my application',
            prompt: 'Help me prepare a concise application strategy for this '
                'specific role using only verified profile evidence.',
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
          children: [
            _PositionHeader(job: job),
            const SizedBox(height: 14),
            _ListingFacts(job: job),
            if (job.requiredSkills.isNotEmpty) ...[
              const SizedBox(height: 26),
              const _SectionHeading('Role skills'),
              const SizedBox(height: 11),
              _RoleSkills(skills: job.requiredSkills),
            ],
            const SizedBox(height: 26),
            const _SectionHeading('Profile evidence'),
            const SizedBox(height: 11),
            _ProfileMatchCard(
              job: job,
              limitations: args.limitations,
            ),
            const SizedBox(height: 26),
            _ApplicationDocuments(job: job),
          ],
        ),
      ),
    );
  }

  String get _copilotContext {
    final sources = _connectedSources(args.evidence);
    final citations = job.profileEvidenceCitations
        .map(
          (item) => '${item.skill} — ${item.evidence} [${item.sourceLabel}]',
        )
        .join(' | ');
    return '''
You are the in-page CareerLoop Job Copilot for one specific opening. Keep the
conversation about ${job.title} at ${job.company}; never redirect the user to
another chat. The listing URL is ${job.url}. Listing facts: location
${job.location}; category ${job.category ?? 'not supplied'}; sponsorship
${job.sponsorship ?? 'not supplied'}; degrees
${job.degrees.isEmpty ? 'not supplied' : job.degrees.join(', ')}.

The current match reasons are: ${job.matchReasons.join(' | ')}.
The role skill model expects: ${job.requiredSkills.join(', ')}.
Profile-aligned terms are: ${job.profileSkillMatches.join(', ')}.
Verified source citations: ${citations.isEmpty ? 'none returned' : citations}.
Evaluation summary: ${job.assessmentSummary}.
Search-intent matches are: ${job.keywordMatches.join(', ')}.
Connected profile sources: ${sources.isEmpty ? 'none' : sources.join(', ')}.
Known limitations: ${args.limitations.join(' | ')}.

For every personal claim, cite the provided source and evidence. Be candid:
do not inflate weak or self-reported evidence, do not convert repository usage
into mastery, and say when the available profile cannot support a requirement.
Separate employer facts, verified profile evidence, and inference clearly.
''';
  }

  static List<String> _connectedSources(OpportunityEvidence evidence) => [
        if (evidence.academicTranscript) 'Academic transcript',
        if (evidence.linkedInPdf) 'LinkedIn profile PDF',
        if (evidence.github) 'GitHub',
        if (evidence.resume) 'Resume',
      ];

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
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 12,
                    height: 1.35,
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
      if (job.locations.length > 1)
        (
          icon: Icons.map_outlined,
          label: 'Locations',
          value: job.locations.join(', '),
        ),
      (
        icon: Icons.verified_outlined,
        label: 'Status',
        value: job.active ? 'Active listing' : 'Status unavailable',
      ),
    ];
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

class _RoleSkills extends StatelessWidget {
  final List<String> skills;

  const _RoleSkills({required this.skills});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LensColors.line),
      ),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: skills
            .map(
              (skill) => Chip(
                label: Text(skill),
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: LensColors.line),
                backgroundColor: LensColors.canvas,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProfileMatchCard extends StatelessWidget {
  final JobOpportunity job;
  final List<String> limitations;

  const _ProfileMatchCard({
    required this.job,
    required this.limitations,
  });

  @override
  Widget build(BuildContext context) {
    final citations = job.profileEvidenceCitations;
    return LensCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (job.assessmentSummary.isNotEmpty) ...[
            Text(
              job.assessmentSummary,
              style: const TextStyle(
                color: LensColors.ink,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),
          ],
          if (citations.isNotEmpty)
            ...citations.take(6).map(
                  (citation) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LensColors.canvas,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            color: LensColors.aqua,
                            size: 18,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        citation.skill,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border:
                                            Border.all(color: LensColors.line),
                                      ),
                                      child: Text(
                                        citation.sourceLabel,
                                        style: const TextStyle(
                                          color: LensColors.indigo,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  citation.evidence,
                                  style: const TextStyle(
                                    color: LensColors.muted,
                                    fontSize: 11.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
          else if (job.matchReasons.isEmpty)
            const Text(
              'No connected profile evidence supports this role yet. The '
              'result is based on your search preferences only.',
              style: TextStyle(color: LensColors.muted, fontSize: 12),
            )
          else
            ...job.matchReasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 17,
                      color: LensColors.indigo,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (limitations.isNotEmpty) ...[
            const Divider(height: 22),
            Text(
              limitations.first,
              style: const TextStyle(
                color: LensColors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
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
            const _SectionHeading('Application documents'),
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
                        ? 'Your profile aligned to ${job.company}'
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

class _SectionHeading extends StatelessWidget {
  final String text;

  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
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
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: onAskAi,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Copilot'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
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
