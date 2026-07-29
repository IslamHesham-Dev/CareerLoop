import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/api_client.dart';
import '../../data/career_document_repository.dart';
import '../../data/models.dart';
import '../career/career_document_viewer_screen.dart';
import '../core/lens_components.dart';

class GeneratedDocumentsScreen extends StatefulWidget {
  const GeneratedDocumentsScreen({super.key});

  @override
  State<GeneratedDocumentsScreen> createState() =>
      _GeneratedDocumentsScreenState();
}

class _GeneratedDocumentsScreenState extends State<GeneratedDocumentsScreen> {
  String? _opening;

  @override
  Widget build(BuildContext context) {
    final histories = context.watch<CareerDocumentRepository>().histories;
    return Scaffold(
      backgroundColor: LensColors.canvas,
      appBar: LensPageAppBar(
        title: 'Generated documents',
        onBack: () => context.pop(),
      ),
      body: histories.isEmpty
          ? const _EmptyLibrary()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              itemCount: histories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final history = histories[index];
                return _DocumentHistoryCard(
                  history: history,
                  opening: _opening,
                  onOpen: (document) => _open(history.job, document),
                );
              },
            ),
    );
  }

  Future<void> _open(
    JobOpportunity job,
    CareerDocument document,
  ) async {
    final openingKey = '${document.id}:${document.version}';
    setState(() => _opening = openingKey);
    try {
      final file =
          await context.read<CareerDocumentRepository>().download(document);
      if (!mounted) return;
      await context.push(
        '/career-document',
        extra: CareerDocumentViewerArgs(
          job: job,
          document: document,
          localPath: file.path,
        ),
      );
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exception.message)),
      );
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_copy_outlined,
              color: LensColors.violet,
              size: 38,
            ),
            const SizedBox(height: 14),
            Text(
              'No generated documents yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            const Text(
              'Master resumes and job-specific resumes or cover letters will '
              'appear here with their revision history.',
              textAlign: TextAlign.center,
              style: TextStyle(color: LensColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentHistoryCard extends StatelessWidget {
  final CareerDocumentHistory history;
  final String? opening;
  final ValueChanged<CareerDocument> onOpen;

  const _DocumentHistoryCard({
    required this.history,
    required this.opening,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final latest = history.versions.first;
    final master = history.job.id == 'careerloop-master-resume';
    final kindLabel = history.kind == 'resume' ? 'Resume' : 'Cover letter';
    return LensCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LensColors.violet.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  history.kind == 'resume'
                      ? Icons.description_outlined
                      : Icons.mail_outline_rounded,
                  color: LensColors.violet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      master ? 'Master resume' : kindLabel,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      master
                          ? history.job.title
                          : '${history.job.title} · ${history.job.company}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LensColors.muted,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${history.versions.length} ${history.versions.length == 1 ? 'version' : 'versions'}',
                style: const TextStyle(
                  color: LensColors.indigo,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (latest.generationContext.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              latest.generationContext,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LensColors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 7),
          ...history.versions.map(
            (document) {
              final key = '${document.id}:${document.version}';
              final busy = opening == key;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: LensColors.indigo.withValues(alpha: .09),
                  child: Text(
                    'v${document.version}',
                    style: const TextStyle(
                      color: LensColors.indigo,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                title: Text(
                  document.revisionNote.isEmpty
                      ? 'Original generation'
                      : document.revisionNote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  DateFormat('MMM d, yyyy · HH:mm').format(
                    document.updatedAt.toLocal(),
                  ),
                  style: const TextStyle(fontSize: 10.5),
                ),
                trailing: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: busy ? null : () => onOpen(document),
              );
            },
          ),
        ],
      ),
    );
  }
}
