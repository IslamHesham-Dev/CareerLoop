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

  const ContentAiOverlay({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    required this.contextInstruction,
    required this.quickActions,
    this.controller,
    this.onSend,
  });

  @override
  State<ContentAiOverlay> createState() => _ContentAiOverlayState();
}

class _ContentAiOverlayState extends State<ContentAiOverlay> {
  static const _bubbleSize = 58.0;
  final _controller = TextEditingController();
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
                  controller: _controller,
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
                ),
              )
            else
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
                      elevation: 12,
                      shadowColor: LensColors.indigo.withValues(alpha: .4),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => setState(() => _expanded = true),
                        child: Ink(
                          width: _bubbleSize,
                          height: _bubbleSize,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [LensColors.indigo, LensColors.violet],
                            ),
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

    final advisor = context.read<AdvisorRepository>();
    ChatMessage? response;
    try {
      if (widget.onSend != null) {
        response = await widget.onSend!(trimmed);
      } else {
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
            ? advisor.error ?? 'The assistant could not respond right now.'
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(prompt));
    }
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
  final TextEditingController controller;
  final ScrollController scrollController;
  final ChatMessage? messageToReveal;
  final GlobalKey? messageToRevealKey;
  final bool sending;
  final String? error;
  final VoidCallback onMinimize;
  final ValueChanged<String> onPrompt;

  const _ChatPanel({
    required this.title,
    required this.subtitle,
    required this.messages,
    required this.quickActions,
    required this.controller,
    required this.scrollController,
    required this.messageToReveal,
    required this.messageToRevealKey,
    required this.sending,
    required this.error,
    required this.onMinimize,
    required this.onPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return ColoredBox(
      color: Colors.black.withValues(alpha: .26),
      child: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            widthFactor: 1,
            heightFactor: .78,
            child: Material(
              elevation: 22,
              color: const Color(0xFFF8F9FD),
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
                            gradient: const LinearGradient(
                              colors: [LensColors.indigo, LensColors.violet],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
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
                                  fontSize: 10.5,
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
                            onPrompt: onPrompt,
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: LensColors.line)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            minLines: 1,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Ask about what you are viewing...',
                              isDense: true,
                              suffixIcon: keyboardVisible
                                  ? IconButton(
                                      tooltip: 'Hide keyboard',
                                      onPressed: () => FocusManager
                                          .instance.primaryFocus
                                          ?.unfocus(),
                                      icon: const Icon(
                                        Icons.keyboard_hide_rounded,
                                      ),
                                    )
                                  : null,
                            ),
                            onSubmitted: onPrompt,
                            onTapOutside: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Quick prompts',
                          enabled: !sending,
                          icon: const Icon(Icons.bolt_rounded),
                          onSelected: onPrompt,
                          itemBuilder: (context) => quickActions
                              .map(
                                (action) => PopupMenuItem(
                                  value: action.prompt,
                                  child: Row(
                                    children: [
                                      Icon(action.icon, size: 18),
                                      const SizedBox(width: 9),
                                      Flexible(child: Text(action.label)),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Send',
                          onPressed:
                              sending ? null : () => onPrompt(controller.text),
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
                      ],
                    ),
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

class _ChatWelcome extends StatelessWidget {
  final List<ContentAiQuickAction> quickActions;
  final ValueChanged<String> onPrompt;

  const _ChatWelcome({
    required this.quickActions,
    required this.onPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      children: [
        const Text(
          'Ask without leaving the content',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        const Text(
          'Choose a starting action or ask your own question. The response is grounded in the open content.',
          style: TextStyle(color: LensColors.muted, height: 1.4),
        ),
        const SizedBox(height: 20),
        ...quickActions.map(
          (action) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                onTap: () => onPrompt(action.prompt),
                borderRadius: BorderRadius.circular(17),
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
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        margin: EdgeInsets.only(
          left: message.isUser ? 42 : 0,
          right: message.isUser ? 0 : 18,
          bottom: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: message.isUser
              ? const LinearGradient(
                  colors: [LensColors.indigo, LensColors.violet],
                )
              : null,
          color: message.isUser ? null : Colors.white,
          border: message.isUser ? null : Border.all(color: LensColors.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: message.isUser
            ? Text(
                message.text,
                style: const TextStyle(color: Colors.white, height: 1.35),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: message.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        color: LensColors.ink,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      listBullet: const TextStyle(color: LensColors.indigo),
                      tableBorder: TableBorder.all(color: LensColors.line),
                      tableCellsPadding: const EdgeInsets.all(6),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: NotionExportAction(
                      message: message,
                      compact: true,
                    ),
                  ),
                  if (message.practiceSet != null) ...[
                    const SizedBox(height: 10),
                    PracticeLaunchCard(practiceSet: message.practiceSet!),
                  ],
                  const SizedBox(height: 11),
                  CapabilityFooter(
                    tools: message.tools,
                    sources: message.sources,
                    compact: true,
                  ),
                ],
              ),
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
