import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/career_profile_repository.dart';
import '../../data/models.dart';
import '../../data/opportunity_repository.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  final _keywords = TextEditingController(text: 'software engineer, backend');
  final _locations = TextEditingController(text: 'Berlin, Germany');
  String _roleType = 'newgrad';
  String _timeframe = 'lastweek';
  String _targetMarket = 'europe';
  final Set<String> _workModes = {'remote', 'hybrid'};

  @override
  void initState() {
    super.initState();
    final saved = context.read<OpportunityRepository>();
    _roleType = saved.roleType;
    _timeframe = saved.timeframe;
    _targetMarket = saved.targetMarket;
    _workModes
      ..clear()
      ..addAll(saved.workModes);
    _keywords.text = saved.keywords.join(', ');
    _locations.text = saved.locations.join(', ');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicRepository>().loadDashboard();
    });
  }

  @override
  void dispose() {
    _keywords.dispose();
    _locations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opportunities = context.watch<OpportunityRepository>();
    final result = opportunities.result;
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 44),
              children: [
                _TopBar(onBack: () => context.pop()),
                const SizedBox(height: 22),
                const _OpportunityHero(),
                const SizedBox(height: 18),
                _EvidenceRail(evidence: result?.evidence),
                const SizedBox(height: 24),
                _SearchPanel(
                  roleType: _roleType,
                  timeframe: _timeframe,
                  targetMarket: _targetMarket,
                  workModes: _workModes,
                  keywords: _keywords,
                  locations: _locations,
                  loading: opportunities.loading,
                  onRoleChanged: (value) => setState(() => _roleType = value),
                  onTimeframeChanged: (value) =>
                      setState(() => _timeframe = value),
                  onMarketChanged: (value) =>
                      setState(() => _targetMarket = value),
                  onWorkModeChanged: (value, selected) => setState(() {
                    selected ? _workModes.add(value) : _workModes.remove(value);
                  }),
                  onSearch: _search,
                ),
                if (opportunities.error != null) ...[
                  const SizedBox(height: 16),
                  LensError(
                    message: opportunities.error!,
                    onRetry: _search,
                  ),
                ],
                if (opportunities.loading) ...[
                  const SizedBox(height: 22),
                  const LensCard(
                    child: LensLoading(
                      label: 'Scanning live roles and matching your evidence…',
                    ),
                  ),
                ] else if (result != null) ...[
                  const SizedBox(height: 28),
                  _ResultHeader(result: result),
                  const SizedBox(height: 12),
                  if (result.jobs.isEmpty)
                    LensCard(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.manage_search_rounded,
                            color: LensColors.indigo,
                            size: 30,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            result.message ??
                                'No roles matched these preferences.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...result.jobs.map(
                      (job) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _JobCard(
                          job: job,
                          courses: result.courses,
                          onAskAi: () => _askAi(job),
                        ),
                      ),
                    ),
                  if (result.courses.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const _SectionHeading(
                      eyebrow: 'CURATED NEXT STEP',
                      title: 'Close the highest-impact gaps',
                      subtitle:
                          'Courses are selected from your supplied CareerLoop catalogue.',
                    ),
                    const SizedBox(height: 12),
                    ...result.courses.map(
                      (course) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CourseCard(course: course),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _Limitations(items: result.limitations),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _search() {
    FocusManager.instance.primaryFocus?.unfocus();
    return context.read<OpportunityRepository>().search(
          roleType: _roleType,
          timeframe: _timeframe,
          targetMarket: _targetMarket,
          locations: _csv(_locations.text),
          keywords: _csv(_keywords.text),
          workModes: _workModes.toList(),
        );
  }

  void _askAi(JobOpportunity job) {
    context.read<AdvisorRepository>().send(
          'Evaluate my fit for ${job.title} at ${job.company}. Use my full '
          'transcript and imported LinkedIn PDF. The live Swelist role is '
          '${job.url}. Explain the evidence for the match, verify the inferred '
          'skill gaps against what is actually known, and make a focused '
          'preparation plan without inventing job-description requirements.',
        );
    context.go('/advisor');
  }

  static List<String> _csv(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Back to Career Studio',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Opportunity Match',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: LensColors.aqua.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: LensColors.aqua.withValues(alpha: .22),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.radar_rounded, size: 14, color: LensColors.aqua),
              SizedBox(width: 5),
              Text(
                'SWElist live',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OpportunityHero extends StatelessWidget {
  const _OpportunityHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LensColors.ink, Color(0xFF273273)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FROM OPENING TO\nEXPLAINABLE FIT',
            style: TextStyle(
              color: LensColors.aqua,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.35,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Search the market through your own evidence.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'CareerLoop ranks live roles with your preferences, transcript, '
            'and imported professional profile—then turns gaps into action.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _EvidenceRail extends StatelessWidget {
  final OpportunityEvidence? evidence;

  const _EvidenceRail({required this.evidence});

  @override
  Widget build(BuildContext context) {
    final academic = evidence?.academicTranscript ??
        (context.watch<AcademicRepository>().transcript != null);
    final linkedIn = evidence?.linkedInPdf ??
        context.watch<CareerProfileRepository>().hasProfile;
    return Row(
      children: [
        Expanded(
          child: _EvidenceCell(
            icon: Icons.history_edu_outlined,
            label: 'Transcript',
            state: academic ? 'Used' : 'Loads on search',
            live: academic,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _EvidenceCell(
            icon: Icons.badge_outlined,
            label: 'LinkedIn PDF',
            state: linkedIn ? 'Used' : 'Optional',
            live: linkedIn,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: _EvidenceCell(
            icon: Icons.code_rounded,
            label: 'GitHub',
            state: 'Next',
            live: false,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: _EvidenceCell(
            icon: Icons.description_outlined,
            label: 'Resume',
            state: 'Next',
            live: false,
          ),
        ),
      ],
    );
  }
}

class _EvidenceCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String state;
  final bool live;

  const _EvidenceCell({
    required this.icon,
    required this.label,
    required this.state,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: live ? LensColors.aqua.withValues(alpha: .3) : LensColors.line,
        ),
      ),
      child: Column(
        children: [
          Icon(
            live ? Icons.check_circle_rounded : icon,
            size: 18,
            color: live ? LensColors.aqua : LensColors.muted,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800),
          ),
          Text(
            state,
            maxLines: 1,
            style: const TextStyle(color: LensColors.muted, fontSize: 7.8),
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  final String roleType;
  final String timeframe;
  final String targetMarket;
  final Set<String> workModes;
  final TextEditingController keywords;
  final TextEditingController locations;
  final bool loading;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onTimeframeChanged;
  final ValueChanged<String> onMarketChanged;
  final void Function(String, bool) onWorkModeChanged;
  final VoidCallback onSearch;

  const _SearchPanel({
    required this.roleType,
    required this.timeframe,
    required this.targetMarket,
    required this.workModes,
    required this.keywords,
    required this.locations,
    required this.loading,
    required this.onRoleChanged,
    required this.onTimeframeChanged,
    required this.onMarketChanged,
    required this.onWorkModeChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return LensCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SEARCH INTENT',
            style: TextStyle(
              color: LensColors.indigo,
              fontSize: 9,
              letterSpacing: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 13),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'newgrad',
                label: Text('New graduate'),
                icon: Icon(Icons.school_outlined, size: 17),
              ),
              ButtonSegment(
                value: 'internship',
                label: Text('Internship'),
                icon: Icon(Icons.work_outline_rounded, size: 17),
              ),
            ],
            selected: {roleType},
            showSelectedIcon: false,
            onSelectionChanged: (value) => onRoleChanged(value.first),
          ),
          const SizedBox(height: 17),
          const _FieldLabel('Target market'),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: const {
              'europe': 'Europe',
              'local': 'Egypt / local',
              'remote': 'Remote',
              'global': 'Global',
            }
                .entries
                .map(
                  (entry) => ChoiceChip(
                    label: Text(entry.value),
                    selected: targetMarket == entry.key,
                    onSelected: (_) => onMarketChanged(entry.key),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: keywords,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Keywords and role interests',
              hintText: 'backend, Flutter, machine learning',
              prefixIcon: const Icon(Icons.tune_rounded),
              helperText: 'Separate preferences with commas.',
              suffixIcon: keyboardVisible
                  ? IconButton(
                      tooltip: 'Hide keyboard',
                      onPressed: () =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      icon: const Icon(Icons.keyboard_hide_rounded),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: locations,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              labelText: 'Preferred locations',
              hintText: 'Berlin, Amsterdam, Remote',
              prefixIcon: const Icon(Icons.location_on_outlined),
              helperText:
                  'Leave blank to use the selected market automatically.',
              suffixIcon: keyboardVisible
                  ? IconButton(
                      tooltip: 'Hide keyboard',
                      onPressed: () =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      icon: const Icon(Icons.keyboard_hide_rounded),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 15),
          const _FieldLabel('Work nature'),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            children: const {
              'remote': 'Remote',
              'hybrid': 'Hybrid',
              'onsite': 'On-site',
            }
                .entries
                .map(
                  (entry) => FilterChip(
                    label: Text(entry.value),
                    selected: workModes.contains(entry.key),
                    onSelected: (selected) =>
                        onWorkModeChanged(entry.key, selected),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 15),
          const _FieldLabel('Freshness'),
          const SizedBox(height: 7),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'lastday', label: Text('24h')),
              ButtonSegment(value: 'lastweek', label: Text('7 days')),
              ButtonSegment(value: 'lastmonth', label: Text('30 days')),
            ],
            selected: {timeframe},
            showSelectedIcon: false,
            onSelectionChanged: (value) => onTimeframeChanged(value.first),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onSearch,
              icon: const Icon(Icons.radar_rounded),
              label: const Text('Find evidence-backed matches'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      );
}

class _ResultHeader extends StatelessWidget {
  final OpportunitySearchResult result;

  const _ResultHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LIVE MATCHES',
                style: TextStyle(
                  color: LensColors.aqua,
                  fontSize: 9,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${result.jobs.length} positions ranked',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        Text(
          'via ${result.source}',
          style: const TextStyle(
            color: LensColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobOpportunity job;
  final List<CareerCourseRecommendation> courses;
  final VoidCallback onAskAi;

  const _JobCard({
    required this.job,
    required this.courses,
    required this.onAskAi,
  });

  @override
  Widget build(BuildContext context) {
    final linkedCourses = courses
        .where((course) => job.recommendedCourseIds.contains(course.id))
        .toList();
    return LensCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CompanyMark(company: job.company),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.company,
                      style: const TextStyle(
                        color: LensColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: LensColors.indigo.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${job.matchScore}',
                      style: const TextStyle(
                        color: LensColors.indigo,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'signal',
                      style: TextStyle(color: LensColors.muted, fontSize: 7.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: LensColors.muted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  job.location,
                  maxLines: 2,
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...job.matchReasons.take(3).map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: LensColors.aqua,
                        size: 15,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(fontSize: 10.5, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (job.inferredSkillGaps.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'INFERRED GAPS TO VERIFY',
              style: TextStyle(
                color: LensColors.amber,
                fontSize: 8.5,
                letterSpacing: .9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: job.inferredSkillGaps
                  .take(5)
                  .map(
                    (gap) => Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.add_rounded, size: 13),
                      label: Text(gap),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (linkedCourses.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${linkedCourses.length} learning paths mapped below',
              style: const TextStyle(color: LensColors.muted, fontSize: 9.5),
            ),
          ],
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAskAi,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                  label: const Text('Evaluate with AI'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => launchUrl(
                    job.url,
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: const Text('Employer page'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompanyMark extends StatelessWidget {
  final String company;

  const _CompanyMark({required this.company});

  @override
  Widget build(BuildContext context) {
    final letters = company
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
    return Container(
      width: 43,
      height: 43,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LensColors.indigo, LensColors.violet],
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        letters.isEmpty ? 'CL' : letters,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CareerCourseRecommendation course;

  const _CourseCard({required this.course});

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
          Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0056D2).withValues(alpha: .09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              SimpleIcons.coursera,
              color: Color(0xFF0056D2),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.provider,
                  style: const TextStyle(
                    color: LensColors.indigo,
                    fontSize: 9,
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
                const SizedBox(height: 6),
                Text(
                  '${course.level} · ${course.duration}',
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 9.5,
                  ),
                ),
                if (course.addressesSkills.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    'Closes: ${course.addressesSkills.join(' · ')}',
                    style: const TextStyle(
                      color: LensColors.aqua,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded, size: 17),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionHeading({
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
            fontSize: 9,
            letterSpacing: 1.25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: LensColors.muted, fontSize: 10.5),
        ),
      ],
    );
  }
}

class _Limitations extends StatelessWidget {
  final List<String> items;

  const _Limitations({required this.items});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
      leading: const Icon(Icons.info_outline_rounded, size: 19),
      title: const Text(
        'How this match was calculated',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text(
                item,
                style: const TextStyle(
                  color: LensColors.muted,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
