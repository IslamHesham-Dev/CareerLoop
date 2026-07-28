import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/application_repository.dart';
import '../../data/current_cv_repository.dart';
import '../core/brand_marks.dart';
import '../core/lens_components.dart';

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
    final result = await repository.send(
      subject: _subjectController.text,
      body: _bodyController.text,
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
            const PageHeading(
              eyebrow: 'Human-approved action',
              title: 'Turn a post into an application',
              subtitle:
                  'CareerLoop reads the opportunity, drafts the email, and pauses for your approval before Gmail sends anything.',
            ),
            const SizedBox(height: 20),
            const _Pipeline(),
            const SizedBox(height: 20),
            _ReadinessCard(
              gmailConnected: repository.gmailConnected,
              gmailAvailable: repository.gmailAvailable,
              gmailEmail: repository.gmailEmail,
              configurationMessage: repository.configurationMessage,
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

class _Pipeline extends StatelessWidget {
  const _Pipeline();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.work_outline_rounded, 'Post'),
      (Icons.auto_awesome_rounded, 'Draft'),
      (Icons.fact_check_outlined, 'Review'),
      (SimpleIcons.gmail, 'Send'),
    ];
    return LensCard(
      color: LensColors.ink,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
      child: Row(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Expanded(
              child: Column(
                children: [
                  Icon(steps[index].$1, color: LensColors.aqua, size: 19),
                  const SizedBox(height: 7),
                  Text(
                    steps[index].$2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (index < steps.length - 1)
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: .25),
                size: 17,
              ),
          ],
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  final bool gmailConnected;
  final bool gmailAvailable;
  final String? gmailEmail;
  final String? configurationMessage;
  final bool checkingGmail;
  final CurrentCvRepository cvRepository;
  final VoidCallback onConnectGmail;

  const _ReadinessCard({
    required this.gmailConnected,
    required this.gmailAvailable,
    required this.gmailEmail,
    required this.configurationMessage,
    required this.checkingGmail,
    required this.cvRepository,
    required this.onConnectGmail,
  });

  @override
  Widget build(BuildContext context) {
    final cv = cvRepository.currentCv;
    return LensCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SEND READINESS',
            style: TextStyle(
              color: LensColors.indigo,
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 13),
          _SourceRow(
            icon: SimpleIcons.gmail,
            color: const Color(0xFFEA4335),
            title: gmailConnected ? 'Gmail connected' : 'Connect Gmail',
            subtitle: gmailConnected
                ? (gmailEmail ?? 'Send-only access granted')
                : (configurationMessage ??
                    'CareerLoop requests send-only permission'),
            ready: gmailConnected,
            busy: checkingGmail,
            actionLabel: gmailConnected ? 'Change' : 'Connect',
            onAction: onConnectGmail,
            enabled: gmailConnected || gmailAvailable,
          ),
          if (!gmailConnected && gmailAvailable) ...[
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: LensColors.amber.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    color: LensColors.amber,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OAuth testing: this Gmail address must be added under '
                      'Google Auth Platform → Audience → Test users.',
                      style: TextStyle(fontSize: 9.5, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 24),
          _SourceRow(
            icon: Icons.picture_as_pdf_rounded,
            color: LensColors.rose,
            title: cv == null ? 'Add current CV' : cv.fileName,
            subtitle: cv == null
                ? 'Stored privately on this device'
                : '${(cv.sizeBytes / 1024).round()} KB · attached only when you approve',
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
  final String subtitle;
  final bool ready;
  final bool busy;
  final String actionLabel;
  final VoidCallback onAction;
  final bool enabled;

  const _SourceRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LensColors.muted,
                  fontSize: 10.5,
                ),
              ),
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

class _PostIntake extends StatelessWidget {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LinkedIn opportunity',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text(
                      'Paste a public post link',
                      style: TextStyle(
                        color: LensColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: linkController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'LinkedIn post URL',
              hintText: 'https://www.linkedin.com/posts/...',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            controller: postController,
            minLines: 4,
            maxLines: 9,
            decoration: const InputDecoration(
              labelText: 'Post text · optional fallback',
              hintText:
                  'Paste the job post here when LinkedIn hides its public preview...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 11),
          const Text(
            'LinkedIn often restricts post content. CareerLoop first checks public preview metadata and asks for pasted text only when needed.',
            style: TextStyle(
              color: LensColors.muted,
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: analyzing ? null : onAnalyze,
              icon: analyzing
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                analyzing ? 'Preparing application…' : 'Analyze opportunity',
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
    final ready = repository.gmailConnected &&
        cvRepository.hasCv &&
        subjectController.text.trim().length >= 3 &&
        bodyController.text.trim().length >= 20;
    return Column(
      children: [
        LensCard(
          color: LensColors.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GradientPill(
                label: 'AI proposal · awaiting approval',
                icon: Icons.pause_circle_outline_rounded,
                dark: true,
              ),
              const SizedBox(height: 15),
              Text(
                draft.role,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (draft.company?.isNotEmpty ?? false) ...[
                const SizedBox(height: 5),
                Text(
                  draft.company!,
                  style: const TextStyle(color: Colors.white70),
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
                value: cvRepository.currentCv?.fileName ?? 'Choose a PDF',
              ),
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
                    foregroundColor: LensColors.ink,
                  ),
                  icon: repository.sending
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: LensColors.ink,
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
            style: const TextStyle(
              color: LensColors.aqua,
              fontSize: 9,
              letterSpacing: .8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (locked)
          const Icon(Icons.lock_rounded, color: Colors.white38, size: 14),
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
            style: const TextStyle(color: LensColors.muted),
          ),
          const SizedBox(height: 17),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LensColors.canvas,
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
                  '${result.attachmentName} · Gmail message ${result.messageId}',
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 10.5,
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
              style: const TextStyle(fontSize: 10.5, height: 1.4),
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
