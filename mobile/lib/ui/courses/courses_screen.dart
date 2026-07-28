import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

enum _LearnSection { materials, grades }

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  _LearnSection _section = _LearnSection.materials;
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
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicRepository>();
    final cms = context.watch<CmsRepository>();
    final session = context.watch<AuthRepository>().session;
    final cmsConnected = session?.cmsConnected ?? false;
    final desiredSeason = academic.context?.currentSeason;

    if (cmsConnected &&
        desiredSeason != null &&
        _cmsSeasonRequested != desiredSeason) {
      _cmsSeasonRequested = desiredSeason;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<CmsRepository>().loadCourses(
              force: true,
              season: desiredSeason,
            );
      });
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            academic.loadDashboard(force: true),
            if (cmsConnected)
              cms.loadCourses(
                force: true,
                season: academic.context?.currentSeason,
              ),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Learn',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Saved quizzes',
                  onPressed: () => context.push('/practice'),
                  icon: const Icon(Icons.quiz_outlined),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SegmentedButton<_LearnSection>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _LearnSection.materials,
                  icon: Icon(Icons.folder_copy_outlined, size: 18),
                  label: Text('Materials'),
                ),
                ButtonSegment(
                  value: _LearnSection.grades,
                  icon: Icon(Icons.analytics_outlined, size: 18),
                  label: Text('Grades'),
                ),
              ],
              selected: {_section},
              onSelectionChanged: (selection) {
                setState(() => _section = selection.single);
              },
            ),
            const SizedBox(height: 26),
            if (_section == _LearnSection.materials)
              _MaterialsSection(
                cmsConnected: cmsConnected,
                cmsMessage: session?.cmsMessage,
                cms: cms,
                season: academic.context?.currentSeason,
              )
            else
              _GradesSection(academic: academic),
          ],
        ),
      ),
    );
  }
}

class _MaterialsSection extends StatelessWidget {
  final bool cmsConnected;
  final String? cmsMessage;
  final CmsRepository cms;
  final String? season;

  const _MaterialsSection({
    required this.cmsConnected,
    required this.cmsMessage,
    required this.cms,
    required this.season,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course materials',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (!cmsConnected)
          CmsAccessNotice(message: cmsMessage)
        else if (cms.loadingCourses && cms.courses.isEmpty)
          const LensCard(
            child: LensLoading(label: 'Loading course materials…'),
          )
        else if (cms.error != null && cms.courses.isEmpty)
          LensError(
            message: cms.error!,
            onRetry: () => cms.loadCourses(
              force: true,
              season: season,
            ),
          )
        else if (cms.courses.isEmpty)
          const LensCard(
            child: Text(
              'No course materials are available.',
              textAlign: TextAlign.center,
            ),
          )
        else
          ...cms.courses.map(
            (course) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CmsCourseCard(course: course),
            ),
          ),
      ],
    );
  }
}

class _GradesSection extends StatelessWidget {
  final AcademicRepository academic;

  const _GradesSection({required this.academic});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Grades', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (academic.loadingDashboard && academic.courses.isEmpty)
          const LensCard(
            child: LensLoading(label: 'Loading grades…'),
          )
        else if (academic.courses.isEmpty)
          const LensCard(
            child: Text(
              'No course grades are available.',
              textAlign: TextAlign.center,
            ),
          )
        else
          ...academic.courses.map(
            (course) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _GradeCourseCard(course: course),
            ),
          ),
      ],
    );
  }
}

class _CmsCourseCard extends StatelessWidget {
  final CmsCourse course;

  const _CmsCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: () => context.push('/courses/cms/${course.id}', extra: course),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _CourseCode(code: course.code),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded, color: LensColors.muted),
        ],
      ),
    );
  }
}

class _GradeCourseCard extends StatelessWidget {
  final CourseSummary course;

  const _GradeCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: () => context.push('/courses/${course.code}', extra: course),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _CourseCode(code: course.code),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded, color: LensColors.muted),
        ],
      ),
    );
  }
}

class _CourseCode extends StatelessWidget {
  final String code;

  const _CourseCode({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 48,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: LensColors.indigo.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        code,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: LensColors.indigo,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
