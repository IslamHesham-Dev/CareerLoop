import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/api_client.dart';
import '../../data/career_document_repository.dart';
import '../../data/career_profile_repository.dart';
import '../../data/current_cv_repository.dart';
import '../../data/github_profile_repository.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../data/tone_profile_repository.dart';
import '../career/career_document_viewer_screen.dart';
import '../core/lens_components.dart';

class MasterResumeScreen extends StatefulWidget {
  const MasterResumeScreen({super.key});

  @override
  State<MasterResumeScreen> createState() => _MasterResumeScreenState();
}

class _MasterResumeScreenState extends State<MasterResumeScreen> {
  final _nameController = TextEditingController();
  final _directionController = TextEditingController(
    text: 'Graduate and early-career opportunities',
  );
  bool _initializedName = false;
  bool _adopting = false;

  static final _masterJob = JobOpportunity(
    id: 'careerloop-master-resume',
    company: 'CareerLoop Profile',
    title: 'General graduate opportunities',
    location: '',
    url: Uri(),
    source: 'CareerLoop profile',
    category: 'master resume',
    roleFamily: 'general',
    matchScore: 0,
    matchReasons: const [],
    keywordMatches: const [],
    profileSkillMatches: const [],
    inferredSkillGaps: const [],
    recommendedCourseIds: const [],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicRepository>().loadDashboard();
      _initializeName();
    });
  }

  void _initializeName() {
    if (_initializedName) return;
    final resume = context.read<CurrentCvRepository>().profile?.name;
    final linkedIn = context.read<CareerProfileRepository>().profile?.name;
    final github = context.read<GithubProfileRepository>().profile?.name;
    _nameController.text = [
      resume,
      linkedIn,
      github,
    ].whereType<String>().map((value) => value.trim()).firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => '',
        );
    _initializedName = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _directionController.dispose();
    super.dispose();
  }

  Future<void> _openDocument({bool regenerate = false}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final name = _nameController.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add your full name first.')),
      );
      return;
    }
    final academic = context.read<AcademicRepository>();
    if (academic.fullTranscript == null ||
        academic.fullTranscript!.courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your complete transcript is still loading. Try again shortly.',
          ),
        ),
      );
      return;
    }
    final repository = context.read<CareerDocumentRepository>();
    var document =
        regenerate ? null : repository.documentFor(_masterJob, 'resume');
    document ??= await repository.generate(
      _masterJob,
      'resume',
      instructions:
          'Create a versatile one-page master resume. The candidate confirms '
          'their full name is "$name". Use the complete enrollment-to-latest '
          'academic transcript and every connected verified career source. '
          'Career direction: ${_directionController.text.trim()}. Do not '
          'invent contact details, experience, projects, or achievements.',
    );
    if (document == null || !mounted) return;
    try {
      final file = await repository.download(document);
      if (!mounted) return;
      await context.push(
        '/career-document',
        extra: CareerDocumentViewerArgs(
          job: _masterJob,
          document: document,
          localPath: file.path,
        ),
      );
      if (!mounted) return;
      await _adoptLatestResume();
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exception.message)),
      );
    }
  }

  Future<void> _adoptLatestResume() async {
    final repository = context.read<CareerDocumentRepository>();
    final latest = repository.documentFor(_masterJob, 'resume');
    if (latest == null) return;
    setState(() => _adopting = true);
    try {
      final file = await repository.download(latest);
      if (!mounted) return;
      final imported = await context.read<CurrentCvRepository>().importFile(
            file.path,
            fileName: latest.filename,
          );
      if (!mounted) return;
      if (imported) {
        repository.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Version ${latest.version} is now your active resume evidence.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adopting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicRepository>();
    final documents = context.watch<CareerDocumentRepository>();
    final currentCv = context.watch<CurrentCvRepository>();
    final tone = context.watch<ToneProfileRepository>();
    final transcript = academic.fullTranscript;
    final document = documents.documentFor(_masterJob, 'resume');
    final generating = documents.isBusy(_masterJob, 'resume');
    final transcriptReady = transcript != null && transcript.courses.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Master resume')),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              'Create your master resume',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Build a one-page resume from your academic history and connected profile sources.',
              style: TextStyle(color: LensColors.muted, height: 1.45),
            ),
            const SizedBox(height: 16),
            LensCard(
              child: Column(
                children: [
                  _EvidenceLine(
                    icon: Icons.school_outlined,
                    title: 'Complete transcript',
                    value: transcriptReady
                        ? '${transcript.loadedYears.length} years · ${transcript.courses.length} courses'
                        : 'Loading enrollment history…',
                    ready: transcriptReady,
                  ),
                  const Divider(height: 24),
                  _EvidenceLine(
                    icon: Icons.description_outlined,
                    title: 'Existing resume',
                    value: currentCv.hasProfile
                        ? 'Included as verified evidence'
                        : 'Not required',
                    ready: currentCv.hasProfile,
                    optional: true,
                  ),
                  const Divider(height: 24),
                  _EvidenceLine(
                    icon: Icons.graphic_eq_rounded,
                    title: 'Writing voice',
                    value: tone.configured
                        ? 'Personal style active'
                        : 'Professional default',
                    ready: tone.configured,
                    optional: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            LensCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _directionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Career direction',
                      hintText: 'Example: backend engineering roles in Germany',
                      prefixIcon: Icon(Icons.explore_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: generating || _adopting || !transcriptReady
                          ? null
                          : () => _openDocument(),
                      icon: generating || _adopting
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              document == null
                                  ? Icons.auto_awesome_rounded
                                  : Icons.open_in_new_rounded,
                            ),
                      label: Text(
                        generating
                            ? 'Generating and compiling…'
                            : _adopting
                                ? 'Loading as active resume…'
                                : document == null
                                    ? 'Generate master resume'
                                    : 'Open version ${document.version}',
                      ),
                    ),
                  ),
                  if (document != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: generating || _adopting
                            ? null
                            : () => _openDocument(regenerate: true),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Regenerate from current evidence'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (documents.error != null || currentCv.error != null) ...[
              const SizedBox(height: 12),
              Text(
                documents.error ?? currentCv.error!,
                style: const TextStyle(color: LensColors.rose),
              ),
            ],
            if (academic.fullTranscriptError != null) ...[
              const SizedBox(height: 12),
              Text(
                academic.fullTranscriptError!,
                style: const TextStyle(color: LensColors.rose),
              ),
              TextButton.icon(
                onPressed: academic.loadingDashboard
                    ? null
                    : () => academic.loadDashboard(force: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry complete transcript'),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'After you close the PDF studio, its latest AI-refined version '
              'is automatically saved as your active resume for matching and '
              'email attachments.',
              style: TextStyle(
                color: LensColors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool ready;
  final bool optional;

  const _EvidenceLine({
    required this.icon,
    required this.title,
    required this.value,
    required this.ready,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: LensColors.aqua, size: 21),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: LensColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: LensColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Icon(
          ready
              ? Icons.check_circle_rounded
              : optional
                  ? Icons.remove_circle_outline_rounded
                  : Icons.sync_rounded,
          color: ready ? LensColors.aqua : LensColors.muted,
          size: 18,
        ),
      ],
    );
  }
}
