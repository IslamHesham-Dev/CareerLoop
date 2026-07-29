import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import 'capability_footer.dart';
import 'notion_export_action.dart';
import 'practice_launch_card.dart';

class ContentAiOverlayController {
  _ContentAiOverlayState? _state;

  void open({String? prompt}) {
    _state?._openFromController(prompt);
  }
}

class ContentAiQuickAction {
  final IconData icon;
  final String label;
  final String prompt;

  const ContentAiQuickAction({
    required this.icon,
    required this.label,
    required this.prompt,
  });
}

class ContentAiOverlay extends StatefulWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final String contextInstruction;
  final List<ContentAiQuickAction> quickActions;
  final ContentAiOverlayController? controller;
  final Future<ChatMessage?> Function(String prompt)? onSend;
  final bool showLauncher;
  final String welcomeDescription;

  const ContentAiOverlay({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    required this.contextInstruction,
    required this.quickActions,
    this.controller,
    this.onSend,
    this.showLauncher = true,
    this.welcomeDescription =
        'Ask about the content on this screen or choose a focused starting point.',
  });

  @override
  State<ContentAiOverlay> createState() => _ContentAiOverlayState();
}

class _ContentAiOverlayState extends State<ContentAiOverlay> {
  static const _bubbleSize = 58.0;
  final _controller = TextEditingController();
  final _composerFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  ChatMessage? _messageToReveal;
  GlobalKey? _messageToRevealKey;
  Offset? _bubblePosition;
  bool _expanded = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(covariant ContentAiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._state == this) {
        oldWidget.controller?._state = null;
      }
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) {
      widget.controller?._state = null;
    }
    _controller.dispose();
    _composerFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final position = _clampedPosition(constraints);
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (_expanded)
              Positioned.fill(
                child: _ChatPanel(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  messages: _messages,
                  quickActions: widget.quickActions,
                  welcomeDescription: widget.welcomeDescription,
                  controller: _controller,
                  focusNode: _composerFocusNode,
                  scrollController: _scrollController,
                  messageToReveal: _messageToReveal,
                  messageToRevealKey: _messageToRevealKey,
                  sending: _sending,
                  error: _error,
                  onMinimize: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _expanded = false);
                  },
                  onPrompt: _send,
                  onDraft: _prepareDraft,
                ),
              )
            else if (widget.showLauncher)
              Positioned(
                left: position.dx,
                top: position.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _bubblePosition = _clampOffset(
                        position + details.delta,
                        constraints,
                      );
                    });
                  },
                  child: Semantics(
                    button: true,
                    label: 'Open ${widget.title}',
                    child: Material(
                      elevation: 4,
                      shadowColor: LensColors.ink.withValues(alpha: .18),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => setState(() => _expanded = true),
                        child: Ink(
                          width: _bubbleSize,
                          height: _bubbleSize,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: LensColors.indigo,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Offset _clampedPosition(BoxConstraints constraints) {
    final fallback = Offset(
      constraints.maxWidth - _bubbleSize - 18,
      constraints.maxHeight - _bubbleSize - 22,
    );
    return _clampOffset(_bubblePosition ?? fallback, constraints);
  }

  Offset _clampOffset(Offset position, BoxConstraints constraints) {
    const edge = 10.0;
    return Offset(
      position.dx.clamp(edge, constraints.maxWidth - _bubbleSize - edge),
      position.dy.clamp(edge, constraints.maxHeight - _bubbleSize - edge),
    );
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;
    _controller.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _messages.add(
        ChatMessage(
          isUser: true,
          text: trimmed,
          createdAt: DateTime.now(),
        ),
      );
      _sending = true;
      _error = null;
    });
    _scrollToEnd();

    AdvisorRepository? advisor;
    ChatMessage? response;
    try {
      if (widget.onSend != null) {
        response = await widget.onSend!(trimmed);
      } else {
        advisor = context.read<AdvisorRepository>();
        response = await advisor.sendContextual(
          visibleText: trimmed,
          agentText: '${widget.contextInstruction}\n\n'
              'The student asks about the content currently open on screen:\n'
              '$trimmed',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'The requested update could not be completed.';
        _sending = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      if (response != null) {
        _messages.add(response);
        _messageToReveal = response;
        _messageToRevealKey = GlobalKey();
      } else {
        _error = widget.onSend == null
            ? advisor?.error ?? 'The assistant could not respond right now.'
            : 'The requested refinement could not be applied.';
      }
      _sending = false;
    });
    if (response != null) {
      _scrollToResponseStart();
    } else {
      _scrollToEnd();
    }
  }

  void _openFromController(String? prompt) {
    if (!mounted) return;
    setState(() => _expanded = true);
    if (prompt != null && prompt.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _prepareDraft(prompt),
      );
    }
  }

  void _prepareDraft(String text) {
    if (!mounted) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _composerFocusNode.requestFocus();
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
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class _ChatPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ChatMessage> messages;
  final List<ContentAiQuickAction> quickActions;
  final String welcomeDescription;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final ChatMessage? messageToReveal;
  final GlobalKey? messageToRevealKey;
  final bool sending;
  final String? error;
  final VoidCallback onMinimize;
  final ValueChanged<String> onPrompt;
  final ValueChanged<String> onDraft;

  const _ChatPanel({
    required this.title,
    required this.subtitle,
    required this.messages,
    required this.quickActions,
    required this.welcomeDescription,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.messageToReveal,
    required this.messageToRevealKey,
    required this.sending,
    required this.error,
    required this.onMinimize,
    required this.onPrompt,
    required this.onDraft,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: .26),
      child: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            widthFactor: 1,
            heightFactor: .86,
            child: Material(
              elevation: 22,
              color: LensColors.canvas,
              shadowColor: Colors.black45,
              borderRadius: BorderRadius.circular(26),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 13, 9, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: LensColors.line),
                      ),
                    ),
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
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: LensColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Minimize assistant',
                          onPressed: onMinimize,
                          icon: const Icon(Icons.remove_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: messages.isEmpty
                        ? _ChatWelcome(
                            quickActions: quickActions,
                            description: welcomeDescription,
                            onPrompt: onDraft,
                          )
                        : ListView.builder(
                            controller: scrollController,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                            itemCount: messages.length + (sending ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == messages.length) {
                                return const _ContentThinkingBubble();
                              }
                              final message = messages[index];
                              final bubble = _ContentMessageBubble(
                                message: message,
                              );
                              if (identical(message, messageToReveal)) {
                                return KeyedSubtree(
                                  key: messageToRevealKey,
                                  child: bubble,
                                );
                              }
                              return bubble;
                            },
                          ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: LensColors.rose,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  _OverlayComposer(
                    controller: controller,
                    focusNode: focusNode,
                    isSending: sending,
                    quickActions: quickActions,
                    onPrompt: onPrompt,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final List<ContentAiQuickAction> quickActions;
  final ValueChanged<String> onPrompt;

  const _OverlayComposer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.quickActions,
    required this.onPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
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
            child: IconButton.filledTonal(
              tooltip: 'Quick prompts',
              onPressed: isSending ? null : () => _showQuickPrompts(context),
              style: IconButton.styleFrom(
                backgroundColor: LensColors.indigo.withValues(alpha: .09),
                foregroundColor: LensColors.indigo,
                disabledBackgroundColor: LensColors.line,
                minimumSize: const Size(42, 42),
                maximumSize: const Size(42, 42),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
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
              onSubmitted: (_) => onPrompt(controller.text),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
          const SizedBox(width: 7),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: isSending ? null : () => onPrompt(controller.text),
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

  Future<void> _showQuickPrompts(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showModalBottomSheet<ContentAiQuickAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: LensColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .68,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick prompts',
                          style: TextStyle(
                            color: LensColors.ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Choose a focused starting point.',
                          style: TextStyle(
                            color: LensColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: LensColors.line),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                itemCount: quickActions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final action = quickActions[index];
                  const colors = [
                    LensColors.indigo,
                    LensColors.rose,
                    LensColors.aqua,
                    LensColors.violet,
                    LensColors.amber,
                  ];
                  final color = colors[index % colors.length];
                  return Material(
                    color: LensColors.card,
                    borderRadius: BorderRadius.circular(17),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(sheetContext).pop(action),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: LensColors.line),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(action.icon, color: color, size: 21),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Text(
                                action.label,
                                style: const TextStyle(
                                  color: LensColors.ink,
                                  fontSize: 13.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: LensColors.muted,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    controller.value = TextEditingValue(
      text: selected.prompt,
      selection: TextSelection.collapsed(offset: selected.prompt.length),
    );
    focusNode.requestFocus();
  }
}

class _ChatWelcome extends StatelessWidget {
  final List<ContentAiQuickAction> quickActions;
  final String description;
  final ValueChanged<String> onPrompt;

  const _ChatWelcome({
    required this.quickActions,
    required this.description,
    required this.onPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      children: [
        const Text(
          'How can I help?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        Text(
          description,
          style: const TextStyle(color: LensColors.muted, height: 1.4),
        ),
        const SizedBox(height: 20),
        ...quickActions.map(
          (action) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: LensColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onPrompt(action.prompt),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(action.icon, color: LensColors.violet, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          action.label,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
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

class _ContentMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _ContentMessageBubble({required this.message});

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

class _ContentThinkingBubble extends StatelessWidget {
  const _ContentThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 9),
            Text(
              'Reading the open content...',
              style: TextStyle(color: LensColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
