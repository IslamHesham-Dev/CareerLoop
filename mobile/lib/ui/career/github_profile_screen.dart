import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/github_profile_repository.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class GithubProfileScreen extends StatefulWidget {
  const GithubProfileScreen({super.key});

  @override
  State<GithubProfileScreen> createState() => _GithubProfileScreenState();
}

class _GithubProfileScreenState extends State<GithubProfileScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GithubProfileRepository>().refreshStatus();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<GithubProfileRepository>();
    return Scaffold(
      backgroundColor: LensColors.canvas,
      appBar: LensPageAppBar(
        title: 'GitHub',
        onBack: () => context.pop(),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Icon(SimpleIcons.github, size: 23),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 44),
        children: [
          if (repository.profile case final profile?)
            _ConnectedProfile(
              profile: profile,
              loading: repository.loading,
              error: repository.error,
              onRefresh: () => _refresh(repository),
              onReconnect: () => _begin(repository),
              onRemove: () => _remove(repository),
            )
          else
            _ConnectionExperience(
              repository: repository,
              onConnect: () => _begin(repository),
              onOpenGithub: () => _openAuthorization(repository),
              onCheck: () => _poll(repository),
            ),
        ],
      ),
    );
  }

  Future<void> _begin(GithubProfileRepository repository) async {
    _pollTimer?.cancel();
    final authorization = await repository.beginConnection();
    if (!mounted || authorization == null) return;
    await Clipboard.setData(ClipboardData(text: authorization.userCode));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GitHub code copied. Paste it in the browser.'),
      ),
    );
    await launchUrl(
      authorization.verificationUri,
      mode: LaunchMode.externalApplication,
    );
    _pollTimer = Timer.periodic(
      Duration(seconds: authorization.interval + 1),
      (_) => _poll(repository),
    );
  }

  Future<void> _poll(GithubProfileRepository repository) async {
    final status = await repository.pollConnection();
    if (status == 'connected') {
      _pollTimer?.cancel();
      if (!mounted) return;
      context.read<AdvisorRepository>().clearLocal();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'GitHub connected. Repository evidence is ready for CareerLoop.',
          ),
        ),
      );
    } else if (status == 'expired' || status == 'denied' || status == 'error') {
      _pollTimer?.cancel();
    }
  }

  Future<void> _openAuthorization(
    GithubProfileRepository repository,
  ) async {
    final authorization = repository.authorization;
    if (authorization == null) return;
    await Clipboard.setData(ClipboardData(text: authorization.userCode));
    await launchUrl(
      authorization.verificationUri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _refresh(GithubProfileRepository repository) async {
    final refreshed = await repository.refreshProfile();
    if (!mounted) return;
    if (refreshed) {
      context.read<AdvisorRepository>().clearLocal();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GitHub evidence refreshed.')),
      );
    }
  }

  Future<void> _remove(GithubProfileRepository repository) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove GitHub evidence?'),
        content: const Text(
          'CareerLoop will remove the local repository snapshot and stop using '
          'it for advisor and job-fit responses. This does not change GitHub.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await repository.remove();
    if (!mounted) return;
    context.read<AdvisorRepository>().clearLocal();
  }
}

class _ConnectionExperience extends StatelessWidget {
  final GithubProfileRepository repository;
  final VoidCallback onConnect;
  final VoidCallback onOpenGithub;
  final VoidCallback onCheck;

  const _ConnectionExperience({
    required this.repository,
    required this.onConnect,
    required this.onOpenGithub,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    final authorization = repository.authorization;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LensCard(
          padding: const EdgeInsets.all(20),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(SimpleIcons.github, size: 36, color: LensColors.ink),
              SizedBox(height: 18),
              Text(
                'Connect your GitHub profile',
                style: TextStyle(
                  color: LensColors.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'CareerLoop reads public repositories and uses verified project details when matching roles.',
                style: TextStyle(
                  color: LensColors.muted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'What is imported',
          style: TextStyle(
            color: LensColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const _ExtractionGrid(),
        const SizedBox(height: 18),
        LensCard(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: LensColors.aqua),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Public repositories only',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'This build requests GitHub identity access and analyzes only '
                'public, non-fork, non-archived repositories. It does not ask '
                'for private-repository access or modify your account.',
                style: TextStyle(
                  color: LensColors.muted,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
              if (!repository.configured) ...[
                const SizedBox(height: 13),
                _InlineNotice(
                  text: repository.configurationMessage ??
                      'GitHub connection is not configured on this deployment.',
                  color: LensColors.amber,
                ),
              ],
              if (repository.error != null) ...[
                const SizedBox(height: 13),
                _InlineNotice(
                  text: repository.error!,
                  color: LensColors.rose,
                ),
              ],
              if (authorization != null) ...[
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'One-time code',
                  style: TextStyle(
                    color: LensColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(text: authorization.userCode),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('GitHub authorization code copied.'),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 6, 7, 6),
                    decoration: BoxDecoration(
                      color: LensColors.canvas,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            authorization.userCode,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 23,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Copy GitHub code',
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: authorization.userCode),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'GitHub authorization code copied.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    if (repository.polling)
                      const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(
                        Icons.hourglass_top_rounded,
                        size: 16,
                        color: LensColors.indigo,
                      ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Waiting for approval. Repository analysis starts '
                        'automatically after authorization.',
                        style: TextStyle(
                          color: LensColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: repository.loading || !repository.configured
                      ? null
                      : authorization == null
                          ? onConnect
                          : onOpenGithub,
                  icon: repository.loading
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(SimpleIcons.github, size: 18),
                  label: Text(
                    authorization == null
                        ? 'Connect GitHub'
                        : 'Open GitHub and paste code',
                  ),
                ),
              ),
              if (authorization != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: repository.polling ? null : onCheck,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text("I've authorized — check now"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExtractionGrid extends StatelessWidget {
  const _ExtractionGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        Icons.code_rounded,
        'Languages',
        'GitHub Linguist usage, not profile claims'
      ),
      (
        Icons.account_tree_outlined,
        'Technologies',
        'Frameworks found in dependency manifests'
      ),
      (
        Icons.folder_copy_outlined,
        'Projects',
        'Descriptions, topics, activity, and README context'
      ),
      (
        Icons.fact_check_outlined,
        'Evidence',
        'Every skill remains linked to supporting repos'
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: 1.18,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: LensColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.$1, color: LensColors.indigo, size: 21),
              const Spacer(),
              Text(
                item.$2,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                item.$3,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LensColors.muted,
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConnectedProfile extends StatelessWidget {
  final GithubProfileEvidence profile;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;
  final VoidCallback onReconnect;
  final VoidCallback onRemove;

  const _ConnectedProfile({
    required this.profile,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onReconnect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final totalLanguageBytes =
        profile.languages.values.fold<int>(0, (sum, value) => sum + value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LensCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GithubAvatar(profile: profile),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name ?? profile.login,
                          style: const TextStyle(
                            color: LensColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '@${profile.login}',
                          style: const TextStyle(
                            color: LensColors.indigo,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if ((profile.bio ?? '').isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Text(
                            profile.bio!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: LensColors.muted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.verified_rounded,
                    color: LensColors.aqua,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _ProfileMetric(
                    value: '${profile.analyzedRepositoryCount}',
                    label: 'repos analyzed',
                  ),
                  _ProfileMetric(
                    value: '${profile.skills.length}',
                    label: 'skill signals',
                  ),
                  _ProfileMetric(
                    value: '${profile.followers}',
                    label: 'followers',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 13),
          _InlineNotice(text: error!, color: LensColors.rose),
        ],
        const SizedBox(height: 22),
        const _SectionHeading(
          eyebrow: 'Languages',
          title: 'Repository language mix',
          subtitle:
              'Calculated from bytes classified by GitHub—not self-reported proficiency.',
        ),
        const SizedBox(height: 11),
        LensCard(
          padding: const EdgeInsets.all(17),
          child: Column(
            children: profile.languages.entries.take(6).map((entry) {
              final ratio = totalLanguageBytes == 0
                  ? 0.0
                  : entry.value / totalLanguageBytes;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LanguageBar(
                  language: entry.key,
                  ratio: ratio,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 22),
        const _SectionHeading(
          eyebrow: 'Skills',
          title: 'Technologies found in your projects',
          subtitle:
              'Each signal records the repositories that support it; use is not presented as mastery.',
        ),
        const SizedBox(height: 11),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: profile.skills
              .take(18)
              .map(
                (skill) => ActionChip(
                  avatar: const Icon(Icons.code_rounded, size: 14),
                  label: Text(
                    '${skill.skill} · ${skill.evidenceRepos.length}',
                  ),
                  onPressed: () => _showSkillEvidence(context, skill),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        _SectionHeading(
          eyebrow: 'Projects',
          title: '${profile.repositories.length} public repositories',
          subtitle:
              'Tap a project to inspect the evidence CareerLoop will provide to the advisor.',
        ),
        const SizedBox(height: 11),
        ...profile.repositories.map(
          (repository) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RepositoryCard(repository: repository),
          ),
        ),
        const SizedBox(height: 16),
        LensCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.sync_rounded,
                    color: LensColors.indigo,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Updated ${_formatDate(profile.refreshedAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading ? null : onReconnect,
                      child: const Text('Reconnect'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: loading ? null : onRefresh,
                      icon: loading
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 17),
                      label: const Text('Refresh'),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: loading ? null : onRemove,
                child: const Text('Remove GitHub evidence'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';

  static Future<void> _showSkillEvidence(
    BuildContext context,
    GithubSkillEvidence skill,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                skill.skill,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 3),
              Text(
                skill.category,
                style: const TextStyle(
                  color: LensColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Supported by',
                style: TextStyle(
                  color: LensColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: skill.evidenceRepos
                    .map((repo) => Chip(label: Text(repo)))
                    .toList(),
              ),
              const SizedBox(height: 14),
              const Text(
                'CareerLoop treats this as evidence of use, not a claim of mastery.',
                style: TextStyle(color: LensColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GithubAvatar extends StatelessWidget {
  final GithubProfileEvidence profile;

  const _GithubAvatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl?.toString() ?? '';
    return Container(
      width: 62,
      height: 62,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: LensColors.canvas,
        shape: BoxShape.circle,
        border: Border.all(color: LensColors.line, width: 2),
      ),
      child: url.isEmpty
          ? const Icon(SimpleIcons.github, color: LensColors.ink, size: 30)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                SimpleIcons.github,
                color: LensColors.ink,
                size: 30,
              ),
            ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: LensColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: LensColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _LanguageBar extends StatelessWidget {
  final String language;
  final double ratio;

  const _LanguageBar({required this.language, required this.ratio});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                language,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${(ratio * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: LensColors.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: ratio.clamp(0, 1),
            backgroundColor: LensColors.line,
            color: LensColors.indigo,
          ),
        ),
      ],
    );
  }
}

class _RepositoryCard extends StatelessWidget {
  final GithubRepositoryEvidence repository;

  const _RepositoryCard({required this.repository});

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: () => _showRepository(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LensColors.ink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  SimpleIcons.github,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repository.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      repository.primaryLanguage ?? 'Mixed codebase',
                      style: const TextStyle(
                        color: LensColors.indigo,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          if ((repository.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              repository.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LensColors.muted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          if (repository.detectedSkills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: repository.detectedSkills
                  .take(5)
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: LensColors.canvas,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showRepository(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                repository.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              Text(
                repository.fullName,
                style: const TextStyle(color: LensColors.muted),
              ),
              if ((repository.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  repository.description!,
                  style: const TextStyle(height: 1.45),
                ),
              ],
              const SizedBox(height: 18),
              const Text(
                'Technologies found',
                style: TextStyle(
                  color: LensColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: repository.detectedSkills
                    .map((skill) => Chip(label: Text(skill)))
                    .toList(),
              ),
              if ((repository.readmeExcerpt ?? '').isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'README excerpt',
                  style: TextStyle(
                    color: LensColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LensColors.canvas,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    repository.readmeExcerpt!,
                    maxLines: 12,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => launchUrl(
                    repository.url,
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open repository'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String text;
  final Color color;

  const _InlineNotice({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, height: 1.35),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: LensColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: LensColors.muted,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
