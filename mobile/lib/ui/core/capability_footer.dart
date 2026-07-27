import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models.dart';

class CapabilityFooter extends StatelessWidget {
  final List<ToolActivity> tools;
  final List<String> sources;
  final bool compact;

  const CapabilityFooter({
    super.key,
    required this.tools,
    required this.sources,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_CapabilityItem>[];
    final seen = <String>{};

    void add(_CapabilityItem item) {
      if (seen.add('${item.kind}:${item.label}:${item.failed}')) {
        items.add(item);
      }
    }

    for (final source in sources) {
      add(
        _CapabilityItem(
          kind: 'Connector',
          label: _sourceLabel(source),
          icon: _sourceIcon(source),
        ),
      );
    }
    for (final tool in tools) {
      add(
        _CapabilityItem(
          kind: 'Tool',
          label: _toolLabel(tool.name),
          icon: _toolIcon(tool.name),
          failed: tool.status == 'error',
        ),
      );
    }
    if (items.isEmpty) {
      add(
        const _CapabilityItem(
          kind: 'Skill',
          label: 'CareerLoop reasoning',
          icon: Icons.auto_awesome_rounded,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: compact ? 9 : 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: LensColors.line),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'USED IN THIS ANSWER',
            style: TextStyle(
              color: LensColors.muted,
              fontSize: compact ? 8.5 : 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.05,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map(
                  (item) => _CapabilityChip(
                    item: item,
                    compact: compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  static String _sourceLabel(String source) {
    final value = source.toLowerCase();
    if (value.contains('linkedin')) return 'LinkedIn PDF';
    if (value.contains('swelist') || value.contains('job posting')) {
      return 'SweList Jobs';
    }
    if (value.contains('coursera')) return 'Coursera';
    if (value.contains('company career')) return 'Company Careers';
    if (value.contains('practice set')) return 'Quiz Builder';
    if (value.contains('cms')) {
      final university = RegExp(r'\b(GIU|GUC)\b').firstMatch(source)?.group(1);
      return university == null ? 'University CMS' : '$university CMS';
    }
    if (value.contains('transcript')) {
      final university = RegExp(r'\b(GIU|GUC)\b').firstMatch(source)?.group(1);
      return university == null
          ? 'University Transcript'
          : '$university Transcript';
    }
    if (value.contains('grade') || value.contains('advisory')) {
      final university = RegExp(r'\b(GIU|GUC)\b').firstMatch(source)?.group(1);
      return university == null ? 'Academic Portal' : '$university Portal';
    }
    return source;
  }

  static IconData _sourceIcon(String source) {
    final value = source.toLowerCase();
    if (value.contains('linkedin')) return Icons.badge_outlined;
    if (value.contains('coursera')) return Icons.school_outlined;
    if (value.contains('job') || value.contains('career')) {
      return Icons.work_outline_rounded;
    }
    if (value.contains('cms')) return Icons.folder_copy_outlined;
    if (value.contains('transcript')) return Icons.history_edu_outlined;
    if (value.contains('grade') || value.contains('advisory')) {
      return Icons.school_outlined;
    }
    if (value.contains('practice')) return Icons.quiz_outlined;
    return Icons.link_rounded;
  }

  static String _toolLabel(String name) {
    const labels = {
      'get_advisory_context': 'Advisory Context',
      'list_advisory_courses': 'Course Lookup',
      'get_advisory_course_grades': 'Grade Analysis',
      'get_advisory_transcript': 'Transcript Reader',
      'get_full_transcript': 'Degree History',
      'get_linkedin_pdf_profile': 'Profile Reader',
      'list_grade_seasons': 'Semester Lookup',
      'list_courses_in_season': 'Course Lookup',
      'get_course_grades': 'Grade Analysis',
      'get_transcript': 'Transcript Reader',
      'find_transcript_course': 'Transcript Search',
      'list_cms_courses': 'CMS Course Lookup',
      'get_cms_course_content': 'CMS Content Reader',
      'search_cms_content': 'CMS Search',
      'get_cms_video_transcript': 'Video Transcript',
      'read_cms_pdf': 'PDF Reader',
      'create_practice_set': 'Quiz Builder',
      'search_tech_jobs': 'Job Search',
      'get_company_jobs': 'Career Page Search',
    };
    return labels[name] ??
        name
            .replaceAll(RegExp(r'^(get|list|search)_'), '')
            .replaceAll('_', ' ');
  }

  static IconData _toolIcon(String name) {
    if (name.contains('job')) return Icons.travel_explore_rounded;
    if (name.contains('linkedin')) return Icons.person_search_outlined;
    if (name.contains('practice')) return Icons.quiz_outlined;
    if (name.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (name.contains('video')) return Icons.smart_display_outlined;
    if (name.contains('cms')) return Icons.folder_open_outlined;
    if (name.contains('transcript')) return Icons.history_edu_outlined;
    if (name.contains('grade')) return Icons.analytics_outlined;
    if (name.contains('course') || name.contains('season')) {
      return Icons.school_outlined;
    }
    return Icons.build_circle_outlined;
  }
}

class _CapabilityItem {
  final String kind;
  final String label;
  final IconData icon;
  final bool failed;

  const _CapabilityItem({
    required this.kind,
    required this.label,
    required this.icon,
    this.failed = false,
  });
}

class _CapabilityChip extends StatelessWidget {
  final _CapabilityItem item;
  final bool compact;

  const _CapabilityChip({
    required this.item,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.failed ? LensColors.rose : LensColors.indigo;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .13)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.failed ? Icons.error_outline_rounded : item.icon,
            size: compact ? 12 : 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            '${item.kind} · ${item.label}${item.failed ? ' failed' : ''}',
            style: TextStyle(
              color: item.failed ? LensColors.rose : LensColors.ink,
              fontSize: compact ? 9 : 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
