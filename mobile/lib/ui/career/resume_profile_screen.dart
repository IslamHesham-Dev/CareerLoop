import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/application_models.dart';
import '../../data/current_cv_repository.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class ResumeProfileScreen extends StatefulWidget {
  const ResumeProfileScreen({super.key});

  @override
  State<ResumeProfileScreen> createState() => _ResumeProfileScreenState();
}

class _ResumeProfileScreenState extends State<ResumeProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final repository = context.watch<CurrentCvRepository>();
    return Scaffold(
      backgroundColor: LensColors.canvas,
      appBar: LensPageAppBar(
        title: 'Resume evidence',
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: repository.hasProfile
              ? _ExtractedProfile(
                  key: const ValueKey('resume-profile'),
                  repository: repository,
                )
              : _ResumeImport(
                  key: const ValueKey('resume-import'),
                  repository: repository,
                  onImported: () {
                    if (mounted) setState(() {});
                  },
                ),
        ),
      ),
    );
  }
}

class _ResumeImport extends StatelessWidget {
  final CurrentCvRepository repository;
  final VoidCallback onImported;

  const _ResumeImport({
    super.key,
    required this.repository,
    required this.onImported,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      children: [
        LensCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: LensColors.indigo.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: LensColors.indigo,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Import your resume',
                style: TextStyle(
                  color: LensColors.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'CareerLoop reads the information in your PDF and makes it available for job matching and tailored documents.',
                style: TextStyle(color: LensColors.muted, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LensCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What becomes agent-ready',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 15),
              const _ImportCapability(
                icon: Icons.badge_outlined,
                title: 'Identity and contact',
                text: 'Name, headline, email, and phone when present.',
              ),
              const _ImportCapability(
                icon: Icons.work_history_outlined,
                title: 'Experience and skills',
                text: 'Summary, experience, skills, and certifications.',
              ),
              const _ImportCapability(
                icon: Icons.hub_outlined,
                title: 'Profile context',
                text:
                    'Paired with academic, LinkedIn, and GitHub sources during relevant agent tasks.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _PrivacyNotice(),
        if (repository.currentCv != null && repository.profile == null) ...[
          const SizedBox(height: 12),
          const _LegacyNotice(),
        ],
        if (repository.error != null) ...[
          const SizedBox(height: 12),
          Text(
            repository.error!,
            style: const TextStyle(color: LensColors.rose),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: repository.selecting
              ? null
              : () async {
                  final imported = repository.currentCv == null
                      ? await repository.pick()
                      : await repository.ensureSynced();
                  if (imported && context.mounted) {
                    context.read<AdvisorRepository>().clearLocal();
                    onImported();
                  }
                },
          icon: repository.selecting
              ? const SizedBox.square(
                  dimension: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.upload_file_rounded),
          label: Text(
            repository.selecting
                ? 'Reading resume…'
                : repository.currentCv == null
                    ? 'Choose resume PDF'
                    : 'Extract saved resume',
          ),
        ),
      ],
    );
  }
}

class _ExtractedProfile extends StatelessWidget {
  final CurrentCvRepository repository;

  const _ExtractedProfile({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final profile = repository.profile!;
    final file = repository.currentCv!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 38),
      children: [
        LensCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: LensColors.indigo.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: LensColors.indigo,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resume imported',
                          style: TextStyle(
                            color: LensColors.indigo,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Available to CareerLoop',
                          style: TextStyle(
                            color: LensColors.muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.verified_rounded,
                    color: LensColors.aqua,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                profile.name ?? 'Current resume',
                style: const TextStyle(
                  color: LensColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (profile.headline?.isNotEmpty ?? false) ...[
                const SizedBox(height: 5),
                Text(
                  profile.headline!,
                  style: TextStyle(
                    color: LensColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 17),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _DarkFact(icon: Icons.picture_as_pdf, label: file.fileName),
                  _DarkFact(
                    icon: Icons.layers_outlined,
                    label: '${profile.pageCount} pages',
                  ),
                  _DarkFact(
                    icon: Icons.schedule_rounded,
                    label: DateFormat('d MMM yyyy').format(profile.importedAt),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _EvidenceCoverage(profile: profile),
        if (profile.summary?.isNotEmpty ?? false) ...[
          const SizedBox(height: 14),
          _TextSection(
            title: 'Professional summary',
            icon: Icons.subject_rounded,
            values: [profile.summary!],
          ),
        ],
        if (profile.skills.isNotEmpty) ...[
          const SizedBox(height: 14),
          LensCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(
                  icon: Icons.auto_awesome_mosaic_outlined,
                  title: 'Extracted skills',
                ),
                const SizedBox(height: 13),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: profile.skills
                      .take(30)
                      .map((skill) => Chip(label: Text(skill)))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
        if (profile.experience.isNotEmpty) ...[
          const SizedBox(height: 14),
          _TextSection(
            title: 'Experience',
            icon: Icons.work_outline_rounded,
            values: profile.experience,
          ),
        ],
        if (profile.education.isNotEmpty) ...[
          const SizedBox(height: 14),
          _TextSection(
            title: 'Education',
            icon: Icons.school_outlined,
            values: profile.education,
          ),
        ],
        if (profile.certifications.isNotEmpty) ...[
          const SizedBox(height: 14),
          _TextSection(
            title: 'Certifications',
            icon: Icons.workspace_premium_outlined,
            values: profile.certifications,
          ),
        ],
        const SizedBox(height: 18),
        const _AgentContextCard(),
        if (repository.error != null) ...[
          const SizedBox(height: 12),
          Text(
            repository.error!,
            style: const TextStyle(color: LensColors.rose),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: repository.selecting
                    ? null
                    : () async {
                        final imported = await repository.pick();
                        if (imported && context.mounted) {
                          context.read<AdvisorRepository>().clearLocal();
                        }
                      },
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Replace'),
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
    CurrentCvRepository repository,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove resume evidence?'),
        content: const Text(
          'The local PDF and extracted profile will be removed. CareerLoop '
          'will stop using this resume in new agent responses.',
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
        context.read<AdvisorRepository>().clearLocal();
      }
    }
  }
}

class _EvidenceCoverage extends StatelessWidget {
  final ResumeProfile profile;

  const _EvidenceCoverage({required this.profile});

  @override
  Widget build(BuildContext context) {
    final values = [
      ('Skills', profile.skills.length),
      ('Experience', profile.experience.length),
      ('Education', profile.education.length),
      ('Credentials', profile.certifications.length),
    ];
    return LensCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: values
            .map(
              (item) => Expanded(
                child: Column(
                  children: [
                    Text(
                      '${item.$2}',
                      style: const TextStyle(
                        color: LensColors.indigo,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.$1,
                      style: const TextStyle(
                        color: LensColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> values;

  const _TextSection({
    required this.title,
    required this.icon,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: icon, title: title),
          const SizedBox(height: 12),
          for (final value in values.take(12))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: CircleAvatar(
                      radius: 2.5,
                      backgroundColor: LensColors.indigo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: LensColors.indigo, size: 20),
        const SizedBox(width: 9),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _ImportCapability extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _ImportCapability({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: LensColors.indigo, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    color: LensColors.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentContextCard extends StatelessWidget {
  const _AgentContextCard();

  @override
  Widget build(BuildContext context) {
    return LensCard(
      color: LensColors.indigo.withValues(alpha: .08),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hub_outlined, color: LensColors.indigo),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available to CareerLoop Copilot',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5),
                Text(
                  'For relevant career tasks, the agent can combine this '
                  'resume with your complete academic record, LinkedIn PDF, '
                  'and GitHub projects while keeping each source traceable.',
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
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: LensColors.aqua.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: LensColors.aqua),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'The PDF is saved in private app storage. The backend extracts '
              'it into your short-lived CareerLoop session and does not keep '
              'the original file.',
              style: TextStyle(fontSize: 11, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyNotice extends StatelessWidget {
  const _LegacyNotice();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'A CV was previously selected for applications. Extract the saved file '
      'to make its profile available to the agent.',
      style: TextStyle(color: LensColors.amber, fontSize: 11),
    );
  }
}

class _DarkFact extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DarkFact({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: LensColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LensColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: LensColors.muted, size: 13),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LensColors.muted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
