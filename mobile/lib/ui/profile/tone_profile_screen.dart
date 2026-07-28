import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/career_document_repository.dart';
import '../../data/repositories.dart';
import '../../data/tone_profile_repository.dart';
import '../core/lens_components.dart';

class ToneProfileScreen extends StatefulWidget {
  const ToneProfileScreen({super.key});

  @override
  State<ToneProfileScreen> createState() => _ToneProfileScreenState();
}

class _ToneProfileScreenState extends State<ToneProfileScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repository = context.read<ToneProfileRepository>();
    await repository.load();
    if (!mounted) return;
    for (final question in repository.questions) {
      _controllers.putIfAbsent(
        question,
        () => TextEditingController(text: repository.answers[question] ?? ''),
      );
    }
    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await context.read<ToneProfileRepository>().save(
          _controllers.map(
            (question, controller) => MapEntry(question, controller.text),
          ),
        );
    if (!mounted || !saved) return;
    context.read<CareerDocumentRepository>().clear();
    context.read<AdvisorRepository>().clearLocal();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Writing voice saved. New resumes, letters, and emails will use it.',
        ),
      ),
    );
  }

  Future<void> _remove() async {
    await context.read<ToneProfileRepository>().remove();
    if (!mounted) return;
    context.read<CareerDocumentRepository>().clear();
    context.read<AdvisorRepository>().clearLocal();
    for (final controller in _controllers.values) {
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<ToneProfileRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Writing Voice')),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            const PageHeading(
              eyebrow: 'Personalization layer',
              title: 'Sound like yourself',
              subtitle:
                  'Short writing samples teach CareerLoop your rhythm and formality without reducing your voice to a generic tone label.',
            ),
            const SizedBox(height: 18),
            LensCard(
              color: LensColors.ink,
              child: Row(
                children: [
                  Container(
                    width: 47,
                    height: 47,
                    decoration: BoxDecoration(
                      color: LensColors.violet.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: LensColors.aqua,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repository.configured
                              ? 'Voice profile active'
                              : 'Default professional voice',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          repository.configured
                              ? '${repository.answers.length} writing samples connected'
                              : 'Add at least one sample to personalize generation',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .62),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    repository.configured
                        ? Icons.verified_rounded
                        : Icons.tune_rounded,
                    color: LensColors.aqua,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_initialized || repository.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              for (var index = 0;
                  index < repository.questions.length;
                  index++) ...[
                _ToneQuestion(
                  number: index + 1,
                  question: repository.questions[index],
                  controller: _controllers[repository.questions[index]]!,
                ),
                const SizedBox(height: 11),
              ],
            if (repository.error != null) ...[
              const SizedBox(height: 4),
              Text(
                repository.error!,
                style: const TextStyle(color: LensColors.rose),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: repository.saving || !_initialized ? null : _save,
              icon: repository.saving
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                repository.saving ? 'Saving voice…' : 'Use this writing voice',
              ),
            ),
            if (repository.configured) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: repository.saving ? null : _remove,
                child: const Text('Reset to default professional voice'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToneQuestion extends StatelessWidget {
  final int number;
  final String question;
  final TextEditingController controller;

  const _ToneQuestion({
    required this.number,
    required this.question,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 27,
                height: 27,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LensColors.violet.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: LensColors.violet,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Write naturally—this is a voice sample, not a test.',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}
