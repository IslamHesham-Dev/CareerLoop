import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';

class NotionExportAction extends StatefulWidget {
  final ChatMessage message;
  final bool compact;

  const NotionExportAction({
    super.key,
    required this.message,
    this.compact = false,
  });

  @override
  State<NotionExportAction> createState() => _NotionExportActionState();
}

class _NotionExportActionState extends State<NotionExportAction> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<NotionRepository>();
    final busy = _working || repository.exporting;
    return TextButton.icon(
      onPressed: busy ? null : _export,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: widget.compact
            ? const EdgeInsets.symmetric(horizontal: 7, vertical: 3)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      icon: busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(
              SimpleIcons.notion,
              size: 15,
              color: LensColors.ink,
            ),
      label: Text(
        'Export to Notion',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _working = true);
    final repository = context.read<NotionRepository>();
    var connected = await repository.refreshStatus();
    if (!mounted) return;

    if (!repository.available) {
      _showError(
        repository.error ??
            repository.configurationMessage ??
            'Notion export is not configured on the CareerLoop backend.',
      );
      setState(() => _working = false);
      return;
    }

    if (!connected) {
      final authorizationUrl = await repository.beginConnection();
      if (!mounted) return;
      if (authorizationUrl == null) {
        if (repository.connected) {
          connected = true;
        } else {
          _showError(
            repository.error ?? 'The Notion connection could not be opened.',
          );
        }
      } else {
        final launched = await launchUrl(
          authorizationUrl,
          mode: LaunchMode.externalApplication,
        );
        if (!mounted) return;
        if (!launched) {
          _showError('Could not open the Notion authorization page.');
        } else {
          connected = await _waitForConnection(repository);
        }
      }
    }

    if (connected && mounted) {
      final result = await repository.exportResponse(
        title: _titleFrom(widget.message.text),
        markdown: widget.message.text,
        sources: widget.message.sources,
      );
      if (!mounted) return;
      if (result == null || result.pageUrl.isEmpty) {
        _showError(repository.error ?? 'The Notion export failed.');
      } else {
        _showSuccess(result);
      }
    }
    if (mounted) setState(() => _working = false);
  }

  Future<bool> _waitForConnection(NotionRepository repository) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finish connecting Notion'),
        content: const Text(
          'Choose your Notion workspace in the browser, allow access, then '
          'return here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final connected = await repository.refreshStatus();
              if (!dialogContext.mounted) return;
              if (connected) {
                Navigator.pop(dialogContext, true);
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      repository.error ??
                          'Not connected yet. Complete the browser step first.',
                    ),
                  ),
                );
              }
            },
            child: const Text('I’ve connected'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccess(NotionExportResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exported to Notion.'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => launchUrl(
            Uri.parse(result.pageUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ),
    );
  }

  String _titleFrom(String markdown) {
    final firstMeaningful = markdown
        .split('\n')
        .map((line) => line.trim())
        .firstWhere(
          (line) => line.isNotEmpty,
          orElse: () => 'CareerLoop explanation',
        )
        .replaceFirst(RegExp(r'^#{1,6}\s*'), '')
        .replaceAll(RegExp(r'[*_`]'), '')
        .trim();
    if (firstMeaningful.isEmpty) return 'CareerLoop explanation';
    return firstMeaningful.length <= 90
        ? firstMeaningful
        : '${firstMeaningful.substring(0, 87)}...';
  }
}

class NotionConnectionCard extends StatefulWidget {
  const NotionConnectionCard({super.key});

  @override
  State<NotionConnectionCard> createState() => _NotionConnectionCardState();
}

class _NotionConnectionCardState extends State<NotionConnectionCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotionRepository>().refreshStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notion = context.watch<NotionRepository>();
    final statusText = notion.connected
        ? notion.workspaceName ?? 'Connected'
        : notion.available
            ? 'Connect once, then export in one tap'
            : notion.configurationMessage ??
                'Notion is not configured on this deployment';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LensColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: LensColors.ink.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(SimpleIcons.notion, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notion',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  statusText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (notion.loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (notion.connected)
            const Icon(Icons.check_circle_rounded, color: LensColors.aqua)
          else
            TextButton(
              onPressed: notion.available
                  ? () => _connect(notion)
                  : notion.refreshStatus,
              child: Text(notion.available ? 'Connect' : 'Retry'),
            ),
        ],
      ),
    );
  }

  Future<void> _connect(NotionRepository notion) async {
    final uri = await notion.beginConnection();
    if (!mounted) return;
    if (notion.connected) return;
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notion.error ?? 'Could not connect Notion.')),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Complete authorization in Notion, then return to Profile.',
        ),
      ),
    );
  }
}
