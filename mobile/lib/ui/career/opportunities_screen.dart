import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
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
      backgroundColor: LensColors.canvas,
      appBar: AppBar(
        backgroundColor: LensColors.canvas,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 1,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Opportunities'),
        actions: [
          IconButton(
            tooltip: 'Edit filters',
            onPressed: opportunities.loading ? null : _openFilters,
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            _FilterSummaryCard(
              roleType: _roleType,
              targetMarket: _targetMarket,
              workModes: _workModes,
              roleInterests: _roleInterests,
              technologies: _technologies,
              preferredLocations: _preferredLocations,
              customKeywords: _csv(_keywords.text),
              customLocations: _csv(_locations.text),
              onEdit: opportunities.loading ? null : _openFilters,
            ),
            if (opportunities.error != null) ...[
              const SizedBox(height: 16),
              LensError(
                message: opportunities.error!,
                onRetry: _search,
              ),
            ],
            if (opportunities.loading) ...[
              const SizedBox(height: 20),
              const LensCard(
                child: LensLoading(
                  label: 'Finding roles and checking profile fit…',
                ),
              ),
            ] else if (result == null) ...[
              const SizedBox(height: 36),
              _SearchEmptyState(onSearch: _openFilters),
            ] else ...[
              const SizedBox(height: 24),
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
                        result.message ?? 'No roles matched these preferences.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: _openFilters,
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Adjust filters'),
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
    );
  }

  Future<void> _openFilters() async {
    FocusManager.instance.primaryFocus?.unfocus();
    var roleType = _roleType;
    var targetMarket = _targetMarket;
    final workModes = {..._workModes};
    final roleInterests = {..._roleInterests};
    final technologies = {..._technologies};
    final preferredLocations = {..._preferredLocations};
    final keywords = TextEditingController(text: _keywords.text);
    final locations = TextEditingController(text: _locations.text);

    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SizedBox(
              height: MediaQuery.sizeOf(context).height * .88,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 8, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Search filters',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Choose what matters for your next role.',
                                style: TextStyle(
                                  color: LensColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                      child: _SearchPanel(
                        roleType: roleType,
                        targetMarket: targetMarket,
                        workModes: workModes,
                        roleInterests: roleInterests,
                        technologies: technologies,
                        preferredLocations: preferredLocations,
                        keywords: keywords,
                        locations: locations,
                        onRoleChanged: (value) =>
                            setSheetState(() => roleType = value),
                        onMarketChanged: (value) =>
                            setSheetState(() => targetMarket = value),
                        onRoleInterestChanged: (value, selected) {
                          setSheetState(() {
                            selected
                                ? roleInterests.add(value)
                                : roleInterests.remove(value);
                          });
                        },
                        onTechnologyChanged: (value, selected) {
                          setSheetState(() {
                            selected
                                ? technologies.add(value)
                                : technologies.remove(value);
                          });
                        },
                        onLocationChanged: (value, selected) {
                          setSheetState(() {
                            selected
                                ? preferredLocations.add(value)
                                : preferredLocations.remove(value);
                          });
                        },
                        onWorkModeChanged: (value, selected) {
                          setSheetState(() {
                            selected
                                ? workModes.add(value)
                                : workModes.remove(value);
                          });
                        },
                        onSearch: () => Navigator.of(sheetContext).pop(true),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted) {
      keywords.dispose();
      locations.dispose();
      return;
    }
    if (apply == true) {
      setState(() {
        _roleType = roleType;
        _targetMarket = targetMarket;
        _workModes
          ..clear()
          ..addAll(workModes);
        _roleInterests
          ..clear()
          ..addAll(roleInterests);
        _technologies
          ..clear()
          ..addAll(technologies);
        _preferredLocations
          ..clear()
          ..addAll(preferredLocations);
        _keywords.text = keywords.text;
        _locations.text = locations.text;
      });
      await _search();
    }
    keywords.dispose();
    locations.dispose();
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

class _FilterSummaryCard extends StatelessWidget {
  final String roleType;
  final String targetMarket;
  final Set<String> workModes;
  final Set<String> roleInterests;
  final Set<String> technologies;
  final Set<String> preferredLocations;
  final List<String> customKeywords;
  final List<String> customLocations;
  final VoidCallback? onEdit;

  const _FilterSummaryCard({
    required this.roleType,
    required this.targetMarket,
    required this.workModes,
    required this.roleInterests,
    required this.technologies,
    required this.preferredLocations,
    required this.customKeywords,
    required this.customLocations,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    const markets = {
      'europe': 'Europe',
      'local': 'Egypt / local',
      'remote': 'Remote market',
      'global': 'Global',
    };
    final filters = <String>[
      roleType == 'internship' ? 'Internship' : 'New graduate',
      ...roleInterests.map((value) => _roleChoices[value] ?? value),
      ...technologies.map((value) => _technologyChoices[value] ?? value),
      markets[targetMarket] ?? targetMarket,
      ...preferredLocations,
      ...customLocations,
      ...workModes.map(_displayWorkMode),
      ...customKeywords,
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LensColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Search preferences',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.tune_rounded, size: 17),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: filters
                .take(5)
                .map((label) => _SummaryChip(label: label))
                .toList(),
          ),
          if (filters.length > 5) ...[
            const SizedBox(height: 8),
            Text(
              '+${filters.length - 5} more filters',
              style: const TextStyle(
                color: LensColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _displayWorkMode(String value) => switch (value) {
        'onsite' => 'On-site',
        'hybrid' => 'Hybrid',
        _ => 'Remote',
      };
}

class _SummaryChip extends StatelessWidget {
  final String label;

  const _SummaryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: LensColors.canvas,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: LensColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  final VoidCallback onSearch;

  const _SearchEmptyState({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: LensColors.indigo.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: LensColors.indigo,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Find roles that fit your profile',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 7),
          const Text(
            'Set your role, market, and work preferences. CareerLoop will '
            'rank openings against your connected profile.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LensColors.muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Set filters and search'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 20),
        const _FieldLabel('Role interests'),
        const SizedBox(height: 8),
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
        const SizedBox(height: 20),
        const _FieldLabel('Technologies'),
        const SizedBox(height: 8),
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
        const SizedBox(height: 16),
        TextField(
          controller: keywords,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Custom role or skill',
            hintText: 'LangGraph, fintech, iOS',
            prefixIcon: const Icon(Icons.add_circle_outline_rounded),
            helperText: 'Optional · separate terms with commas.',
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
        const SizedBox(height: 20),
        const _FieldLabel('Target market'),
        const SizedBox(height: 8),
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
        const SizedBox(height: 20),
        const _FieldLabel('Preferred locations'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _locationChoices
              .map(
                (value) => FilterChip(
                  label: Text(value),
                  selected: preferredLocations.contains(value),
                  onSelected: (selected) => onLocationChanged(value, selected),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: locations,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Another location',
            hintText: 'Munich, Stockholm',
            prefixIcon: const Icon(Icons.location_on_outlined),
            helperText: 'Optional · separate places with commas.',
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
        const SizedBox(height: 20),
        const _FieldLabel('Work mode'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Show matches'),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      );
}

class _ResultHeader extends StatelessWidget {
  final OpportunitySearchResult result;

  const _ResultHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            result.jobs.length == 1
                ? '1 matching position'
                : '${result.jobs.length} matching positions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              size: 17,
              color: LensColors.muted,
            ),
            SizedBox(width: 4),
            Text(
              'Best fit first',
              style: TextStyle(color: LensColors.muted, fontSize: 11),
            ),
          ],
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: LensColors.indigo.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${job.matchScore}% fit',
                  style: const TextStyle(
                    color: LensColors.indigo,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
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
          if (job.matchReasons.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...job.matchReasons.take(2).map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: LensColors.aqua,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reason,
                            style: const TextStyle(fontSize: 12, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${job.inferredSkillGaps.length} gaps · '
                  '${job.recommendedCourseIds.length} recommended courses',
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 21),
            ],
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
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: LensColors.canvas,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LensColors.muted),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LensColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
