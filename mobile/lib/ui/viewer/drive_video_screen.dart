import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/theme.dart';
import '../core/content_ai_overlay.dart';

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
              if (mounted) setState(() => _error = error.description);
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
      body: ContentAiOverlay(
        title: 'Video Assist',
        subtitle: widget.args.title,
        contextInstruction: 'First call get_cms_video_transcript with '
            'video_id "${widget.args.videoId}". The open recording is '
            '"${widget.args.title}" from ${widget.args.courseTitle}. Base '
            'answers about its substance on that transcript and clearly say '
            'if it is unavailable.',
        quickActions: const [
          ContentAiQuickAction(
            icon: Icons.summarize_outlined,
            label: 'Summarize this recording',
            prompt: 'Summarize this recording into a topic outline, key '
                'explanations, and a revision checklist.',
          ),
          ContentAiQuickAction(
            icon: Icons.account_tree_outlined,
            label: 'Extract its key concepts',
            prompt: 'Extract the key concepts. Give each definition, the '
                'lecturer\'s example, and its relationship to other concepts.',
          ),
          ContentAiQuickAction(
            icon: Icons.quiz_outlined,
            label: 'Quiz me on this video',
            prompt: 'Quiz me with 10 conceptual and applied questions. Keep '
                'the answers hidden until I attempt them.',
          ),
        ],
        child: Stack(
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
      ),
    );
  }
}
