import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/career_document_repository.dart';
import '../../data/repositories.dart';
import '../../data/tone_profile_repository.dart';
import '../core/lens_components.dart';

/// "Add your tone" — the onboarding flow for `app.tone` on the backend.
///
/// Four short writing-sample questions (never a "pick a formality level"
/// slider - see `backend/app/tone/questions.py` for why) become a style
/// reference the agent uses for CV bullets, cover letters, emails, and now
/// its own chat replies. Mirrors the two-state pattern already used by
/// `ResumeProfileScreen`: a guided onboarding view before a tone profile
/// exists, and a summary view with edit/remove afterward.
class ToneScreen extends StatefulWidget {
  const ToneScreen({super.key});

  @override
  State<ToneScreen> createState() => _ToneScreenState();
}

class _ToneScreenState extends State<ToneScreen> {
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ToneProfileRepository>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<ToneProfileRepository>();
    final showOnboarding = _editing || !repository.configured;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Add your tone'),
      ),
      body: SafeArea(
        top: false,
        child: repository.loading && repository.questions.isEmpty
            ? const LensLoading(
                label: 'Bringing your onboarding questions into focus…')
            : repository.questions.isEmpty
                ? LensError(
                    message: repository.error ??
                        'The onboarding questions could not be loaded.',
                    onRetry: () => context.read<ToneProfileRepository>().load(),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: showOnboarding
                        ? _ToneOnboarding(
                            key: const ValueKey('tone-onboarding'),
                            repository: repository,
                            onDone: () {
                              if (mounted) setState(() => _editing = false);
                            },
                          )
                        : _ToneSummary(
                            key: const ValueKey('tone-summary'),
                            repository: repository,
                            onEdit: () => setState(() => _editing = true),
                          ),
                  ),
      ),
    );
  }
}

class _ToneOnboarding extends StatefulWidget {
  final ToneProfileRepository repository;
  final VoidCallback onDone;

  const _ToneOnboarding({
    super.key,
    required this.repository,
    required this.onDone,
  });

  @override
  State<_ToneOnboarding> createState() => _ToneOnboardingState();
}

class _ToneOnboardingState extends State<_ToneOnboarding> {
  final _pages = PageController();
  late final List<TextEditingController> _controllers;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controllers = widget.repository.questions
        .map(
          (question) =>
              TextEditingController(text: widget.repository.answers[question]),
        )
        .toList();
  }

  @override
  void dispose() {
    _pages.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _next() async {
    final isLast = _page == widget.repository.questions.length - 1;
    if (!isLast) {
      await _pages.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    final answers = {
      for (var i = 0; i < widget.repository.questions.length; i++)
        widget.repository.questions[i]: _controllers[i].text,
    };
    final saved = await widget.repository.save(answers);
    if (saved && mounted) {
      context.read<CareerDocumentRepository>().clear();
      context.read<AdvisorRepository>().clearLocal();
      widget.onDone();
    }
  }

  void _back() {
    if (_page == 0) return;
    _pages.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.repository.questions;
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pages,
            onPageChanged: (value) => setState(() => _page = value),
            children: [
              for (var i = 0; i < questions.length; i++)
                _QuestionPage(
                  step: '0${i + 1}',
                  total: questions.length,
                  question: questions[i],
                  controller: _controllers[i],
                ),
            ],
          ),
        ),
        if (widget.repository.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
            child: Text(
              widget.repository.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: LensColors.rose, fontSize: 11.5),
            ),
          ),
        _ToneFooter(
          page: _page,
          totalPages: questions.length,
          saving: widget.repository.saving,
          isLast: _page == questions.length - 1,
          onBack: _page == 0 ? null : _back,
          onNext: _next,
        ),
      ],
    );
  }
}

class _QuestionPage extends StatelessWidget {
  final String step;
  final int total;
  final String question;
  final TextEditingController controller;

  const _QuestionPage({
    required this.step,
    required this.total,
    required this.question,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [LensColors.ink, Color(0xFF3B2A63)],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientPill(
                label: '$step of 0$total · your own words',
                icon: Icons.record_voice_over_outlined,
                dark: true,
              ),
              const SizedBox(height: 16),
              Text(
                question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: controller,
          maxLines: 8,
          minLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Answer naturally, the way you actually write.',
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: LensColors.violet.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_outlined, color: LensColors.violet),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'There are no wrong answers here. CareerLoop matches the '
                  'voice these samples show - sentence length, formality, '
                  'word choice - it never copies these sentences into what '
                  'it writes for you, and this answer can be skipped.',
                  style: TextStyle(fontSize: 11, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToneFooter extends StatelessWidget {
  final int page;
  final int totalPages;
  final bool saving;
  final bool isLast;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const _ToneFooter({
    required this.page,
    required this.totalPages,
    required this.saving,
    required this.isLast,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.paddingOf(context).bottom + 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: LensColors.line)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == page ? 24 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == page ? LensColors.violet : LensColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              if (onBack != null) ...[
                TextButton(
                  onPressed: saving ? null : onBack,
                  child: const Text('Back'),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: LensColors.violet,
                  ),
                  onPressed: saving ? null : onNext,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          isLast
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                  label: Text(isLast ? 'Save my tone' : 'Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToneSummary extends StatelessWidget {
  final ToneProfileRepository repository;
  final VoidCallback onEdit;

  const _ToneSummary({
    super.key,
    required this.repository,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final entries = repository.answers.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 38),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: LensColors.ink,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: LensColors.violet.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      color: LensColors.violet,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TONE CAPTURED',
                          style: TextStyle(
                            color: LensColors.violet,
                            fontSize: 9,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Agent ready',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_rounded, color: LensColors.violet),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '${entries.length} writing sample${entries.length == 1 ? '' : 's'} '
                'saved in your own words.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .72),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LensCard(
          color: LensColors.violet.withValues(alpha: .08),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.hub_outlined, color: LensColors.violet),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where this shows up',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'CV bullets, cover letters, drafted emails, and every '
                      'CareerLoop Copilot chat reply now aim for your voice, '
                      'not a generic one.',
                      style: TextStyle(
                        color: LensColors.muted,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final entry in entries) ...[
          LensCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.value,
                  style: const TextStyle(
                    color: LensColors.muted,
                    height: 1.5,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (repository.error != null) ...[
          Text(
            repository.error!,
            style: const TextStyle(color: LensColors.rose),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit answers'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _confirmRemove(context, repository),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    ToneProfileRepository repository,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove your tone?'),
        content: const Text(
          'Your saved answers will be removed. CareerLoop falls back to a '
          'neutral voice in new agent responses until you add your tone '
          'again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove == true) {
      await repository.remove();
      if (context.mounted) {
        context.read<CareerDocumentRepository>().clear();
        context.read<AdvisorRepository>().clearLocal();
      }
    }
  }
}
