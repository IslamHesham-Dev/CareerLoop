import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

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
        borderRadius: BorderRadius.circular(size * .28),
        border: Border.all(color: LensColors.line),
        boxShadow: [
          BoxShadow(
            color: LensColors.ink.withValues(alpha: .07),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
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
      bottomNavigationBar: _ActionBar(
        onAskAi: () => _askAi(context),
        onApply: () => _open(job.url),
      ),
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                pinned: true,
                title: const Text(
                  'Position intelligence',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                leading: IconButton.filledTonal(
                  tooltip: 'Back to matches',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 130),
                sliver: SliverList.list(
                  children: [
                    _PositionHero(job: job),
                    const SizedBox(height: 14),
                    _ListingFacts(job: job),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      eyebrow: 'CAREERLOOP EVALUATION',
                      title: 'Why this role reached your shortlist',
                      subtitle:
                          'A transparent signal built from your selected intent and connected evidence.',
                    ),
                    const SizedBox(height: 11),
                    _FitCard(job: job, evidence: args.evidence),
                    const SizedBox(height: 20),
                    _SkillMap(job: job),
                    const SizedBox(height: 22),
                    _QualificationPath(courses: courses, job: job),
                    const SizedBox(height: 20),
                    _EvidenceDisclosure(
                      evidence: args.evidence,
                      limitations: args.limitations,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _askAi(BuildContext context) {
    context.read<AdvisorRepository>().send(
          'Deep-evaluate my fit for ${job.title} at ${job.company}. Use my '
          'full transcript, imported LinkedIn PDF, and connected GitHub '
          'project evidence. The live application '
          'page is ${job.url}. Known listing metadata: category '
          '${job.category ?? 'not supplied'}, locations ${job.location}, '
          'sponsorship ${job.sponsorship ?? 'not supplied'}, and degrees '
          '${job.degrees.isEmpty ? 'not supplied' : job.degrees.join(', ')}. '
          'Validate the current inferred gaps (${job.inferredSkillGaps.join(', ')}) '
          'against my evidence, clearly separate facts from inferences, and '
          'build a focused qualification and application plan.',
        );
    context.go('/advisor');
  }

  static Future<void> _open(Uri uri) async {
    if (uri.toString().isEmpty) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _PositionHero extends StatelessWidget {
  final JobOpportunity job;

  const _PositionHero({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LensColors.ink, Color(0xFF273273)],
        ),
        borderRadius: BorderRadius.circular(28),
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
                      job.company.toUpperCase(),
                      style: const TextStyle(
                        color: LensColors.aqua,
                        fontSize: 9,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      job.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
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
              Expanded(
                child: _HeroFact(
                  icon: Icons.location_on_outlined,
                  value: job.location,
                ),
              ),
              const SizedBox(width: 10),
              _SignalGauge(score: job.matchScore),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  final IconData icon;
  final String value;

  const _HeroFact({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white60),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignalGauge extends StatelessWidget {
  final int score;

  const _SignalGauge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Column(
        children: [
          Text(
            '$score%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'FIT SIGNAL',
            style: TextStyle(
              color: LensColors.aqua,
              fontSize: 7,
              letterSpacing: .7,
              fontWeight: FontWeight.w900,
            ),
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
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: facts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final fact = facts[index];
          return Container(
            width: 138,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: LensColors.line),
            ),
            child: Row(
              children: [
                Icon(fact.icon, size: 18, color: LensColors.indigo),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fact.label.toUpperCase(),
                        style: const TextStyle(
                          color: LensColors.muted,
                          fontSize: 7.5,
                          letterSpacing: .6,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        fact.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
                  label: 'profile signals',
                ),
              ),
              Container(width: 1, height: 36, color: LensColors.line),
              Expanded(
                child: _EvidenceCount(
                  value: '${job.keywordMatches.length}',
                  label: 'intent matches',
                ),
              ),
              Container(width: 1, height: 36, color: LensColors.line),
              Expanded(
                child: _EvidenceCount(
                  value: '${_connectedCount(evidence)}',
                  label: 'sources used',
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
              style: const TextStyle(fontSize: 11.5, height: 1.35),
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
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: LensColors.muted, fontSize: 8.5),
        ),
      ],
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
          eyebrow: 'SIGNAL MAP',
          title: 'Known strengths and gaps to verify',
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
                label: 'EVIDENCED IN YOUR PROFILE',
                emptyLabel: 'No explicit matching skill was detected yet.',
                values: job.profileSkillMatches,
                color: LensColors.aqua,
                icon: Icons.verified_rounded,
              ),
              const SizedBox(height: 17),
              _TagGroup(
                label: 'INFERRED GAPS — VERIFY FIRST',
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
          style: TextStyle(
            color: color,
            fontSize: 8.5,
            letterSpacing: .8,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        if (values.isEmpty)
          Text(
            emptyLabel,
            style: const TextStyle(color: LensColors.muted, fontSize: 10.5),
          )
        else
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: values
                .map(
                  (value) => Chip(
                    avatar: Icon(icon, size: 13, color: color),
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
  final JobOpportunity job;

  const _QualificationPath({required this.courses, required this.job});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          eyebrow: 'QUALIFICATION PATH',
          title: 'Close the gaps for this position',
          subtitle:
              'Mapped only to the inferred gaps above—not generic course recommendations.',
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
                  borderRadius: BorderRadius.circular(14),
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
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
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
                  course.provider.toUpperCase(),
                  style: const TextStyle(
                    color: LensColors.indigo,
                    fontSize: 8,
                    letterSpacing: .7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${course.level} · ${course.duration}',
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 9.5,
                  ),
                ),
                if (course.addressesSkills.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Closes: ${course.addressesSkills.join(', ')}',
                    style: const TextStyle(
                      color: LensColors.aqua,
                      fontSize: 9.5,
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
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 2),
      title: const Text(
        'How this evaluation was made',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        used.isEmpty ? 'Preference signals only' : used.join(' + '),
        style: const TextStyle(color: LensColors.muted, fontSize: 10),
      ),
      children: [
        ...limitations.map(
          (item) => _ReasonRow(
            icon: Icons.info_outline_rounded,
            color: LensColors.muted,
            text: item,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: LensColors.indigo,
            fontSize: 8.5,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: LensColors.muted,
            fontSize: 10.5,
            height: 1.35,
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
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: LensColors.line),
          boxShadow: [
            BoxShadow(
              color: LensColors.ink.withValues(alpha: .12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAskAi,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Deep evaluate'),
              ),
            ),
            const SizedBox(width: 8),
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
