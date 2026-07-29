import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _search = TextEditingController();
  String? _cmsSeasonRequested;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final academic = context.read<AcademicRepository>();
      academic.loadDashboard();
      _cmsSeasonRequested = academic.context?.currentSeason;
      final cmsConnected =
          context.read<AuthRepository>().session?.cmsConnected ?? false;
      if (cmsConnected) {
        context.read<CmsRepository>().loadCourses(
              season: academic.context?.currentSeason,
            );
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicRepository>();
    final cms = context.watch<CmsRepository>();
    final session = context.watch<AuthRepository>().session;
    final university = session?.universityLabel ?? 'University';
    final cmsConnected = session?.cmsConnected ?? false;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final desiredSeason = academic.context?.currentSeason;
    if (cmsConnected &&
        desiredSeason != null &&
        _cmsSeasonRequested != desiredSeason) {
      _cmsSeasonRequested = desiredSeason;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<CmsRepository>().loadCourses(
                force: true,
                season: desiredSeason,
              );
        }
      });
    }
    final needle = _search.text.trim().toLowerCase();
    final cmsCourses = cms.courses
        .where(
          (course) =>
              needle.isEmpty ||
              course.code.toLowerCase().contains(needle) ||
              course.title.toLowerCase().contains(needle) ||
              course.cmsLabel.toLowerCase().contains(needle),
        )
        .toList();
    final semesterCourses = academic.courses
        .where(
          (course) =>
              needle.isEmpty ||
              course.code.toLowerCase().contains(needle) ||
              course.title.toLowerCase().contains(needle),
        )
        .toList();
    final mergedCourses = <String, _CourseEntry>{};
    for (final course in semesterCourses) {
      mergedCourses
          .putIfAbsent(
            course.code.toUpperCase(),
            () => _CourseEntry(code: course.code, title: course.title),
          )
          .academic = course;
    }
    if (cmsConnected) {
      for (final course in cmsCourses) {
        mergedCourses
            .putIfAbsent(
              course.code.toUpperCase(),
              () => _CourseEntry(code: course.code, title: course.title),
            )
            .cms = course;
      }
    }
    final courseEntries = mergedCourses.values.toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    final coursesLoading = (academic.loadingDashboard &&
            academic.courses.isEmpty) ||
        (cmsConnected && cms.loadingCourses && cms.courses.isEmpty);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            if (cmsConnected)
              cms.loadCourses(
                force: true,
                season: academic.context?.currentSeason,
              ),
            academic.loadDashboard(force: true),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learn',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Saved quizzes',
                  onPressed: () => context.push('/practice'),
                  icon: const Icon(Icons.quiz_outlined),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => context.go('/advisor'),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Prep'),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            if (!cmsConnected) ...[
              const SizedBox(height: 18),
              CmsAccessNotice(message: session?.cmsMessage),
            ] else ...[
              const SizedBox(height: 14),
              _CmsStatus(
                courseCount: cms.courses.length,
                loading: cms.loadingCourses,
                university: university,
              ),
            ],
            const SizedBox(height: 18),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Find a course or code',
                prefixIcon: const Icon(Icons.search_rounded),
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
            const SizedBox(height: 26),
            _SectionHeading(
              title: 'Courses',
              detail: academic.context?.currentSeason ?? 'Portal',
            ),
            const SizedBox(height: 11),
            if (coursesLoading)
              const LensCard(
                child: LensLoading(label: 'Loading your courses...'),
              )
            else if (cmsConnected &&
                cms.error != null &&
                cms.courses.isEmpty &&
                academic.courses.isEmpty)
              LensError(
                message: cms.error!,
                onRetry: () => cms.loadCourses(
                  force: true,
                  season: academic.context?.currentSeason,
                ),
              )
            else if (courseEntries.isEmpty)
              const LensCard(
                child: Text(
                  'No course matches this search.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...courseEntries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: _CourseRow(entry: entry),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CmsStatus extends StatelessWidget {
  final int courseCount;
  final bool loading;
  final String university;

  const _CmsStatus({
    required this.courseCount,
    required this.loading,
    required this.university,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: context.lens.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.lens.line),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: loading ? LensColors.amber : LensColors.aqua,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (loading ? LensColors.amber : LensColors.aqua)
                      .withValues(alpha: .35),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loading ? 'Syncing $university CMS' : '$university CMS connected',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          if (courseCount > 0)
            Text(
              '$courseCount courses',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                  ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String? detail;

  const _SectionHeading({required this.title, this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (detail != null)
          Text(detail!, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _CourseEntry {
  final String code;
  final String title;
  CourseSummary? academic;
  CmsCourse? cms;

  _CourseEntry({required this.code, required this.title});
}

class _CourseRow extends StatelessWidget {
  final _CourseEntry entry;

  const _CourseRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final academic = entry.academic;
    final cms = entry.cms;
    return LensCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LensColors.indigo.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: LensColors.indigo.withValues(alpha: .12),
              ),
            ),
            child: Text(
              entry.code,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: LensColors.indigo,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              entry.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Grades',
            onPressed: academic == null
                ? null
                : () => context.push(
                      '/courses/${academic.code}',
                      extra: academic,
                    ),
            icon: const Icon(Icons.analytics_outlined, size: 19),
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            tooltip: 'Materials',
            onPressed: cms == null
                ? null
                : () => context.push('/courses/cms/${cms.id}', extra: cms),
            icon: const Icon(Icons.folder_copy_outlined, size: 19),
          ),
        ],
      ),
    );
  }
}
