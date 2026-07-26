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
            PageHeading(
              eyebrow: cmsConnected ? 'LIVE GIU CMS' : 'PORTAL COURSES',
              title: 'Course space',
              subtitle: cmsConnected
                  ? 'Your official course files, organized for mobile. '
                      'Selected courses also include a video learning library.'
                  : 'Your portal course history remains available even when '
                      'CMS course access has ended.',
              trailing: IconButton.filledTonal(
                tooltip: 'Ask CareerLoop AI',
                onPressed: () => context.go('/advisor'),
                icon: const Icon(Icons.auto_awesome_rounded),
              ),
            ),
            const SizedBox(height: 18),
            if (cmsConnected)
              _CmsStatus(
                courseCount: cms.courses.length,
                loading: cms.loadingCourses,
              )
            else
              CmsAccessNotice(message: session?.cmsMessage),
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
              title: 'Advisory semester',
              detail: academic.context?.currentSeason ?? 'Portal',
            ),
            const SizedBox(height: 11),
            if (academic.loadingDashboard && academic.courses.isEmpty)
              const LensCard(
                child: LensLoading(label: 'Loading semester courses...'),
              )
            else if (semesterCourses.isEmpty)
              const LensCard(
                child: Text(
                  'No advisory-semester course matches this search.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              LensCard(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: semesterCourses
                      .map(
                        (course) => ActionChip(
                          avatar: const Icon(
                            Icons.analytics_outlined,
                            size: 17,
                          ),
                          label: Text(course.code),
                          tooltip: course.title,
                          onPressed: () => context.push(
                            '/courses/${course.code}',
                            extra: course,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (cmsConnected) ...[
              const SizedBox(height: 28),
              _SectionHeading(
                title: 'All CMS courses',
                detail: cms.courses.isEmpty
                    ? cms.season
                    : '${cms.courses.length} · ${cms.season ?? ''}',
              ),
              const SizedBox(height: 11),
              if (cms.loadingCourses && cms.courses.isEmpty)
                const LensCard(
                  child: LensLoading(label: 'Connecting to GIU CMS...'),
                )
              else if (cms.error != null && cms.courses.isEmpty)
                LensError(
                  message: cms.error!,
                  onRetry: () => cms.loadCourses(
                    force: true,
                    season: academic.context?.currentSeason,
                  ),
                )
              else if (cmsCourses.isEmpty)
                const LensCard(
                  child: Text(
                    'No CMS course matches this search.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...cmsCourses.map(
                  (course) => Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: _CmsCourseCard(course: course),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CmsStatus extends StatelessWidget {
  final int courseCount;
  final bool loading;

  const _CmsStatus({required this.courseCount, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LensColors.line),
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
              loading
                  ? 'Syncing your CMS workspace'
                  : 'Connected to your private GIU CMS session',
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

class _CmsCourseCard extends StatelessWidget {
  final CmsCourse course;

  const _CmsCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final resourceLabel = course.resourceCount == null
        ? 'Open course resources'
        : '${course.resourceCount} CMS resources';
    return LensCard(
      onTap: () => context.push('/courses/cms/${course.id}', extra: course),
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LensColors.indigo.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: LensColors.indigo.withValues(alpha: .12),
              ),
            ),
            child: Text(
              course.code,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: LensColors.indigo,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      resourceLabel,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 11),
                    ),
                    if (course.hasSupplementalVideos)
                      _VideoBadge(count: course.videoCount),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Ask AI about ${course.code}',
            onPressed: () {
              context.read<AdvisorRepository>().send(
                    'Help me study ${course.code} ${course.title} in '
                    '${course.season}. Use the live CMS course tools first and '
                    'base suggestions only on resources you can verify.',
                  );
              context.go('/advisor');
            },
            icon: const Icon(
              Icons.auto_awesome_outlined,
              color: LensColors.violet,
              size: 20,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: LensColors.muted),
        ],
      ),
    );
  }
}

class _VideoBadge extends StatelessWidget {
  final int count;

  const _VideoBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LensColors.violet.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_circle_outline_rounded,
            size: 13,
            color: LensColors.violet,
          ),
          const SizedBox(width: 4),
          Text(
            '$count videos',
            style: const TextStyle(
              color: LensColors.violet,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
