import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/career_document_repository.dart';
import '../../data/models.dart';
import '../core/content_ai_overlay.dart';

class CareerDocumentViewerArgs {
  final JobOpportunity job;
  final CareerDocument document;
  final String localPath;

  const CareerDocumentViewerArgs({
    required this.job,
    required this.document,
    required this.localPath,
  });
}

class CareerDocumentViewerScreen extends StatefulWidget {
  final CareerDocumentViewerArgs args;

  const CareerDocumentViewerScreen({super.key, required this.args});

  @override
  State<CareerDocumentViewerScreen> createState() =>
      _CareerDocumentViewerScreenState();
}

class _CareerDocumentViewerScreenState
    extends State<CareerDocumentViewerScreen> {
  late CareerDocument _document;
  late String _localPath;

  @override
  void initState() {
    super.initState();
    _document = widget.args.document;
    _localPath = widget.args.localPath;
  }

  @override
  Widget build(BuildContext context) {
    final label = _document.kind == 'resume' ? 'Resume' : 'Cover letter';
    return Scaffold(
      backgroundColor: LensColors.canvas,
      appBar: AppBar(
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            Text(
              '${widget.args.job.company} · Version ${_document.version}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LensColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: ContentAiOverlay(
        title: 'Document Copilot',
        subtitle: 'Refine this ${_document.kind.replaceAll('_', ' ')}',
        contextInstruction: '',
        onSend: _refine,
        quickActions: [
          const ContentAiQuickAction(
            icon: Icons.compress_rounded,
            label: 'Make it sharper and keep one page',
            prompt:
                'Tighten the writing, remove repetition, and keep it to one page.',
          ),
          ContentAiQuickAction(
            icon: Icons.track_changes_rounded,
            label: 'Strengthen the role match',
            prompt:
                'Strengthen the fit for ${widget.args.job.title} using only verified evidence.',
          ),
          const ContentAiQuickAction(
            icon: Icons.data_object_rounded,
            label: 'Emphasize relevant GitHub work',
            prompt:
                'Prioritize the most relevant connected GitHub projects and their verified technology stacks.',
          ),
          const ContentAiQuickAction(
            icon: Icons.school_outlined,
            label: 'Use stronger academic evidence',
            prompt:
                'Use the strongest relevant transcript evidence without overstating it.',
          ),
        ],
        child: PDFView(
          key: ValueKey(
            '${_document.id}:${_document.version}:$_localPath',
          ),
          filePath: _localPath,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          fitPolicy: FitPolicy.WIDTH,
          backgroundColor: LensColors.canvas,
        ),
      ),
    );
  }

  Future<ChatMessage?> _refine(String instruction) async {
    final repository = context.read<CareerDocumentRepository>();
    final updated = await repository.refine(
      widget.args.job,
      _document,
      instruction,
    );
    if (updated == null) return null;
    final file = await repository.download(updated);
    if (!mounted) return null;
    setState(() {
      _document = updated;
      _localPath = file.path;
    });
    return ChatMessage(
      isUser: false,
      text: 'Updated **${updated.title}** to version ${updated.version}. '
          'The PDF preview now shows the revised, job-specific document.',
      createdAt: DateTime.now(),
      sources: updated.sourcesUsed,
      tools: const [
        ToolActivity(name: 'Career evidence merge', status: 'completed'),
        ToolActivity(name: 'LaTeX template compiler', status: 'completed'),
      ],
    );
  }
}
