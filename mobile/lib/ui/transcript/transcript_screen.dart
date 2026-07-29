import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class TranscriptScreen extends StatefulWidget {
  const TranscriptScreen({super.key});

  @override
  State<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
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
    final history = academic.fullTranscript;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic record'),
        leading: IconButton(
          tooltip: 'Back to profile',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => academic.loadDashboard(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          children: [
            if (academic.loadingDashboard && history == null)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: LensLoading(
                  label: 'Loading your complete academic record…',
                ),
              )
            else if (history == null)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: LensError(
                  message: academic.fullTranscriptError ??
                      academic.error ??
                      'Your complete transcript could not be loaded.',
                  onRetry: () => academic.loadDashboard(force: true),
                ),
              )
            else ...[
              _GpaHero(history: history),
              if (history.failedYears.isNotEmpty) ...[
                const SizedBox(height: 12),
                _IncompleteHistoryNotice(
                  failedYears: history.failedYears,
                ),
              ],
              const SizedBox(height: 14),
              const _GradeScaleCard(),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transcript history',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${history.courses.length} courses',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._displayYears(history).map(
                (year) => _AcademicYearSection(
                  academicYear: year,
                  semesters:
                      history.byAcademicYearAndSemester[year] ?? const {},
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _displayYears(TranscriptWindow history) {
    final years = <String>[];
    for (final year in history.requestedYears) {
      if (history.byAcademicYearAndSemester.containsKey(year)) years.add(year);
    }
    for (final year in history.byAcademicYearAndSemester.keys) {
      if (!years.contains(year)) years.add(year);
    }
    if (years.isEmpty) return history.loadedYears;
    return years;
  }
}

class _IncompleteHistoryNotice extends StatelessWidget {
  final List<String> failedYears;

  const _IncompleteHistoryNotice({required this.failedYears});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LensColors.amber.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LensColors.amber.withValues(alpha: .24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sync_problem_rounded,
            color: LensColors.amber,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'The portal did not return ${failedYears.join(', ')}. '
              'Pull down to try loading the missing year again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeScaleCard extends StatelessWidget {
  const _GradeScaleCard();

  @override
  Widget build(BuildContext context) {
    return LensCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(
          Icons.rule_rounded,
          color: LensColors.indigo,
        ),
        title: const Text(
          'Grading scale',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        children: GiuGradeScale.bands
            .map(
              (band) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 7, 20, 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 76,
                      child: Text(
                        '${band.percentageRange}%',
                        style: const TextStyle(
                          color: LensColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        band.letter,
                        style: const TextStyle(
                          color: LensColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'GPA ${band.gpaRange}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: LensColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _GpaHero extends StatelessWidget {
  final TranscriptWindow history;

  const _GpaHero({required this.history});

  @override
  Widget build(BuildContext context) {
    final recordedYears = history.byAcademicYearAndSemester.keys.toList();
    final firstYear = recordedYears.isNotEmpty
        ? recordedYears.first
        : history.requestedYears.isNotEmpty
            ? history.requestedYears.first
            : history.enrollmentYear.toString();
    final lastYear = recordedYears.isNotEmpty
        ? recordedYears.last
        : history.loadedYears.isNotEmpty
            ? history.loadedYears.last
            : 'present';

    return LensCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cumulative GPA',
                  style: TextStyle(
                    color: LensColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  history.cumulativeGpaWithGrade,
                  style: const TextStyle(
                    color: LensColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '$firstYear → $lastYear · '
                  '${recordedYears.length} academic years on record',
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: LensColors.indigo.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: LensColors.indigo,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademicYearSection extends StatelessWidget {
  final String academicYear;
  final Map<String, List<TranscriptWindowCourse>> semesters;

  const _AcademicYearSection({
    required this.academicYear,
    required this.semesters,
  });

  @override
  Widget build(BuildContext context) {
    final courseCount = semesters.values.fold<int>(
      0,
      (count, courses) => count + courses.length,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: LensColors.indigo,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  academicYear,
                  style: const TextStyle(
                    color: LensColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$courseCount courses',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (semesters.isEmpty)
            const LensCard(
              child: Text(
                'No transcript entries were returned for this academic year.',
                style: TextStyle(
                  color: LensColors.muted,
                  fontSize: 12,
                ),
              ),
            )
          else
            ...semesters.entries.map(
              (entry) => _SemesterSection(
                semester: entry.key,
                courses: entry.value,
              ),
            ),
        ],
      ),
    );
  }
}

class _SemesterSection extends StatelessWidget {
  final String semester;
  final List<TranscriptWindowCourse> courses;

  const _SemesterSection({
    required this.semester,
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            semester.isEmpty ? 'Semester' : semester,
            style: const TextStyle(
              color: LensColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 9),
          LensCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: courses.asMap().entries.map((entry) {
                final course = entry.value;
                final displayedGrade =
                    course.displayGrade.isEmpty ? '—' : course.displayGrade;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 43,
                            height: 43,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _gradeColor(displayedGrade)
                                  .withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              displayedGrade,
                              style: TextStyle(
                                color: _gradeColor(displayedGrade),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.course,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                if (course.hours.isNotEmpty ||
                                    course.group.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (course.hours.isNotEmpty)
                                        '${course.hours} hours',
                                      if (course.group.isNotEmpty) course.group,
                                    ].join(' · '),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (course.numeric.isNotEmpty)
                            Text(
                              course.gpaWithGrade,
                              style: const TextStyle(
                                color: LensColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (entry.key != courses.length - 1)
                      const Divider(height: 1, indent: 72),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _gradeColor(String grade) {
    final normalized = grade.toUpperCase();
    if (normalized.startsWith('A')) return LensColors.aqua;
    if (normalized.startsWith('B')) return LensColors.indigo;
    if (normalized.startsWith('C')) return LensColors.amber;
    return LensColors.rose;
  }
}
