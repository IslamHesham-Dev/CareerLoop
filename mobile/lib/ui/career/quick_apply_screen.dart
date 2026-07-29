import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/api_client.dart';
import '../../data/application_models.dart';
import '../../data/application_repository.dart';
import '../../data/career_document_repository.dart';
import '../../data/current_cv_repository.dart';
import '../../data/models.dart';
import '../core/brand_marks.dart';
import '../core/lens_components.dart';
import 'career_document_viewer_screen.dart';

class QuickApplyScreen extends StatefulWidget {
  const QuickApplyScreen({super.key});

  @override
  State<QuickApplyScreen> createState() => _QuickApplyScreenState();
}

class _QuickApplyScreenState extends State<QuickApplyScreen>
    with WidgetsBindingObserver {
  final _linkController = TextEditingController();
  final _postController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subjectController.addListener(_rebuildForDraftEdits);
    _bodyController.addListener(_rebuildForDraftEdits);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicationRepository>().refreshGmailStatus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ApplicationRepository>().refreshGmailStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subjectController.removeListener(_rebuildForDraftEdits);
    _bodyController.removeListener(_rebuildForDraftEdits);
    _linkController.dispose();
    _postController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _rebuildForDraftEdits() {
    if (mounted) setState(() {});
  }

  Future<void> _analyze() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final repository = context.read<ApplicationRepository>();
    final draft = await repository.analyze(
      linkedInPostUrl: _linkController.text,
      postText: _postController.text,
    );
    if (draft == null || !mounted) return;
    _subjectController.text = draft.subject;
    _bodyController.text = draft.body;
  }

  Future<void> _connectGmail({bool reconnect = false}) async {
    final repository = context.read<ApplicationRepository>();
    final uri = await repository.beginGmailConnection(reconnect: reconnect);
    if (uri == null || !mounted) return;
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in could not be opened.')),
      );
    }
  }

  Future<void> _send() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final repository = context.read<ApplicationRepository>();
    final draft = repository.draft;
    if (draft == null) return;
    final job = _jobFromDraft(draft);
    final documentRepository = context.read<CareerDocumentRepository>();
    DownloadedFile? tailoredResume;
    DownloadedFile? tailoredCoverLetter;
    try {
      final resume = documentRepository.documentFor(job, 'resume');
      final coverLetter = documentRepository.documentFor(job, 'cover_letter');
      if (resume != null) {
        tailoredResume = await documentRepository.download(resume);
      }
      if (coverLetter != null) {
        tailoredCoverLetter = await documentRepository.download(coverLetter);
      }
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exception.message)),
      );
      return;
    }
    final result = await repository.send(
      subject: _subjectController.text,
      body: _bodyController.text,
      tailoredResume: tailoredResume,
      tailoredCoverLetter: tailoredCoverLetter,
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application sent through Gmail.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<ApplicationRepository>();
    final cvRepository = context.watch<CurrentCvRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post to Application'),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              'Apply from a LinkedIn post',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _ReadinessCard(
              gmailConnected: repository.gmailConnected,
              gmailAvailable: repository.gmailAvailable,
              gmailEmail: repository.gmailEmail,
              checkingGmail: repository.checkingGmail,
              cvRepository: cvRepository,
              onConnectGmail: () => _connectGmail(
                reconnect: repository.gmailConnected,
              ),
            ),
            const SizedBox(height: 20),
            if (repository.sent != null)
              _SentReceipt(
                repository: repository,
                onStartAnother: () {
                  repository.resetDraft();
                  _linkController.clear();
                  _postController.clear();
                  _subjectController.clear();
                  _bodyController.clear();
                },
              )
            else if (repository.draft == null)
              _PostIntake(
                linkController: _linkController,
                postController: _postController,
                analyzing: repository.analyzing,
                onAnalyze: _analyze,
              )
            else
              _ApplicationReview(
                repository: repository,
                cvRepository: cvRepository,
                subjectController: _subjectController,
                bodyController: _bodyController,
                onSend: _send,
              ),
            if (repository.error != null) ...[
              const SizedBox(height: 14),
              _ErrorNotice(message: repository.error!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  final bool gmailConnected;
  final bool gmailAvailable;
  final String? gmailEmail;
  final bool checkingGmail;
  final CurrentCvRepository cvRepository;
  final VoidCallback onConnectGmail;

  const _ReadinessCard({
    required this.gmailConnected,
    required this.gmailAvailable,
    required this.gmailEmail,
    required this.checkingGmail,
    required this.cvRepository,
    required this.onConnectGmail,
  });

  @override
  Widget build(BuildContext context) {
    final cv = cvRepository.currentCv;
    final ready = gmailConnected && cv != null;
    return LensCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Ready to send?',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (ready) const ReadinessPill(ready: true),
            ],
          ),
          const SizedBox(height: 13),
          _SourceRow(
            icon: SimpleIcons.gmail,
            color: const Color(0xFFEA4335),
            title: gmailConnected
                ? (gmailEmail ?? 'Gmail connected')
                : 'Connect Gmail',
            ready: gmailConnected,
            busy: checkingGmail,
            actionLabel: gmailConnected ? 'Change' : 'Connect',
            onAction: onConnectGmail,
            enabled: gmailConnected || gmailAvailable,
          ),
          const Divider(height: 24),
          _SourceRow(
            icon: Icons.picture_as_pdf_rounded,
            color: LensColors.rose,
            title: cv == null ? 'Add current CV' : cv.fileName,
            ready: cv != null,
            busy: cvRepository.selecting,
            actionLabel: cv == null ? 'Choose PDF' : 'Change',
            onAction: cvRepository.pick,
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final bool ready;
  final bool busy;
  final String actionLabel;
  final VoidCallback onAction;
  final bool enabled;

  const _SourceRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.ready,
    required this.busy,
    required this.actionLabel,
    required this.onAction,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (ready) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.verified_rounded,
                  color: LensColors.aqua,
                  size: 15,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: busy || !enabled ? null : onAction,
          child: busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(actionLabel),
        ),
      ],
    );
  }
}

class _PostIntake extends StatefulWidget {
  final TextEditingController linkController;
  final TextEditingController postController;
  final bool analyzing;
  final VoidCallback onAnalyze;

  const _PostIntake({
    required this.linkController,
    required this.postController,
    required this.analyzing,
    required this.onAnalyze,
  });

  @override
  State<_PostIntake> createState() => _PostIntakeState();
}

class _PostIntakeState extends State<_PostIntake> {
  late String _mode =
      widget.postController.text.trim().isNotEmpty ? 'text' : 'link';

  @override
  Widget build(BuildContext context) {
    return LensCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LinkedInBrandMark(size: 38),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'LinkedIn opportunity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'link',
                label: Text('Post link'),
                icon: Icon(Icons.link_rounded, size: 17),
              ),
              ButtonSegment(
                value: 'text',
                label: Text('Post text'),
                icon: Icon(Icons.notes_rounded, size: 17),
              ),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: (value) => setState(() => _mode = value.first),
          ),
          const SizedBox(height: 16),
          if (_mode == 'link')
            TextField(
              controller: widget.linkController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'LinkedIn post URL',
                hintText: 'https://www.linkedin.com/posts/...',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            )
          else
            TextField(
              controller: widget.postController,
              minLines: 4,
              maxLines: 9,
              decoration: const InputDecoration(
                labelText: 'Post text',
                hintText: 'Paste the full job post text here...',
                alignLabelWithHint: true,
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.analyzing ? null : widget.onAnalyze,
              icon: widget.analyzing
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                widget.analyzing
                    ? 'Preparing application…'
                    : 'Analyze opportunity',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationReview extends StatelessWidget {
  final ApplicationRepository repository;
  final CurrentCvRepository cvRepository;
  final TextEditingController subjectController;
  final TextEditingController bodyController;
  final VoidCallback onSend;

  const _ApplicationReview({
    required this.repository,
    required this.cvRepository,
    required this.subjectController,
    required this.bodyController,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final draft = repository.draft!;
    final job = _jobFromDraft(draft);
    final documents = context.watch<CareerDocumentRepository>();
    final tailoredResume = documents.documentFor(job, 'resume');
    final tailoredCoverLetter = documents.documentFor(job, 'cover_letter');
    final ready = repository.gmailConnected &&
        (cvRepository.hasCv || tailoredResume != null) &&
        subjectController.text.trim().length >= 3 &&
        bodyController.text.trim().length >= 20 &&
        !documents.isBusy(job, 'resume') &&
        !documents.isBusy(job, 'cover_letter');
    return Column(
      children: [
        LensCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: LensColors.indigo.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      color: LensColors.indigo,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Draft ready for review',
                      style: TextStyle(
                        color: LensColors.indigo,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ReadinessPill(ready: ready),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                draft.role,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (draft.company?.isNotEmpty ?? false) ...[
                const SizedBox(height: 5),
                Text(
                  draft.company!,
                  style: TextStyle(color: context.lens.muted),
                ),
              ],
              const SizedBox(height: 16),
              _EnvelopeLine(
                label: 'FROM',
                value: repository.gmailEmail ?? 'Connect Gmail',
              ),
              const SizedBox(height: 8),
              _EnvelopeLine(
                label: 'TO',
                value: draft.recipient,
                locked: true,
              ),
              const SizedBox(height: 8),
              _EnvelopeLine(
                label: 'CV',
                value: tailoredResume?.filename ??
                    cvRepository.currentCv?.fileName ??
                    'Generate or choose a PDF',
              ),
              if (tailoredCoverLetter != null) ...[
                const SizedBox(height: 8),
                _EnvelopeLine(
                  label: 'LETTER',
                  value: tailoredCoverLetter.filename,
                ),
              ],
            ],
          ),
        ),
        if (draft.warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final warning in draft.warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _Notice(
                icon: Icons.info_outline_rounded,
                message: warning,
              ),
            ),
        ],
        const SizedBox(height: 12),
        _QuickApplyDocumentStudio(
          job: job,
          repository: documents,
        ),
        const SizedBox(height: 12),
        LensCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Review the email',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: repository.resetDraft,
                    child: const Text('Start over'),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              TextField(
                controller: subjectController,
                maxLength: 180,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyController,
                minLines: 9,
                maxLines: 16,
                maxLength: 5000,
                decoration: const InputDecoration(
                  labelText: 'Email body',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              const _Notice(
                icon: Icons.lock_outline_rounded,
                message:
                    'Prototype safety: the test inbox is enforced by the backend. Any email found in the post is shown as evidence only.',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: ready && !repository.sending ? onSend : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: LensColors.aqua,
                    foregroundColor: context.lens.ink,
                  ),
                  icon: repository.sending
                      ? SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.lens.ink,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    repository.sending
                        ? 'Sending through Gmail…'
                        : 'Approve & send application',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickApplyDocumentStudio extends StatelessWidget {
  final JobOpportunity job;
  final CareerDocumentRepository repository;

  const _QuickApplyDocumentStudio({
    required this.job,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final resume = repository.documentFor(job, 'resume');
    final coverLetter = repository.documentFor(job, 'cover_letter');
    return LensCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: LensColors.indigo),
              SizedBox(width: 9),
              Text(
                'Application documents',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Generate or open the tailored files that will be attached after approval.',
            style: TextStyle(
              color: context.lens.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _QuickApplyDocumentAction(
            icon: Icons.description_outlined,
            title: 'Tailored resume',
            subtitle: resume == null
                ? 'Build for ${job.title}'
                : 'Version ${resume.version} · ready to attach',
            ready: resume != null,
            loading: repository.isBusy(job, 'resume'),
            onTap: () => _open(
              context,
              kind: 'resume',
              document: resume,
            ),
          ),
          const SizedBox(height: 9),
          _QuickApplyDocumentAction(
            icon: Icons.mail_outline_rounded,
            title: 'Tailored cover letter',
            subtitle: coverLetter == null
                ? 'Build for ${job.company}'
                : 'Version ${coverLetter.version} · ready to attach',
            ready: coverLetter != null,
            loading: repository.isBusy(job, 'cover_letter'),
            onTap: () => _open(
              context,
              kind: 'cover_letter',
              document: coverLetter,
            ),
          ),
          if (repository.error != null) ...[
            const SizedBox(height: 10),
            Text(
              repository.error!,
              style: const TextStyle(
                color: LensColors.rose,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _open(
    BuildContext context, {
    required String kind,
    required CareerDocument? document,
  }) async {
    var active = document ?? await repository.generate(job, kind);
    if (active == null || !context.mounted) return;
    try {
      final file = await repository.download(active);
      if (!context.mounted) return;
      await context.push(
        '/career-document',
        extra: CareerDocumentViewerArgs(
          job: job,
          document: active,
          localPath: file.path,
        ),
      );
    } on ApiException catch (exception) {
      if (exception.statusCode == 404 && document != null) {
        active = await repository.generate(job, kind);
        if (active == null || !context.mounted) return;
        final file = await repository.download(active);
        if (!context.mounted) return;
        await context.push(
          '/career-document',
          extra: CareerDocumentViewerArgs(
            job: job,
            document: active,
            localPath: file.path,
          ),
        );
        return;
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exception.message)),
      );
    }
  }
}

class _QuickApplyDocumentAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool ready;
  final bool loading;
  final VoidCallback onTap;

  const _QuickApplyDocumentAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ready,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.lens.canvas,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: ready
                      ? LensColors.aqua.withValues(alpha: .14)
                      : LensColors.indigo.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          color: LensColors.aqua,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        ready ? Icons.verified_rounded : icon,
                        color: ready ? LensColors.aqua : LensColors.indigo,
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
                      style: TextStyle(
                        color: context.lens.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      loading ? 'Generating and compiling PDF…' : subtitle,
                      style: TextStyle(
                        color: context.lens.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                ready ? Icons.open_in_new_rounded : Icons.add_rounded,
                color: LensColors.indigo,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnvelopeLine extends StatelessWidget {
  final String label;
  final String value;
  final bool locked;

  const _EnvelopeLine({
    required this.label,
    required this.value,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 43,
          child: Text(
            label,
            style: TextStyle(
              color: context.lens.muted,
              fontSize: 11,
              letterSpacing: .8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: context.lens.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (locked)
          Icon(Icons.lock_rounded, color: context.lens.muted, size: 14),
      ],
    );
  }
}

class _SentReceipt extends StatelessWidget {
  final ApplicationRepository repository;
  final VoidCallback onStartAnother;

  const _SentReceipt({
    required this.repository,
    required this.onStartAnother,
  });

  @override
  Widget build(BuildContext context) {
    final result = repository.sent!;
    return LensCard(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: LensColors.aqua.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: LensColors.aqua,
              size: 31,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            'Application sent',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 7),
          Text(
            '${result.sender} → ${result.recipient}',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.lens.muted),
          ),
          const SizedBox(height: 17),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.lens.canvas,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.subject,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.attachmentNames.join(' + ')} · '
                  'Gmail message ${result.messageId}',
                  style: TextStyle(
                    color: context.lens.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onStartAnother,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Prepare another application'),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 7,
            children: [
              Chip(
                avatar: Icon(SimpleIcons.gmail, size: 14),
                label: Text('Gmail Sender'),
              ),
              Chip(
                avatar: Icon(Icons.auto_awesome_rounded, size: 14),
                label: Text('Application Drafting'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String message;

  const _Notice({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LensColors.indigo.withValues(alpha: .065),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: LensColors.indigo, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  final String message;

  const _ErrorNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LensColors.rose.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: LensColors.rose),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

JobOpportunity _jobFromDraft(ApplicationDraft draft) {
  return JobOpportunity(
    id: 'linkedin-application-${draft.id}',
    company: (draft.company?.trim().isNotEmpty ?? false)
        ? draft.company!.trim()
        : 'LinkedIn opportunity',
    title: draft.role,
    location: 'Location not specified',
    url: Uri.parse(draft.linkedInPostUrl),
    source: 'LinkedIn post',
    category: draft.contentSource,
    roleFamily: 'general',
    matchScore: 0,
    matchReasons: [
      'LinkedIn post context: ${draft.postExcerpt}',
    ],
    keywordMatches: const [],
    profileSkillMatches: const [],
    inferredSkillGaps: const [],
    recommendedCourseIds: const [],
  );
}
