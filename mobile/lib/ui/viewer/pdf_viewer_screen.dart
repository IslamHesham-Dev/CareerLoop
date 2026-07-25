import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/repositories.dart';

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
              onPressed: () => _askAi(context),
              icon: const Icon(Icons.auto_awesome_rounded, size: 17),
              label: const Text('Ask AI'),
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

  void _askAi(BuildContext context) {
    context.read<AdvisorRepository>().send(
          'I am viewing the CMS PDF "${args.title}" in '
          '${args.courseTitle}. Use read_cms_pdf with resource_id '
          '"${args.resourceId}" before answering. Give me a concise overview '
          'of the document, then suggest useful study actions I can ask for.',
        );
    context.go('/advisor');
  }
}
