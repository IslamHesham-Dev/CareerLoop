import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/practice_repository.dart';
import '../core/content_ai_overlay.dart';
import '../core/lens_components.dart';

class PracticeLibraryScreen extends StatelessWidget {
  const PracticeLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sets = context.watch<PracticeRepository>().sets;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice library'),
      ),
      body: AuroraBackground(
        child: sets.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.style_outlined,
                        size: 50,
                        color: LensColors.violet,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Your practice sets will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ask CareerLoop to prepare you for a quiz, midterm, or final.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: LensColors.muted),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
                itemCount: sets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 11),
                itemBuilder: (context, index) {
                  final set = sets[index];
                  return Dismissible(
                    key: ValueKey(set.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: LensColors.rose,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child:
                          const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) =>
                        context.read<PracticeRepository>().remove(set.id),
                    child: LensCard(
                      onTap: () =>
                          context.push('/practice/session', extra: set),
                      padding: const EdgeInsets.all(17),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  LensColors.indigo,
                                  LensColors.violet,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.quiz_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  set.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${set.questions.length} MCQs · '
                                  '${DateFormat.MMMd().format(set.createdAt)}',
                                  style: const TextStyle(
                                    color: LensColors.muted,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: LensColors.indigo,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class PracticeSessionScreen extends StatefulWidget {
  final PracticeSet practiceSet;

  const PracticeSessionScreen({
    super.key,
    required this.practiceSet,
  });

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  final _assistController = ContentAiOverlayController();
  final Map<int, int> _answers = {};
  int _index = 0;
  bool _finished = false;

  PracticeQuestion get _question => widget.practiceSet.questions[_index];
  int? get _selected => _answers[_index];
  bool get _answered => _selected != null;

  @override
  Widget build(BuildContext context) {
    final question = _question;
    final selected = _selected;
    final correct = selected == question.correctIndex;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.practiceSet.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.practiceSet.course,
              style: const TextStyle(
                color: LensColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Practice library',
            onPressed: () => context.push('/practice'),
            icon: const Icon(Icons.collections_bookmark_outlined),
          ),
        ],
      ),
      body: ContentAiOverlay(
        controller: _assistController,
        title: 'Question Assist',
        subtitle: question.concept,
        contextInstruction: _questionContext(question, selected),
        quickActions: [
          ContentAiQuickAction(
            icon: Icons.psychology_alt_outlined,
            label: _answered
                ? 'Explain the reasoning'
                : 'Explain what the question asks',
            prompt: _answered
                ? 'Explain the reasoning for this question and why my selected '
                    'answer was ${correct ? 'correct' : 'wrong'}.'
                : 'Explain what this question is testing and how to reason '
                    'about it. Do not reveal or identify the correct option.',
          ),
          const ContentAiQuickAction(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Give me a hint',
            prompt: 'Give me one conceptual hint without revealing or '
                'eliminating options or identifying the correct answer.',
          ),
        ],
        child: _finished
            ? _CompletionView(
                score: _score,
                total: widget.practiceSet.questions.length,
                onRestart: _restart,
                onLibrary: () => context.go('/practice'),
              )
            : _QuestionView(
                index: _index,
                total: widget.practiceSet.questions.length,
                question: question,
                selected: selected,
                onSelect: (option) => setState(() {
                  if (!_answered) _answers[_index] = option;
                }),
                onExplainQuestion: () => _assistController.open(
                  prompt: 'Explain what this question is testing and how to '
                      'approach it. Do not reveal, eliminate, or identify the '
                      'correct answer.',
                ),
                onExplainWrong: () => _assistController.open(
                  prompt: 'I selected "${question.options[selected!]}", but '
                      'the correct answer is '
                      '"${question.options[question.correctIndex]}". Explain '
                      'the misconception and the correct reasoning clearly.',
                ),
                onNext: _next,
              ),
      ),
    );
  }

  int get _score => _answers.entries
      .where(
        (entry) =>
            widget.practiceSet.questions[entry.key].correctIndex == entry.value,
      )
      .length;

  String _questionContext(PracticeQuestion question, int? selected) {
    final options = question.options
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('\n');
    if (selected == null) {
      return 'Coach the student on this MCQ:\n${question.question}\n$options\n'
          'The student has not answered. Never reveal, name, quote, eliminate, '
          'or indirectly identify the correct option. Explain the underlying '
          'concept or reasoning process only.';
    }
    return 'Coach the student on this answered MCQ:\n${question.question}\n'
        '$options\nThey selected: ${question.options[selected]}.\n'
        'Correct answer: ${question.options[question.correctIndex]}.\n'
        'Ground truth explanation: ${question.explanation}\n'
        'You may now explain the result and correct any misconception.';
  }

  void _next() {
    if (!_answered) return;
    if (_index == widget.practiceSet.questions.length - 1) {
      setState(() => _finished = true);
    } else {
      setState(() => _index++);
    }
  }

  void _restart() {
    setState(() {
      _answers.clear();
      _index = 0;
      _finished = false;
    });
  }
}

class _QuestionView extends StatelessWidget {
  final int index;
  final int total;
  final PracticeQuestion question;
  final int? selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onExplainQuestion;
  final VoidCallback onExplainWrong;
  final VoidCallback onNext;

  const _QuestionView({
    required this.index,
    required this.total,
    required this.question,
    required this.selected,
    required this.onSelect,
    required this.onExplainQuestion,
    required this.onExplainWrong,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final answered = selected != null;
    final correct = selected == question.correctIndex;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (index + 1) / total,
                    minHeight: 7,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${index + 1}/$total',
                style: const TextStyle(
                  color: LensColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            question.concept.toUpperCase(),
            style: const TextStyle(
              color: LensColors.violet,
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 21,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (!answered)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onExplainQuestion,
                icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                label: const Text('Explain the question — no answer'),
              ),
            ),
          const SizedBox(height: 8),
          ...question.options.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OptionTile(
                    index: entry.key,
                    text: entry.value,
                    selected: selected,
                    correctIndex: question.correctIndex,
                    onTap: () => onSelect(entry.key),
                  ),
                ),
              ),
          if (answered) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (correct ? LensColors.aqua : LensColors.rose)
                    .withValues(alpha: .09),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    correct ? 'Correct' : 'Not quite',
                    style: TextStyle(
                      color: correct ? LensColors.aqua : LensColors.rose,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (!correct) ...[
                    const SizedBox(height: 7),
                    Text(
                      question.explanation,
                      style: const TextStyle(height: 1.4),
                    ),
                    const SizedBox(height: 7),
                    TextButton.icon(
                      onPressed: onExplainWrong,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                      label: const Text('Explain why'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onNext,
              child: Text(index == total - 1 ? 'See results' : 'Next question'),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final int index;
  final String text;
  final int? selected;
  final int correctIndex;
  final VoidCallback onTap;

  const _OptionTile({
    required this.index,
    required this.text,
    required this.selected,
    required this.correctIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final answered = selected != null;
    final isSelected = selected == index;
    final isCorrect = answered && correctIndex == index;
    final color = isCorrect
        ? LensColors.aqua
        : isSelected && answered
            ? LensColors.rose
            : LensColors.indigo;
    return Material(
      color:
          isCorrect || isSelected ? color.withValues(alpha: .08) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: answered ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(
              color: isCorrect || isSelected ? color : LensColors.line,
              width: isCorrect || isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 31,
                height: 31,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .09),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (isCorrect)
                const Icon(Icons.check_circle_rounded, color: LensColors.aqua)
              else if (isSelected && answered)
                const Icon(Icons.cancel_rounded, color: LensColors.rose),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onRestart;
  final VoidCallback onLibrary;

  const _CompletionView({
    required this.score,
    required this.total,
    required this.onRestart,
    required this.onLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0 : (score / total * 100).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: LensCard(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: LensColors.violet,
                size: 54,
              ),
              const SizedBox(height: 14),
              const Text(
                'Session complete',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                '$score of $total correct · $percentage%',
                style: const TextStyle(color: LensColors.muted),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onRestart,
                  child: const Text('Practice again'),
                ),
              ),
              TextButton(
                onPressed: onLibrary,
                child: const Text('Back to practice library'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
