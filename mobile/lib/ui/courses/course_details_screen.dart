import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class CourseDetailsScreen extends StatefulWidget {
  final CourseSummary course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicRepository>().loadCourseGrades(widget.course);
    });
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicRepository>();
    final grades = academic.grades[widget.course.code];
    final loading = academic.loadingCourses.contains(widget.course.code);
    final university =
        context.watch<AuthRepository>().session?.universityLabel ??
            'University';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.course.code,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 7),
              Text(
                academic.context?.currentSeason ?? 'Winter 2024',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.course.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (widget.course.track.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              widget.course.track,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          if (loading && grades == null)
            LensCard(
              child: LensLoading(
                label: 'Reading detailed grades from $university…',
              ),
            )
          else if (academic.error != null && grades == null)
            LensError(
              message: academic.error!,
              onRetry: () => academic.loadCourseGrades(
                widget.course,
                force: true,
              ),
            )
          else if (grades != null) ...[
            _CourseSummary(grades: grades, university: university),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Assessments',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${grades.assessments.length} items',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (grades.assessments.isEmpty)
              const LensCard(
                child: Text(
                  'No detailed assessment rows were displayed by the portal.',
                ),
              )
            else
              ...grades.assessments.map(
                (assessment) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AssessmentCard(assessment: assessment),
                ),
              ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                context.read<AdvisorRepository>().send(
                      'Analyze ${widget.course.code}. Explain the grades, identify the weakest assessment, and make a practical improvement plan.',
                    );
                context.go('/advisor');
              },
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Discuss this course'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CourseSummary extends StatelessWidget {
  final CourseGrades grades;
  final String university;

  const _CourseSummary({
    required this.grades,
    required this.university,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = grades.averageRatio;
    final percentage = ratio == null ? '—' : '${(ratio * 100).round()}%';
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LensColors.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: ratio ?? 0,
                  strokeWidth: 7,
                  backgroundColor: scheme.primary.withValues(alpha: .10),
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    percentage,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current assessment average',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 7),
                Text(
                  ratio == null
                      ? 'Scores are shown exactly as $university returned them.'
                      : ratio < .65
                          ? 'This course has room for a focused recovery plan.'
                          : 'Review the detailed rows to protect your strongest work.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  final Assessment assessment;

  const _AssessmentCard({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final ratio = assessment.ratio;
    final color = ratio == null
        ? LensColors.indigo
        : ratio < .65
            ? LensColors.rose
            : ratio < .8
                ? LensColors.amber
                : LensColors.aqua;
    final title = assessment.element.isNotEmpty
        ? assessment.element
        : assessment.assessment.isNotEmpty
            ? assessment.assessment
            : 'Assessment';

    return LensCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                assessment.grade,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (assessment.assessment.isNotEmpty &&
              assessment.assessment != title) ...[
            const SizedBox(height: 7),
            Text(
              assessment.assessment,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12),
            ),
          ],
          if (ratio != null) ...[
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: color.withValues(alpha: .10),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
