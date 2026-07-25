import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/api_client.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';
import '../viewer/drive_video_screen.dart';
import '../viewer/pdf_viewer_screen.dart';

class CmsCourseScreen extends StatefulWidget {
  final CmsCourse course;

  const CmsCourseScreen({super.key, required this.course});

  @override
  State<CmsCourseScreen> createState() => _CmsCourseScreenState();
}

class _CmsCourseScreenState extends State<CmsCourseScreen> {
  String _videoFilter = 'all';
  String? _resourceWeek;
  final Set<String> _downloading = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CmsRepository>().loadCourseContent(widget.course.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cms = context.watch<CmsRepository>();
    final content = cms.content[widget.course.id];
    final course = content?.course ?? widget.course;
    final loading = cms.loadingContent.contains(widget.course.id);
    final resources = content?.cmsResources ?? const <CmsResource>[];
    final videos = (content?.availableVideos ?? const <CmsVideo>[])
        .where(
          (video) => _videoFilter == 'all' || video.contentType == _videoFilter,
        )
        .toList();
    final videoFilters = <String>{
      'all',
      ...?content?.availableVideos.map((video) => video.contentType),
    }.toList();
    final grouped = _groupResources(resources);
    final selectedWeek =
        grouped.containsKey(_resourceWeek) ? _resourceWeek : null;
    final visibleGroups = selectedWeek == null
        ? grouped.entries.toList()
        : grouped.entries.where((entry) => entry.key == selectedWeek).toList();

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => cms.loadCourseContent(
              widget.course.id,
              force: true,
            ),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        const GradientPill(
                          label: 'Live GIU CMS',
                          icon: Icons.lock_outline_rounded,
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: () => _askCourseAi(course),
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 17,
                          ),
                          label: const Text('Ask AI'),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.code,
                          style: const TextStyle(
                            color: LensColors.indigo,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (content != null) ...[
                          const SizedBox(height: 18),
                          _CourseSummary(
                            resources: resources.length,
                            videos: content.availableVideos.length,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (loading && content == null)
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 22),
                    sliver: SliverToBoxAdapter(
                      child: LensCard(
                        child: LensLoading(
                          label: 'Organizing CMS course materials...',
                        ),
                      ),
                    ),
                  )
                else if (cms.error != null && content == null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    sliver: SliverToBoxAdapter(
                      child: LensError(
                        message: cms.error!,
                        onRetry: () => cms.loadCourseContent(
                          widget.course.id,
                          force: true,
                        ),
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                    sliver: SliverToBoxAdapter(
                      child: _SectionTitle(
                        title: 'CMS resources',
                        detail: '${resources.length} files · newest first',
                      ),
                    ),
                  ),
                  if (resources.isEmpty)
                    const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 22),
                      sliver: SliverToBoxAdapter(
                        child: LensCard(
                          child: Text(
                            'No downloadable resources are currently shown for this course.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                      sliver: SliverToBoxAdapter(
                        child: _WeekNavigator(
                          labels: grouped.keys.toList(),
                          selected: selectedWeek,
                          onSelected: (label) => setState(
                            () => _resourceWeek = label,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      sliver: SliverList.list(
                        children: visibleGroups
                            .map(
                              (entry) => _WeekGroup(
                                label: entry.key,
                                resources: entry.value,
                                downloading: _downloading,
                                onOpen: _openResource,
                                onAskAi: (resource) =>
                                    _askResourceAi(course, resource),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                  if (content?.availableVideos.isNotEmpty ?? false) ...[
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(22, 24, 22, 10),
                      sliver: SliverToBoxAdapter(
                        child: _VideoArchiveIntro(),
                      ),
                    ),
                    if (videoFilters.length > 1)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                        sliver: SliverToBoxAdapter(
                          child: SizedBox(
                            height: 38,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: videoFilters.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final filter = videoFilters[index];
                                return ChoiceChip(
                                  selected: _videoFilter == filter,
                                  onSelected: (_) => setState(
                                    () => _videoFilter = filter,
                                  ),
                                  label: Text(_label(filter)),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
                      sliver: SliverList.separated(
                        itemCount: videos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _VideoCard(
                          video: videos[index],
                          onOpen: () => _openVideo(videos[index]),
                          onAskAi: () => _askVideoAi(course, videos[index]),
                        ),
                      ),
                    ),
                  ] else
                    const SliverPadding(
                      padding: EdgeInsets.only(bottom: 120),
                      sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Map<String, List<CmsResource>> _groupResources(
    List<CmsResource> resources,
  ) {
    final grouped = <String, List<CmsResource>>{};
    for (final resource in resources) {
      final label =
          resource.week == null ? 'General resources' : 'Week ${resource.week}';
      grouped.putIfAbsent(label, () => []).add(resource);
    }
    final entries = grouped.entries.toList()
      ..sort((left, right) {
        final leftWeek = _weekNumber(left.key);
        final rightWeek = _weekNumber(right.key);
        if (leftWeek == null && rightWeek == null) {
          return left.key.compareTo(right.key);
        }
        if (leftWeek == null) return 1;
        if (rightWeek == null) return -1;
        return rightWeek.compareTo(leftWeek);
      });
    return Map.fromEntries(entries);
  }

  static int? _weekNumber(String label) {
    final match = RegExp(r'^Week (\d+)$').firstMatch(label);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static String _label(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  Future<void> _openResource(CmsResource resource) async {
    if (_downloading.contains(resource.id)) return;
    setState(() => _downloading.add(resource.id));
    try {
      final downloaded =
          await context.read<CmsRepository>().downloadResource(resource);
      if (downloaded.isPdf) {
        if (!mounted) return;
        await context.push(
          '/viewer/pdf',
          extra: PdfViewerArgs(
            path: downloaded.path,
            title: resource.title,
            courseTitle:
                (context.read<CmsRepository>().content[widget.course.id])
                        ?.course
                        .title ??
                    widget.course.title,
            resourceId: resource.id,
          ),
        );
        return;
      }
      final result = await OpenFilex.open(downloaded.path);
      if (result.type != ResultType.done && mounted) {
        _message(
          result.message.isEmpty
              ? 'The file was downloaded, but no compatible viewer was found.'
              : result.message,
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        _message(error.message);
      }
    } catch (_) {
      if (mounted) _message('This CMS file could not be opened right now.');
    } finally {
      if (mounted) setState(() => _downloading.remove(resource.id));
    }
  }

  void _openVideo(CmsVideo video) {
    context.push(
      '/viewer/video',
      extra: DriveVideoArgs(
        videoId: video.id,
        title: video.title,
        courseTitle: (context.read<CmsRepository>().content[widget.course.id])
                ?.course
                .title ??
            widget.course.title,
        transcriptStatus: video.transcriptStatus,
      ),
    );
  }

  void _askCourseAi(CmsCourse course) {
    context.read<AdvisorRepository>().send(
          'Use the live GIU CMS tools to help me study ${course.code} '
          '${course.title} in ${course.season}. First inspect the available '
          'course resources and supplemental videos, then suggest the most '
          'useful next study action based only on accessible evidence.',
        );
    context.go('/advisor');
  }

  void _askResourceAi(CmsCourse course, CmsResource resource) {
    context.read<AdvisorRepository>().send(
          'I want help with the CMS resource "${resource.title}" in '
          '${course.code} ${course.title}. Its resource_id is "${resource.id}". '
          '${resource.fileExtension.toLowerCase() == 'pdf' ? 'Call read_cms_pdf before discussing or summarizing its contents.' : 'Inspect the CMS metadata and do not invent its contents if it cannot be read.'}',
        );
    context.go('/advisor');
  }

  void _askVideoAi(CmsCourse course, CmsVideo video) {
    context.read<AdvisorRepository>().send(
          'Help me study the supplemental video "${video.title}" in '
          '${course.code} ${course.title}. Its video_id is "${video.id}". '
          'Call get_cms_video_transcript before discussing its substance.',
        );
    context.go('/advisor');
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}

class _CourseSummary extends StatelessWidget {
  final int resources;
  final int videos;

  const _CourseSummary({required this.resources, required this.videos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LensColors.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              icon: Icons.folder_copy_outlined,
              value: '$resources',
              label: 'CMS files',
            ),
          ),
          Container(
            width: 1,
            height: 38,
            color: Colors.white.withValues(alpha: .13),
          ),
          Expanded(
            child: _SummaryMetric(
              icon: Icons.play_circle_outline_rounded,
              value: '$videos',
              label: videos == 0 ? 'No video archive' : 'Extra videos',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: LensColors.aqua, size: 22),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .58),
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String detail;

  const _SectionTitle({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Text(detail, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  final List<String> labels;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _WeekNavigator({
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    String? newestWeek;
    for (final label in labels) {
      if (label.startsWith('Week ')) {
        newestWeek = label;
        break;
      }
    }
    final options = <String?>[null, ...labels];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jump to week',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final value = options[index];
              final label = value == null
                  ? 'All weeks'
                  : value == newestWeek
                      ? '$value · Latest'
                      : value;
              return ChoiceChip(
                selected: selected == value,
                onSelected: (_) => onSelected(value),
                avatar: value == newestWeek
                    ? const Icon(Icons.update_rounded, size: 16)
                    : null,
                label: Text(label),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeekGroup extends StatelessWidget {
  final String label;
  final List<CmsResource> resources;
  final Set<String> downloading;
  final ValueChanged<CmsResource> onOpen;
  final ValueChanged<CmsResource> onAskAi;

  const _WeekGroup({
    required this.label,
    required this.resources,
    required this.downloading,
    required this.onOpen,
    required this.onAskAi,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 3, bottom: 9),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: LensColors.muted,
                fontSize: 10,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...resources.map(
            (resource) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _ResourceCard(
                resource: resource,
                downloading: downloading.contains(resource.id),
                onOpen: () => onOpen(resource),
                onAskAi: () => onAskAi(resource),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final CmsResource resource;
  final bool downloading;
  final VoidCallback onOpen;
  final VoidCallback onAskAi;

  const _ResourceCard({
    required this.resource,
    required this.downloading,
    required this.onOpen,
    required this.onAskAi,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (resource.fileExtension.toLowerCase()) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'ppt' || 'pptx' => Icons.slideshow_outlined,
      'doc' || 'docx' => Icons.description_outlined,
      'zip' || 'rar' => Icons.folder_zip_outlined,
      _ when resource.isVod => Icons.play_circle_outline_rounded,
      _ => Icons.insert_drive_file_outlined,
    };
    return LensCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: LensColors.indigo.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: LensColors.indigo, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    resource.contentType,
                    if (resource.fileExtension.isNotEmpty)
                      resource.fileExtension.toUpperCase(),
                    if (resource.subtitle.isNotEmpty) resource.subtitle,
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Ask AI about this',
            onPressed: onAskAi,
            icon: const Icon(
              Icons.auto_awesome_outlined,
              color: LensColors.violet,
              size: 20,
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Download and open',
            onPressed: downloading ? null : onOpen,
            icon: downloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _VideoArchiveIntro extends StatelessWidget {
  const _VideoArchiveIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: LensColors.violet.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: LensColors.violet.withValues(alpha: .13),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.video_library_outlined, color: LensColors.violet),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available videos',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Supplemental Drive recordings matched to this course. They are separate from official CMS files.',
                  style: TextStyle(
                    color: LensColors.muted,
                    fontSize: 11,
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

class _VideoCard extends StatelessWidget {
  final CmsVideo video;
  final VoidCallback onOpen;
  final VoidCallback onAskAi;

  const _VideoCard({
    required this.video,
    required this.onOpen,
    required this.onAskAi,
  });

  @override
  Widget build(BuildContext context) {
    final transcriptReady = video.transcriptStatus == 'available';
    return LensCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: LensColors.violet.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: LensColors.violet,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    _CmsCourseScreenState._label(video.contentType),
                    if (video.sizeLabel.isNotEmpty) video.sizeLabel,
                    transcriptReady ? 'Transcript ready' : 'Transcript pending',
                  ].join('  ·  '),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ask AI about this video',
            onPressed: onAskAi,
            icon: const Icon(
              Icons.auto_awesome_outlined,
              color: LensColors.violet,
              size: 20,
            ),
          ),
          const Icon(Icons.play_circle_outline, color: LensColors.muted),
        ],
      ),
    );
  }
}
