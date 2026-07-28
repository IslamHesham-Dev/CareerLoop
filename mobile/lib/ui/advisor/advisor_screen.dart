import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/capability_footer.dart';
import '../core/notion_export_action.dart';
import '../core/practice_launch_card.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  ChatMessage? _messageToReveal;
  GlobalKey? _messageToRevealKey;

  static const _suggestions = [
    'Turn my academic strengths into career evidence',
    'Find my weakest assessment and plan the next move',
    'Summarize my academic profile',
    'Prepare a decision brief from my verified data',
    'Create a 10-question interactive quiz for my weakest current course',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestion]) async {
    final text = suggestion ?? _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    final request = context.read<AdvisorRepository>().send(text);
    _scrollToEnd();
    final response = await request;
    if (!mounted) return;
    if (response == null) {
      _scrollToEnd();
      return;
    }
    setState(() {
      _messageToReveal = response;
      _messageToRevealKey = GlobalKey();
    });
    _scrollToResponseStart();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _scrollToResponseStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final responseContext = _messageToRevealKey?.currentContext;
      if (responseContext == null) return;
      Scrollable.ensureVisible(
        responseContext,
        alignment: 0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final advisor = context.watch<AdvisorRepository>();
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: LensColors.indigo.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: LensColors.indigo,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    'Ask CareerLoop',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Practice library',
                  onPressed: () => context.push('/practice'),
                  icon: const Icon(Icons.quiz_outlined),
                ),
                IconButton(
                  tooltip: 'Reset conversation',
                  onPressed: advisor.messages.isEmpty
                      ? null
                      : () => _confirmReset(context),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: LensColors.line),
          Expanded(
            child: advisor.messages.isEmpty
                ? _AdvisorWelcome(onPrompt: _send)
                : ListView.builder(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                    itemCount:
                        advisor.messages.length + (advisor.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == advisor.messages.length) {
                        return const _ThinkingBubble();
                      }
                      final message = advisor.messages[index];
                      final bubble = _MessageBubble(message: message);
                      if (identical(message, _messageToReveal)) {
                        return KeyedSubtree(
                          key: _messageToRevealKey,
                          child: bubble,
                        );
                      }
                      return bubble;
                    },
                  ),
          ),
          if (advisor.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: LensColors.rose.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 18, color: LensColors.rose),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        advisor.error!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _Composer(
            controller: _controller,
            isSending: advisor.isSending,
            onSend: _send,
            quickPrompts: _suggestions,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a fresh conversation?'),
        content: const Text(
          'Your evidence and saved practice stay available, but the Copilot will forget this chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (reset == true && context.mounted) {
      await context.read<AdvisorRepository>().reset();
    }
  }
}

class _AdvisorWelcome extends StatelessWidget {
  final ValueChanged<String> onPrompt;

  const _AdvisorWelcome({required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 36, 22, 24),
      children: [
        Text(
          'How can I help?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Ask about your academic record, course progress, or career profile.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LensColors.muted,
              ),
        ),
        const SizedBox(height: 24),
        ..._AdvisorScreenState._suggestions.map(
          (suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: LensColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onPrompt(suggestion),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          suggestion,
                          style: const TextStyle(
                            color: LensColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: LensColors.muted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 330),
          margin: const EdgeInsets.only(left: 44, bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: LensColors.indigo,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: Text(
            message.text,
            style: const TextStyle(color: Colors.white, height: 1.4),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: LensColors.indigo,
              ),
              SizedBox(width: 7),
              Text(
                'CareerLoop',
                style: TextStyle(
                  color: LensColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MarkdownBody(
            data: message.text,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LensColors.ink,
                    fontSize: 14,
                  ),
              h2: Theme.of(context).textTheme.titleLarge,
              h3: Theme.of(context).textTheme.titleMedium,
              listBullet: const TextStyle(color: LensColors.indigo),
              tableBorder: TableBorder.all(color: LensColors.line),
              tableCellsPadding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: NotionExportAction(message: message),
          ),
          if (message.practiceSet != null) ...[
            const SizedBox(height: 13),
            PracticeLaunchCard(practiceSet: message.practiceSet!),
          ],
          const SizedBox(height: 14),
          CapabilityFooter(
            tools: message.tools,
            sources: message.sources,
          ),
          const SizedBox(height: 2),
          const Divider(height: 1, color: LensColors.line),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 22),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Working on your answer...',
            style: TextStyle(fontSize: 12, color: LensColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final List<String> quickPrompts;

  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.quickPrompts,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.paddingOf(context).bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: LensColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: PopupMenuButton<String>(
              tooltip: 'Quick prompts',
              enabled: !isSending,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add_rounded),
              onSelected: (value) {
                controller.text = value;
                onSend();
              },
              itemBuilder: (context) => quickPrompts
                  .map(
                    (prompt) => PopupMenuItem(
                      value: prompt,
                      child: Text(prompt),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Ask CareerLoop...',
                hintStyle: const TextStyle(
                  color: LensColors.muted,
                  fontSize: 14,
                ),
                fillColor: LensColors.canvas,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: LensColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: LensColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: LensColors.indigo, width: 1.4),
                ),
                suffixIcon: keyboardVisible
                    ? IconButton(
                        tooltip: 'Hide keyboard',
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        icon: const Icon(
                          Icons.keyboard_hide_rounded,
                          size: 19,
                        ),
                      )
                    : null,
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              onSubmitted: (_) => onSend(),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
          const SizedBox(width: 7),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: isSending ? null : onSend,
            style: IconButton.styleFrom(
              minimumSize: const Size(42, 42),
              maximumSize: const Size(42, 42),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.arrow_upward_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
