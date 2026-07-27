import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/career_profile_repository.dart';
import '../../data/models.dart';
import '../../data/opportunity_repository.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';
import 'opportunity_detail_screen.dart';

const _roleChoices = <String, String>{
  'software engineer': 'Software engineering',
  'backend': 'Backend',
  'mobile': 'Mobile',
  'data engineer': 'Data',
  'machine learning': 'AI / ML',
  'cybersecurity': 'Cybersecurity',
  'cloud': 'Cloud / DevOps',
  'business analyst': 'Product / business',
};

const _technologyChoices = <String, String>{
  'Python': 'Python',
  'Java': 'Java',
  'Flutter': 'Flutter',
  'React': 'React',
  'SQL': 'SQL',
  'machine learning': 'Machine learning',
  'Docker': 'Docker',
  'AWS': 'AWS',
};

const _locationChoices = <String>[
  'Berlin',
  'Germany',
  'Amsterdam',
  'London',
  'Remote',
  'Cairo',
  'Egypt',
];

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  final _keywords = TextEditingController();
  final _locations = TextEditingController();
  String _roleType = 'newgrad';
  String _targetMarket = 'europe';
  final Set<String> _workModes = {'remote', 'hybrid'};
  final Set<String> _roleInterests = {'software engineer', 'backend'};
  final Set<String> _technologies = {};
  final Set<String> _preferredLocations = {'Berlin', 'Germany'};

  @override
  void initState() {
    super.initState();
    final saved = context.read<OpportunityRepository>();
    _roleType = saved.roleType;
    _targetMarket = saved.targetMarket;
    _workModes
      ..clear()
      ..addAll(saved.workModes);
    _roleInterests
      ..clear()
      ..addAll(saved.keywords.where(_roleChoices.containsKey));
    _technologies
      ..clear()
      ..addAll(saved.keywords.where(_technologyChoices.containsKey));
    _keywords.text = saved.keywords
        .where(
          (value) =>
              !_roleChoices.containsKey(value) &&
              !_technologyChoices.containsKey(value),
        )
        .join(', ');
    _preferredLocations
      ..clear()
      ..addAll(saved.locations.where(_locationChoices.contains));
    _locations.text = saved.locations
        .where((value) => !_locationChoices.contains(value))
        .join(', ');
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
                  targetMarket: _targetMarket,
                  workModes: _workModes,
                  roleInterests: _roleInterests,
                  technologies: _technologies,
                  preferredLocations: _preferredLocations,
                  keywords: _keywords,
                  locations: _locations,
                  loading: opportunities.loading,
                  onRoleChanged: (value) => setState(() => _roleType = value),
                  onMarketChanged: (value) =>
                      setState(() => _targetMarket = value),
                  onRoleInterestChanged: (value, selected) => setState(() {
                    selected
                        ? _roleInterests.add(value)
                        : _roleInterests.remove(value);
                  }),
                  onTechnologyChanged: (value, selected) => setState(() {
                    selected
                        ? _technologies.add(value)
                        : _technologies.remove(value);
                  }),
                  onLocationChanged: (value, selected) => setState(() {
                    selected
                        ? _preferredLocations.add(value)
                        : _preferredLocations.remove(value);
                  }),
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
                          onOpen: () => context.push(
                            '/opportunities/job/${Uri.encodeComponent(job.id)}',
                            extra: OpportunityDetailArgs(
                              job: job,
                              evidence: result.evidence,
                              courses: result.courses,
                              limitations: result.limitations,
                            ),
                          ),
                        ),
                      ),
                    ),
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
          timeframe: 'all',
          targetMarket: _targetMarket,
          locations: [
            ..._preferredLocations,
            ..._csv(_locations.text),
          ],
          keywords: [
            ..._roleInterests,
            ..._technologies,
            ..._csv(_keywords.text),
          ],
          workModes: _workModes.toList(),
        );
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
                'Live market',
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
  final String targetMarket;
  final Set<String> workModes;
  final Set<String> roleInterests;
  final Set<String> technologies;
  final Set<String> preferredLocations;
  final TextEditingController keywords;
  final TextEditingController locations;
  final bool loading;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onMarketChanged;
  final void Function(String, bool) onRoleInterestChanged;
  final void Function(String, bool) onTechnologyChanged;
  final void Function(String, bool) onLocationChanged;
  final void Function(String, bool) onWorkModeChanged;
  final VoidCallback onSearch;

  const _SearchPanel({
    required this.roleType,
    required this.targetMarket,
    required this.workModes,
    required this.roleInterests,
    required this.technologies,
    required this.preferredLocations,
    required this.keywords,
    required this.locations,
    required this.loading,
    required this.onRoleChanged,
    required this.onMarketChanged,
    required this.onRoleInterestChanged,
    required this.onTechnologyChanged,
    required this.onLocationChanged,
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
          const _FieldLabel('Role interests'),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _roleChoices.entries
                .map(
                  (entry) => FilterChip(
                    label: Text(entry.value),
                    selected: roleInterests.contains(entry.key),
                    onSelected: (selected) =>
                        onRoleInterestChanged(entry.key, selected),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 15),
          const _FieldLabel('Technologies'),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _technologyChoices.entries
                .map(
                  (entry) => FilterChip(
                    label: Text(entry.value),
                    selected: technologies.contains(entry.key),
                    onSelected: (selected) =>
                        onTechnologyChanged(entry.key, selected),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: keywords,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Add custom role or skill',
              hintText: 'e.g. LangGraph, fintech, iOS',
              prefixIcon: const Icon(Icons.add_circle_outline_rounded),
              helperText: 'Optional · separate multiple terms with commas.',
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
          const _FieldLabel('Preferred locations'),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _locationChoices
                .map(
                  (value) => FilterChip(
                    label: Text(value),
                    selected: preferredLocations.contains(value),
                    onSelected: (selected) =>
                        onLocationChanged(value, selected),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: locations,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              labelText: 'Add another location',
              hintText: 'e.g. Munich, Stockholm',
              prefixIcon: const Icon(Icons.location_on_outlined),
              helperText: 'Optional · separate multiple places with commas.',
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
        const Icon(
          Icons.arrow_downward_rounded,
          color: LensColors.muted,
          size: 18,
        ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobOpportunity job;
  final VoidCallback onOpen;

  const _JobCard({
    required this.job,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyLogo(
                company: job.company,
                logoUrl: job.companyLogoUrl,
                size: 46,
              ),
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
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _JobFact(
                icon: Icons.location_on_outlined,
                label: job.location,
              ),
              if ((job.category ?? '').isNotEmpty)
                _JobFact(
                  icon: Icons.work_outline_rounded,
                  label: job.category!,
                ),
              if ((job.sponsorship ?? '').isNotEmpty)
                _JobFact(
                  icon: Icons.public_rounded,
                  label: 'Sponsorship: ${job.sponsorship}',
                ),
              if (job.postedAt != null)
                _JobFact(
                  icon: Icons.schedule_rounded,
                  label: _shortDate(job.postedAt!),
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
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.fromLTRB(11, 9, 8, 9),
            decoration: BoxDecoration(
              color: LensColors.indigo.withValues(alpha: .055),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: LensColors.indigo,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${job.inferredSkillGaps.length} gaps to verify · '
                    '${job.recommendedCourseIds.length} targeted courses',
                    style: const TextStyle(
                      color: LensColors.indigo,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _shortDate(DateTime value) {
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
    return 'Posted ${months[value.month - 1]} ${value.day}';
  }
}

class _JobFact extends StatelessWidget {
  final IconData icon;
  final String label;

  const _JobFact({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: LensColors.canvas,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: LensColors.muted),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LensColors.muted,
                fontSize: 8.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
