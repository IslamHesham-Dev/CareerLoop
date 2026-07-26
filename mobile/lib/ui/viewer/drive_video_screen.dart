import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/theme.dart';
import '../core/ai_assist_sheet.dart';

class DriveVideoArgs {
  final String videoId;
  final String title;
  final String courseTitle;
  final String transcriptStatus;

  const DriveVideoArgs({
    required this.videoId,
    required this.title,
    required this.courseTitle,
    required this.transcriptStatus,
  });
}

class DriveVideoScreen extends StatefulWidget {
  final DriveVideoArgs args;

  const DriveVideoScreen({super.key, required this.args});

  @override
  State<DriveVideoScreen> createState() => _DriveVideoScreenState();
}

class _DriveVideoScreenState extends State<DriveVideoScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    final preview = Uri.parse(
      'https://drive.google.com/file/d/${widget.args.videoId}/preview',
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(LensColors.ink)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _progress = 100);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() => _error = error.description);
              }
            }
          },
        ),
      )
      ..loadRequest(preview);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LensColors.ink,
      appBar: AppBar(
        backgroundColor: LensColors.ink,
        foregroundColor: Colors.white,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.args.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              widget.args.courseTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .56),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          if (_error == null)
            WebViewWidget(controller: _controller)
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.video_file_outlined,
                      color: LensColors.rose,
                      size: 42,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'This Drive video could not be embedded.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The owner may need to enable link access.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .58),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_progress < 100 && _error == null)
            Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(value: _progress / 100),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAssist,
        backgroundColor: LensColors.aqua,
        foregroundColor: LensColors.ink,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Video Assist'),
      ),
    );
  }

  void _openAssist() {
    final ready = widget.args.transcriptStatus == 'available';
    final evidence = 'First call get_cms_video_transcript with video_id '
        '"${widget.args.videoId}". Base the answer on that transcript and '
        'clearly say if it is unavailable.';
    showAiAssistSheet(
      context,
      title: 'Video Assist',
      subtitle: widget.args.title,
      icon: Icons.smart_display_outlined,
      actions: [
        AiAssistAction(
          icon: Icons.summarize_outlined,
          title: 'Summarize recording',
          subtitle: ready
              ? 'Topics, explanations, and takeaways'
              : 'Available after the transcript is prepared',
          enabled: ready,
          prompt: '$evidence Summarize this recording from '
              '${widget.args.courseTitle} into a clear topic outline, key '
              'explanations, and a revision checklist.',
        ),
        AiAssistAction(
          icon: Icons.account_tree_outlined,
          title: 'Extract key concepts',
          subtitle: ready
              ? 'Definitions, examples, and relationships'
              : 'Available after the transcript is prepared',
          enabled: ready,
          prompt: '$evidence Extract the key concepts from this recording. '
              'For each concept give its definition, the lecturer\'s example, '
              'and how it connects to the other concepts.',
        ),
        AiAssistAction(
          icon: Icons.style_outlined,
          title: 'Create flashcards',
          subtitle: ready
              ? 'Active-recall cards from the transcript'
              : 'Available after the transcript is prepared',
          enabled: ready,
          prompt: '$evidence Create 15 concise active-recall flashcards from '
              'this recording. Cover definitions, reasoning, and applied '
              'examples. Format each as Front and Back.',
        ),
        AiAssistAction(
          icon: Icons.quiz_outlined,
          title: 'Quiz me',
          subtitle: ready
              ? 'Questions first; answers stay hidden'
              : 'Available after the transcript is prepared',
          enabled: ready,
          prompt: '$evidence Quiz me on this recording with 10 mixed '
              'conceptual and applied questions. Do not reveal answers until '
              'I submit my attempts.',
        ),
      ],
    );
  }
}
