import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/api_client.dart';
import '../../data/career_document_repository.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
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

class OpportunityDetailScreen extends StatelessWidget {
  final OpportunityDetailArgs args;

  const OpportunityDetailScreen({super.key, required this.args});

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
        onAskAi: () => _askAi(context),
        onApply: () => _open(job.url),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
        children: [
          _PositionHeader(job: job),
          const SizedBox(height: 14),
          _ListingFacts(job: job),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'Why this role matches',
            subtitle: 'Based on your search preferences and connected profile.',
          ),
          const SizedBox(height: 11),
          _FitCard(job: job, evidence: args.evidence),
          const SizedBox(height: 24),
          _ApplicationDocuments(job: job),
          const SizedBox(height: 24),
          _SkillMap(job: job),
          const SizedBox(height: 24),
          _QualificationPath(courses: courses),
          const SizedBox(height: 18),
          _EvidenceDisclosure(
            evidence: args.evidence,
            limitations: args.limitations,
          ),
        ],
      ),
    );
  }

  void _askAi(BuildContext context) {
    context.read<AdvisorRepository>().send(
          'Deep-evaluate my fit for ${job.title} at ${job.company}. Use my '
          'full transcript, imported LinkedIn PDF, and connected GitHub '
          'project evidence. The live application page is ${job.url}. '
          'Known listing metadata: category ${job.category ?? 'not supplied'}, '
          'locations ${job.location}, sponsorship '
          '${job.sponsorship ?? 'not supplied'}, and degrees '
          '${job.degrees.isEmpty ? 'not supplied' : job.degrees.join(', ')}. '
          'Validate the current inferred gaps '
          '(${job.inferredSkillGaps.join(', ')}) against my evidence, clearly '
          'separate facts from inferences, and build a focused qualification '
          'and application plan.',
        );
    context.go('/advisor');
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
                  '${job.matchScore}% profile fit',
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
  final OpportunityEvidence evidence;

  const _FitCard({required this.job, required this.evidence});

  @override
  Widget build(BuildContext context) {
    return LensCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        children: [
          if (job.matchReasons.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No specific match reasons were returned for this role.',
                style: TextStyle(color: LensColors.muted, fontSize: 12),
              ),
            )
          else
            ...job.matchReasons.map(
              (reason) => _ReasonRow(
                icon: Icons.check_circle_rounded,
                color: LensColors.aqua,
                text: reason,
              ),
            ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _EvidenceCount(
                  value: '${job.profileSkillMatches.length}',
                  label: 'Profile signals',
                ),
              ),
              Container(width: 1, height: 36, color: LensColors.line),
              Expanded(
                child: _EvidenceCount(
                  value: '${job.keywordMatches.length}',
                  label: 'Preference matches',
                ),
              ),
              Container(width: 1, height: 36, color: LensColors.line),
              Expanded(
                child: _EvidenceCount(
                  value: '${_connectedCount(evidence)}',
                  label: 'Sources used',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static int _connectedCount(OpportunityEvidence evidence) => [
        evidence.academicTranscript,
        evidence.linkedInPdf,
        evidence.github,
        evidence.resume,
      ].where((value) => value).length;
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

class _EvidenceCount extends StatelessWidget {
  final String value;
  final String label;

  const _EvidenceCount({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: LensColors.indigo,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: LensColors.muted, fontSize: 11),
        ),
      ],
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
            const _SectionTitle(
              title: 'Application documents',
              subtitle:
                  'Generate role-specific files, then review and refine them before applying.',
            ),
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

class _SkillMap extends StatelessWidget {
  final JobOpportunity job;

  const _SkillMap({required this.job});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Strengths and gaps',
          subtitle:
              'Gaps are inferred from the role family until the employer page is reviewed.',
        ),
        const SizedBox(height: 11),
        LensCard(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TagGroup(
                label: 'Supported by your profile',
                emptyLabel: 'No explicit matching skill was detected yet.',
                values: job.profileSkillMatches,
                color: LensColors.aqua,
                icon: Icons.verified_rounded,
              ),
              const SizedBox(height: 18),
              _TagGroup(
                label: 'Gaps to verify',
                emptyLabel: 'No role-family gaps were inferred.',
                values: job.inferredSkillGaps,
                color: LensColors.amber,
                icon: Icons.add_task_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagGroup extends StatelessWidget {
  final String label;
  final String emptyLabel;
  final List<String> values;
  final Color color;
  final IconData icon;

  const _TagGroup({
    required this.label,
    required this.emptyLabel,
    required this.values,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (values.isEmpty)
          Text(
            emptyLabel,
            style: const TextStyle(color: LensColors.muted, fontSize: 12),
          )
        else
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: values
                .map(
                  (value) => Chip(
                    avatar: Icon(icon, size: 14, color: color),
                    label: Text(value),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _QualificationPath extends StatelessWidget {
  final List<CareerCourseRecommendation> courses;

  const _QualificationPath({required this.courses});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Recommended learning',
          subtitle: 'Courses mapped to the inferred gaps for this role.',
        ),
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

  const _CourseStep({required this.number, required this.course});

  @override
  Widget build(BuildContext context) {
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
                Text(
                  course.provider,
                  style: const TextStyle(
                    color: LensColors.indigo,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
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
                    'Addresses ${course.addressesSkills.join(', ')}',
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

class _EvidenceDisclosure extends StatelessWidget {
  final OpportunityEvidence evidence;
  final List<String> limitations;

  const _EvidenceDisclosure({
    required this.evidence,
    required this.limitations,
  });

  @override
  Widget build(BuildContext context) {
    final used = <String>[
      if (evidence.academicTranscript) 'Academic transcript',
      if (evidence.linkedInPdf) 'LinkedIn profile PDF',
      if (evidence.github) 'GitHub',
      if (evidence.resume) 'Resume',
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LensColors.line),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: const Text(
          'Evidence used',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          used.isEmpty ? 'Preference signals only' : used.join(' · '),
          style: const TextStyle(color: LensColors.muted, fontSize: 11),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (limitations.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No additional limitations were reported.',
                style: TextStyle(color: LensColors.muted, fontSize: 12),
              ),
            )
          else
            ...limitations.map(
              (item) => _ReasonRow(
                icon: Icons.info_outline_rounded,
                color: LensColors.muted,
                text: item,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: LensColors.muted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
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
