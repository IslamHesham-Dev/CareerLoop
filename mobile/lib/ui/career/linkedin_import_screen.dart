import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/career_profile_repository.dart';
import '../../data/repositories.dart';
import '../core/brand_marks.dart';
import '../core/lens_components.dart';

const _linkedInBlue = LinkedInBrandMark.blue;

class LinkedInImportScreen extends StatefulWidget {
  const LinkedInImportScreen({super.key});

  @override
  State<LinkedInImportScreen> createState() => _LinkedInImportScreenState();
}

class _LinkedInImportScreenState extends State<LinkedInImportScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<CareerProfileRepository>();
    return Scaffold(
      backgroundColor: LensColors.canvas,
      appBar: LensPageAppBar(
        title: 'LinkedIn profile',
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        top: false,
        child: repository.hasProfile
            ? _ConnectedProfile(repository: repository)
            : Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (value) => setState(() => _page = value),
                      children: const [
                        _GuidePage(
                          step: '01',
                          icon: Icons.language_rounded,
                          title: 'Open your profile\non LinkedIn web',
                          message:
                              'On a desktop or mobile browser, open LinkedIn, '
                              'select your profile photo, then choose '
                              'View Profile.',
                          note:
                              'The Save to PDF option is available from the web '
                              'profile experience.',
                        ),
                        _GuidePage(
                          step: '02',
                          icon: Icons.picture_as_pdf_outlined,
                          title: 'Choose\nSave to PDF',
                          message:
                              'On your profile page, open the More or Resources '
                              'dropdown and select Save to PDF. LinkedIn will '
                              'download a profile snapshot.',
                          note:
                              'Use LinkedIn’s generated PDF—not screenshots or '
                              'a manually designed CV.',
                        ),
                        _GuidePage(
                          step: '03',
                          icon: Icons.upload_file_rounded,
                          title: 'Import your\nprofessional evidence',
                          message:
                              'Upload that PDF here. CareerLoop extracts your '
                              'name, headline, summary, experience, education, '
                              'contact details, skills, and certifications.',
                          note:
                              'The original PDF stays in CareerLoop’s private '
                              'app storage. It is processed in your temporary '
                              'private backend session and is not stored there.',
                        ),
                      ],
                    ),
                  ),
                  if (repository.error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                      child: Text(
                        repository.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: LensColors.rose,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  _GuideFooter(
                    page: _page,
                    importing: repository.importing,
                    onBack: _page == 0
                        ? null
                        : () => _pages.previousPage(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                            ),
                    onNext: () async {
                      if (_page < 2) {
                        await _pages.nextPage(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        final imported = await repository.pickAndImport();
                        if (imported && context.mounted) {
                          context.read<AdvisorRepository>().clearLocal();
                        }
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class _GuidePage extends StatelessWidget {
  final String step;
  final IconData icon;
  final String title;
  final String message;
  final String note;

  const _GuidePage({
    required this.step,
    required this.icon,
    required this.title,
    required this.message,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
      children: [
        Row(
          children: [
            const LinkedInBrandMark(size: 46),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import from LinkedIn',
                    style: TextStyle(
                      color: _linkedInBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Three quick steps',
                    style: TextStyle(
                      color: LensColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              step,
              style: const TextStyle(
                color: LensColors.line,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 54),
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _linkedInBlue.withValues(alpha: .08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _linkedInBlue, size: 34),
        ),
        const SizedBox(height: 28),
        Text(title, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 16),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: LensColors.muted,
              ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: LensColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: _linkedInBlue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note,
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 11,
                    height: 1.4,
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

class _GuideFooter extends StatelessWidget {
  final int page;
  final bool importing;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const _GuideFooter({
    required this.page,
    required this.importing,
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
              3,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == page ? 24 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == page ? _linkedInBlue : LensColors.line,
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
                  onPressed: importing ? null : onBack,
                  child: const Text('Back'),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _linkedInBlue,
                  ),
                  onPressed: importing ? null : onNext,
                  icon: importing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          page == 2
                              ? Icons.upload_file_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                  label: Text(
                    page == 2 ? 'Choose LinkedIn PDF' : 'Continue',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectedProfile extends StatelessWidget {
  final CareerProfileRepository repository;

  const _ConnectedProfile({required this.repository});

  @override
  Widget build(BuildContext context) {
    final profile = repository.profile!;
    final evidence = <String>[
      if (profile.summary?.isNotEmpty ?? false) 'Summary',
      if (profile.experience.isNotEmpty) 'Experience',
      if (profile.education.isNotEmpty) 'Education',
      if (profile.skills.isNotEmpty) 'Skills',
      if (profile.certifications.isNotEmpty) 'Certifications',
      if (profile.contact.isNotEmpty) 'Contact',
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _linkedInBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const LinkedInBrandMark(size: 40),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LinkedIn profile connected',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      profile.name ?? 'Professional profile imported',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (profile.headline != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        profile.headline!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 3),
                      Text(
                        '${profile.pageCount}-page LinkedIn PDF',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: Colors.white),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Available to Copilot',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        LensCard(
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: evidence
                .map(
                  (item) => Chip(
                    avatar: const Icon(Icons.check_rounded, size: 14),
                    label: Text(item),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        LensCard(
          child: Column(
            children: [
              _MetadataRow(
                label: 'Local document',
                value: profile.fileName,
              ),
              const Divider(height: 22),
              _MetadataRow(
                label: 'Imported',
                value: DateFormat.yMMMd().format(profile.importedAt.toLocal()),
              ),
              const Divider(height: 22),
              _MetadataRow(
                label: 'Pages',
                value: '${profile.pageCount}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: _linkedInBlue),
          onPressed: repository.importing
              ? null
              : () async {
                  final imported = await repository.pickAndImport();
                  if (imported && context.mounted) {
                    context.read<AdvisorRepository>().clearLocal();
                  }
                },
          icon: const Icon(Icons.change_circle_outlined),
          label: const Text('Replace LinkedIn PDF'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: repository.importing
              ? null
              : () => _confirmRemove(context, repository),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Remove imported profile'),
        ),
        const SizedBox(height: 10),
        const Text(
          'This is a user-imported snapshot, not a live LinkedIn connection. '
          'CareerLoop never logs into or scrapes your LinkedIn account.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: LensColors.muted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    CareerProfileRepository repository,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove LinkedIn profile?'),
        content: const Text(
          'The locally stored PDF and its extracted professional evidence '
          'will be deleted from CareerLoop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
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
        context.read<AdvisorRepository>().clearLocal();
      }
    }
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: LensColors.muted, fontSize: 11),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
