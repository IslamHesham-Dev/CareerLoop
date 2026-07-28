import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/career_profile_repository.dart';
import '../../data/career_document_repository.dart';
import '../../data/current_cv_repository.dart';
import '../../data/github_profile_repository.dart';
import '../../data/email_repository.dart';
import '../../data/repositories.dart';
import '../../data/tone_profile_repository.dart';
import '../core/lens_components.dart';
import '../core/notion_export_action.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicRepository>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicRepository>();
    final auth = context.watch<AuthRepository>();
    final university = auth.session?.universityLabel ?? 'University';
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          children: [
            Text('Academic', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            LensCard(
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.school_rounded,
                    title: 'Academic context year',
                    value: academic.context?.transcriptYear ??
                        auth.session?.advisoryYear ??
                        '2024-2025',
                  ),
                  const Divider(height: 25),
                  _SettingRow(
                    icon: Icons.visibility_outlined,
                    title: 'Connected academic sources',
                    value: '$university Portal + $university CMS',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Integrations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const NotionConnectionCard(),
            const SizedBox(height: 24),
            Text(
              'Data and privacy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            LensCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cached data reduces repeated requests to the $university portal.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your university password is never sent to the AI. '
                    'Only a short-lived session token is stored securely '
                    'on this device.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await academic.clearPortalCache();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Portal cache cleared.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('Clear portal cache'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.read<AdvisorRepository>().reset(),
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text('Reset Copilot conversation'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: LensColors.rose,
              ),
              onPressed: auth.isBusy
                  ? null
                  : () async {
                      final advisor = context.read<AdvisorRepository>();
                      final cms = context.read<CmsRepository>();
                      final notion = context.read<NotionRepository>();
                      final career = context.read<CareerProfileRepository>();
                      final github = context.read<GithubProfileRepository>();
                      final resume = context.read<CurrentCvRepository>();
                      final documents =
                          context.read<CareerDocumentRepository>();
                      final tone = context.read<ToneProfileRepository>();
                      final emails = context.read<EmailRepository>();
                      await advisor.reset();
                      academic.clearLocal();
                      cms.clearLocal();
                      notion.clearLocal();
                      career.markSessionChanged();
                      github.markSessionChanged();
                      resume.markSessionChanged();
                      tone.markSessionChanged();
                      emails.reset();
                      documents.clear();
                      await auth.logout();
                    },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out and close portal session'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: LensColors.indigo.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: LensColors.indigo, size: 21),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
