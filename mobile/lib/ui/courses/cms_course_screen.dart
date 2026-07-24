import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class CmsCourseScreen extends StatefulWidget {
  final CmsCourse course;

  const CmsCourseScreen({super.key, required this.course});

  @override
  State<CmsCourseScreen> createState() => _CmsCourseScreenState();
}

class _CmsCourseScreenState extends State<CmsCourseScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CmsRepository>().loadCourseContent(widget.course.slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cms = context.watch<CmsRepository>();
    final content = cms.content[widget.course.slug];
    final loading = cms.loadingContent.contains(widget.course.slug);
    final items = content?.items
            .where(
              (item) => _filter == 'all' || item.contentType == _filter,
            )
            .toList() ??
        const <CmsContentItem>[];
    final filters = <String>{
      'all',
      ...?content?.items.map((item) => item.contentType),
    }.toList();

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      const GradientPill(
                        label: 'CMS + Drive',
                        icon: Icons.cloud_done_outlined,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.course.catalogCode,
                        style: const TextStyle(
                          color: LensColors.indigo,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.course.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 9),
                      Text(
                        widget.course.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [LensColors.ink, Color(0xFF29336D)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.smart_display_rounded,
                              color: LensColors.aqua,
                              size: 28,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.course.videoCount} available videos',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.course.transcribedCount} transcripts ready for AI study help',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: .62),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (filters.length > 1) ...[
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: filters.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final filter = filters[index];
                              return ChoiceChip(
                                selected: _filter == filter,
                                onSelected: (_) =>
                                    setState(() => _filter = filter),
                                label: Text(_label(filter)),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _filter == 'all'
                                  ? 'All course content'
                                  : _label(_filter),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (content != null)
                            Text(
                              '${items.length} videos',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (loading && content == null)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  sliver: SliverToBoxAdapter(
                    child: LensCard(
                      child: LensLoading(label: 'Loading CMS videos...'),
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
                        widget.course.slug,
                        force: true,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 11),
                    itemBuilder: (context, index) => _VideoCard(
                      item: items[index],
                      onOpen: () => _openVideo(context, items[index]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  Future<void> _openVideo(
    BuildContext context,
    CmsContentItem item,
  ) async {
    final opened = await launchUrl(
      Uri.parse(item.driveUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Drive could not open this video.'),
        ),
      );
    }
  }
}

class _VideoCard extends StatelessWidget {
  final CmsContentItem item;
  final VoidCallback onOpen;

  const _VideoCard({required this.item, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final transcriptReady = item.transcriptStatus == 'available';
    return LensCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: LensColors.indigo.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: LensColors.indigo,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    _MetaPill(
                        label: _CmsCourseScreenState._label(
                      item.contentType,
                    )),
                    if (item.sizeLabel.isNotEmpty)
                      _MetaPill(label: item.sizeLabel),
                    _MetaPill(
                      label: transcriptReady
                          ? 'AI transcript ready'
                          : 'Transcript pending',
                      color:
                          transcriptReady ? LensColors.aqua : LensColors.amber,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.open_in_new_rounded, color: LensColors.muted),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color? color;

  const _MetaPill({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? LensColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
