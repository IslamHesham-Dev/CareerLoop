import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/application_repository.dart';
import '../../data/career_profile_repository.dart';
import '../../data/current_cv_repository.dart';
import '../../data/email_repository.dart';
import '../../data/models.dart';
import '../../data/github_profile_repository.dart';
import '../../data/tone_profile_repository.dart';
import '../core/capability_footer.dart';
import '../core/lens_components.dart';

class EmailStudioScreen extends StatefulWidget {
  const EmailStudioScreen({super.key});

  @override
  State<EmailStudioScreen> createState() => _EmailStudioScreenState();
}

class _EmailStudioScreenState extends State<EmailStudioScreen>
    with WidgetsBindingObserver {
  final _recipientController = TextEditingController();
  final _nameController = TextEditingController();
  final _purposeController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _attachResume = false;

  static const _purposes = [
    'Ask a professor for a recommendation letter',
    'Request an appointment with an academic advisor',
    'Ask a lecturer about a course or grade',
    'Follow up on an internship or job application',
    'Introduce myself to a recruiter',
    'Send a professional thank-you note',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subjectController.addListener(_refresh);
    _bodyController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicationRepository>().refreshGmailStatus();
      _initializeName();
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
    _subjectController.removeListener(_refresh);
    _bodyController.removeListener(_refresh);
    _recipientController.dispose();
    _nameController.dispose();
    _purposeController.dispose();
    _instructionsController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _initializeName() {
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
    _refresh();
  }

  Future<void> _connectGmail() async {
    final gmail = context.read<ApplicationRepository>();
    final uri = await gmail.beginGmailConnection(
      reconnect: gmail.gmailConnected,
    );
    if (uri == null || !mounted) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in could not be opened.')),
      );
    }
  }

  Future<void> _preview() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await context.read<EmailRepository>().preview(
          recipientEmail: _recipientController.text,
          senderName: _nameController.text,
          purpose: _purposeController.text,
          customInput: _instructionsController.text,
        );
    if (result == null || !mounted) return;
    _subjectController.text = result.subject;
    _bodyController.text = result.body;
  }

  Future<void> _send() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await context.read<EmailRepository>().send(
          subject: _subjectController.text,
          body: _bodyController.text,
          attachResume: _attachResume,
        );
    if (result == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Email sent to ${result.recipient}.')),
    );
  }

  void _reset() {
    context.read<EmailRepository>().reset();
    _recipientController.clear();
    _nameController.clear();
    _purposeController.clear();
    _instructionsController.clear();
    _subjectController.clear();
    _bodyController.clear();
    setState(() => _attachResume = false);
    _initializeName();
  }

  @override
  Widget build(BuildContext context) {
    final emails = context.watch<EmailRepository>();
    final gmail = context.watch<ApplicationRepository>();
    final cv = context.watch<CurrentCvRepository>();
    final tone = context.watch<ToneProfileRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Write email')),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              'Draft a contextual email',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'CareerLoop prepares the message. You review it before Gmail sends anything.',
              style: TextStyle(color: context.lens.muted, height: 1.45),
            ),
            const SizedBox(height: 16),
            _EmailReadiness(
              gmail: gmail,
              cv: cv,
              tone: tone,
              onConnect: _connectGmail,
            ),
            const SizedBox(height: 14),
            if (emails.sent != null)
              _SentEmailReceipt(
                repository: emails,
                onAnother: _reset,
              )
            else if (emails.draft == null)
              _EmailIntake(
                recipientController: _recipientController,
                nameController: _nameController,
                purposeController: _purposeController,
                instructionsController: _instructionsController,
                purposes: _purposes,
                drafting: emails.drafting,
                onChanged: _refresh,
                onPreview: _preview,
              )
            else
              _EmailReview(
                repository: emails,
                gmailConnected: gmail.gmailConnected,
                hasResume: cv.hasCv,
                attachResume: _attachResume,
                onAttachChanged: (value) =>
                    setState(() => _attachResume = value),
                subjectController: _subjectController,
                bodyController: _bodyController,
                onSend: _send,
                onStartOver: _reset,
              ),
            if (emails.error != null) ...[
              const SizedBox(height: 12),
              Text(
                emails.error!,
                style: const TextStyle(color: LensColors.rose),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmailReadiness extends StatelessWidget {
  final ApplicationRepository gmail;
  final CurrentCvRepository cv;
  final ToneProfileRepository tone;
  final VoidCallback onConnect;

  const _EmailReadiness({
    required this.gmail,
    required this.cv,
    required this.tone,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Before you send',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ReadinessPill(ready: gmail.gmailConnected),
            ],
          ),
          const SizedBox(height: 13),
          _ReadyRow(
            icon: SimpleIcons.gmail,
            title: gmail.gmailConnected
                ? gmail.gmailEmail ?? 'Gmail connected'
                : 'Connect Gmail',
            ready: gmail.gmailConnected,
            action: onConnect,
            actionLabel: gmail.gmailConnected ? 'Change' : 'Connect',
          ),
          const Divider(height: 23),
          _ReadyRow(
            icon: Icons.graphic_eq_rounded,
            title: tone.configured
                ? 'Personal writing voice'
                : 'Professional default voice',
            detail: 'Applied while drafting',
            ready: tone.configured,
          ),
          const Divider(height: 23),
          _ReadyRow(
            icon: Icons.description_outlined,
            title: cv.hasCv ? cv.currentCv!.fileName : 'No resume selected',
            detail: 'Optional attachment',
            ready: cv.hasCv,
          ),
        ],
      ),
    );
  }
}

class _ReadyRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? detail;
  final bool ready;
  final VoidCallback? action;
  final String? actionLabel;

  const _ReadyRow({
    required this.icon,
    required this.title,
    this.detail,
    required this.ready,
    this.action,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: LensColors.indigo, size: 20),
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
                  color: context.lens.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (detail != null)
                Text(
                  detail!,
                  style: const TextStyle(
                    color: context.lens.muted,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: action,
            child: Text(actionLabel ?? 'Open'),
          )
        else
          Icon(
            ready
                ? Icons.check_circle_rounded
                : Icons.remove_circle_outline_rounded,
            color: ready ? LensColors.aqua : context.lens.muted,
            size: 18,
          ),
      ],
    );
  }
}

class _EmailIntake extends StatelessWidget {
  final TextEditingController recipientController;
  final TextEditingController nameController;
  final TextEditingController purposeController;
  final TextEditingController instructionsController;
  final List<String> purposes;
  final bool drafting;
  final VoidCallback onChanged;
  final VoidCallback onPreview;

  const _EmailIntake({
    required this.recipientController,
    required this.nameController,
    required this.purposeController,
    required this.instructionsController,
    required this.purposes,
    required this.drafting,
    required this.onChanged,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final canDraft = recipientController.text.trim().contains('@') &&
        nameController.text.trim().length >= 2 &&
        purposeController.text.trim().length >= 5;
    return LensCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who are you writing to?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 13),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Your full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: recipientController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Recipient email',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Common purposes',
            style: TextStyle(
              color: context.lens.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: purposes
                .map(
                  (purpose) => ActionChip(
                    avatar: const Icon(Icons.bolt_rounded, size: 15),
                    label: Text(purpose),
                    onPressed: () {
                      purposeController.text = purpose;
                      onChanged();
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: purposeController,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Purpose and context',
              hintText:
                  'Explain what you need, relevant dates, and the outcome you want.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: instructionsController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Additional constraints · optional',
              hintText: 'Example: polite, concise, mention Thursday’s deadline',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: drafting || !canDraft ? null : onPreview,
              icon: drafting
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(drafting ? 'Drafting with context…' : 'Create draft'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailReview extends StatelessWidget {
  final EmailRepository repository;
  final bool gmailConnected;
  final bool hasResume;
  final bool attachResume;
  final ValueChanged<bool> onAttachChanged;
  final TextEditingController subjectController;
  final TextEditingController bodyController;
  final VoidCallback onSend;
  final VoidCallback onStartOver;

  const _EmailReview({
    required this.repository,
    required this.gmailConnected,
    required this.hasResume,
    required this.attachResume,
    required this.onAttachChanged,
    required this.subjectController,
    required this.bodyController,
    required this.onSend,
    required this.onStartOver,
  });

  @override
  Widget build(BuildContext context) {
    final draft = repository.draft!;
    final ready = gmailConnected &&
        subjectController.text.trim().length >= 3 &&
        bodyController.text.trim().length >= 20;
    return LensCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LensColors.indigo.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: LensColors.indigo,
                  size: 15,
                ),
              ),
              const SizedBox(width: 9),
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onStartOver,
              child: const Text('Start over'),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            draft.recipientEmail,
            style: const TextStyle(
              color: LensColors.indigo,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: subjectController,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: bodyController,
            minLines: 9,
            maxLines: 18,
            maxLength: 5000,
            decoration: const InputDecoration(
              labelText: 'Email body',
              alignLabelWithHint: true,
            ),
          ),
          if (hasResume)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: attachResume,
              onChanged: onAttachChanged,
              title: const Text(
                'Attach active resume',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Useful for recruiter and recommendation requests',
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: ready && !repository.sending ? onSend : null,
              style: FilledButton.styleFrom(
                backgroundColor: LensColors.aqua,
                foregroundColor: context.lens.ink,
              ),
              icon: repository.sending
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(SimpleIcons.gmail),
              label: Text(
                repository.sending
                    ? 'Sending through Gmail…'
                    : 'Approve & send email',
              ),
            ),
          ),
          const SizedBox(height: 14),
          CapabilityFooter(
            tools: const [
              ToolActivity(name: 'Email drafting', status: 'completed'),
              ToolActivity(name: 'Human approval gate', status: 'completed'),
            ],
            sources: draft.sourcesUsed,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _SentEmailReceipt extends StatelessWidget {
  final EmailRepository repository;
  final VoidCallback onAnother;

  const _SentEmailReceipt({
    required this.repository,
    required this.onAnother,
  });

  @override
  Widget build(BuildContext context) {
    final result = repository.sent!;
    return LensCard(
      child: Column(
        children: [
          const Icon(
            Icons.mark_email_read_rounded,
            color: LensColors.aqua,
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            'Email sent',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Text(
            '${result.sender} → ${result.recipient}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: context.lens.muted),
          ),
          if (result.attachmentName != null) ...[
            const SizedBox(height: 7),
            Text(
              '${result.attachmentName} attached',
              style: const TextStyle(
                color: LensColors.indigo,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 17),
          OutlinedButton.icon(
            onPressed: onAnother,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Write another email'),
          ),
        ],
      ),
    );
  }
}
