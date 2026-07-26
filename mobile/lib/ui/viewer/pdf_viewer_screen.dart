import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../app/theme.dart';
import '../core/ai_assist_sheet.dart';

class PdfViewerArgs {
  final String path;
  final String title;
  final String courseTitle;
  final String resourceId;

  const PdfViewerArgs({
    required this.path,
    required this.title,
    required this.courseTitle,
    required this.resourceId,
  });
}

class PdfViewerScreen extends StatelessWidget {
  final PdfViewerArgs args;

  const PdfViewerScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              args.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              args.courseTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LensColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton.tonalIcon(
              onPressed: () => _openAssist(context),
              icon: const Icon(Icons.auto_awesome_rounded, size: 17),
              label: const Text('Assist'),
            ),
          ),
        ],
      ),
      body: PDFView(
        filePath: args.path,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        fitPolicy: FitPolicy.WIDTH,
        backgroundColor: const Color(0xFFEEF0F7),
      ),
    );
  }

  void _openAssist(BuildContext context) {
    final evidence = 'First call read_cms_pdf with resource_id '
        '"${args.resourceId}". Base the response only on the extracted PDF '
        'and clearly mention if any page could not be read.';
    showAiAssistSheet(
      context,
      title: 'Assist with this PDF',
      subtitle: args.title,
      icon: Icons.picture_as_pdf_outlined,
      actions: [
        AiAssistAction(
          icon: Icons.summarize_outlined,
          title: 'Smart summary',
          subtitle: 'Key ideas, definitions, and the document structure',
          prompt:
              '$evidence Summarize "${args.title}" from ${args.courseTitle}. '
              'Organize the answer into key concepts, important details, and '
              'a short revision checklist.',
        ),
        AiAssistAction(
          icon: Icons.lightbulb_outline_rounded,
          title: 'Explain difficult concepts',
          subtitle: 'Teach the material clearly with examples',
          prompt:
              '$evidence Teach me the difficult concepts in "${args.title}" '
              'step by step. Use simple explanations, then a technical '
              'explanation and a concrete example for each concept.',
        ),
        AiAssistAction(
          icon: Icons.quiz_outlined,
          title: 'Quiz me',
          subtitle: 'Questions first, answers hidden until requested',
          prompt: '$evidence Create a 10-question active-recall quiz from '
              '"${args.title}". Mix conceptual and applied questions. Do not '
              'show the answers yet; wait for my attempts.',
        ),
        AiAssistAction(
          icon: Icons.fact_check_outlined,
          title: 'Exam notes',
          subtitle: 'High-yield facts, traps, and likely applications',
          prompt:
              '$evidence Turn "${args.title}" into concise exam-preparation '
              'notes. Highlight high-yield concepts, common mistakes, '
              'comparisons, formulas, and likely application questions.',
        ),
      ],
    );
  }
}
