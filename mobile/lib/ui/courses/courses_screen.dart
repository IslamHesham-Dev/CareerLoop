import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

enum _LearningView { semester, library }

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _search = TextEditingController();
  String? _cmsSeasonRequested;
  _LearningView _view = _LearningView.semester;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final academic = context.read<AcademicRepository>();
      academic.loadDashboard();
      _cmsSeasonRequested = academic.context?.currentSeason;
      if (context.read<AuthRepository>().session?.cmsConnected ?? false) {
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
    final cmsConnected = session?.cmsConnected ?? false;
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
    final semesterCourses = academic.courses
        .where(
          (course) =>
              needle.isEmpty ||
              course.code.toLowerCase().contains(needle) ||
              course.title.toLowerCase().contains(needle),
        )
        .toList();
    final cmsCourses = cms.courses
        .where(
          (course) =>
              needle.isEmpty ||
              course.code.toLowerCase().contains(needle) ||
              course.title.toLowerCase().contains(needle),
        )
        .toList();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          await academic.loadDashboard(force: true);
          if (cmsConnected) {
            await cms.loadCourses(
              force: true,
              season: academic.context?.currentSeason,
            );
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
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
                      const SizedBox(height: 4),
                      Text(
                        desiredSeason ?? 'Your academic workspace',
                        style: const TextStyle(
                          color: LensColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Ask Copilot',
                  onPressed: () => context.go('/advisor'),
                  icon: const Icon(Icons.auto_awesome_outlined),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ViewSelector(
              value: _view,
              cmsConnected: cmsConnected,
              onChanged: (value) => setState(() => _view = value),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              decoration: InputDecoration(
                hintText: _view == _LearningView.semester
                    ? 'Find a semester course'
                    : 'Find materials by course or code',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            if (_view == _LearningView.semester)
              _SemesterList(
                courses: semesterCourses,
                loading: academic.loadingDashboard,
              )
            else
              _LibraryList(
                courses: cmsCourses,
                cms: cms,
                connected: cmsConnected,
                message: session?.cmsMessage,
                season: desiredSeason,
              ),
          ],
        ),
      ),
    );
  }
}

class _ViewSelector extends StatelessWidget {
  final _LearningView value;
  final bool cmsConnected;
  final ValueChanged<_LearningView> onChanged;

  const _ViewSelector({
    required this.value,
    required this.cmsConnected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_LearningView>(
      segments: [
        const ButtonSegment(
          value: _LearningView.semester,
          icon: Icon(Icons.school_outlined, size: 18),
          label: Text('Semester'),
        ),
        ButtonSegment(
          value: _LearningView.library,
          enabled: cmsConnected,
          icon: const Icon(Icons.folder_open_outlined, size: 18),
          label: const Text('Materials'),
        ),
      ],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _SemesterList extends StatelessWidget {
  final List<CourseSummary> courses;
  final bool loading;

  const _SemesterList({required this.courses, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading && courses.isEmpty) {
      return const LensCard(
        child: LensLoading(label: 'Loading semester courses...'),
      );
    }
    if (courses.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No course found',
        message: 'Try another course name or code.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ListHeader(
          title: 'Semester courses',
          detail: '${courses.length} courses',
        ),
        const SizedBox(height: 10),
        LensCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < courses.length; index++) ...[
                _SemesterCourseRow(course: courses[index]),
                if (index < courses.length - 1)
                  const Divider(height: 1, indent: 62),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SemesterCourseRow extends StatelessWidget {
  final CourseSummary course;

  const _SemesterCourseRow({required this.course});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 7, 10, 7),
      leading: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: LensColors.indigo.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          course.code,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: LensColors.indigo,
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      title: Text(
        course.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        course.track,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: LensColors.muted, fontSize: 10),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: LensColors.muted,
      ),
      onTap: () => context.push('/courses/${course.code}', extra: course),
    );
  }
}

class _LibraryList extends StatelessWidget {
  final List<CmsCourse> courses;
  final CmsRepository cms;
  final bool connected;
  final String? message;
  final String? season;

  const _LibraryList({
    required this.courses,
    required this.cms,
    required this.connected,
    required this.message,
    required this.season,
  });

  @override
  Widget build(BuildContext context) {
    if (!connected) {
      return CmsAccessNotice(message: message);
    }
    if (cms.loadingCourses && cms.courses.isEmpty) {
      return const LensCard(
        child: LensLoading(label: 'Syncing course materials...'),
      );
    }
    if (cms.error != null && cms.courses.isEmpty) {
      return LensError(
        message: cms.error!,
        onRetry: () => cms.loadCourses(force: true, season: season),
      );
    }
    if (courses.isEmpty) {
      return const _EmptyState(
        icon: Icons.folder_off_outlined,
        title: 'No materials found',
        message: 'Try another course name or switch the active semester.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ListHeader(
          title: 'Course materials',
          detail:
              cms.loadingCourses ? 'Syncing...' : '${courses.length} courses',
        ),
        const SizedBox(height: 10),
        ...courses.map(
          (course) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _CmsCourseCard(course: course),
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
    final resourceLabel = course.resourceCount == null
        ? 'Open resources'
        : '${course.resourceCount} resources';
    return LensCard(
      onTap: () => context.push('/courses/cms/${course.id}', extra: course),
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LensColors.aqua.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              course.code,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: LensColors.aqua,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      resourceLabel,
                      style: const TextStyle(
                        color: LensColors.muted,
                        fontSize: 10,
                      ),
                    ),
                    if (course.hasSupplementalVideos) ...[
                      const SizedBox(width: 9),
                      const Icon(
                        Icons.play_circle_outline_rounded,
                        size: 14,
                        color: LensColors.violet,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${course.videoCount} videos',
                        style: const TextStyle(
                          color: LensColors.violet,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: LensColors.muted),
        ],
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  final String title;
  final String detail;

  const _ListHeader({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Text(
          detail,
          style: const TextStyle(color: LensColors.muted, fontSize: 10.5),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 46),
      child: Column(
        children: [
          Icon(icon, size: 32, color: LensColors.muted),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: LensColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
