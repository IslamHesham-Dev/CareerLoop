import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/repositories.dart';

class AiAssistAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final String prompt;
  final bool enabled;

  const AiAssistAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.prompt,
    this.enabled = true,
  });
}

Future<void> showAiAssistSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<AiAssistAction> actions,
  IconData icon = Icons.auto_awesome_rounded,
}) async {
  final prompt = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [LensColors.indigo, LensColors.violet],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: Colors.white, size: 21),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(sheetContext)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Material(
                  color: action.enabled
                      ? LensColors.indigo.withValues(alpha: .045)
                      : LensColors.line.withValues(alpha: .35),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: action.enabled
                        ? () => Navigator.of(sheetContext).pop(action.prompt)
                        : null,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 39,
                            height: 39,
                            decoration: BoxDecoration(
                              color: (action.enabled
                                      ? LensColors.violet
                                      : LensColors.muted)
                                  .withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              action.icon,
                              size: 19,
                              color: action.enabled
                                  ? LensColors.violet
                                  : LensColors.muted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  action.title,
                                  style: TextStyle(
                                    color: action.enabled
                                        ? LensColors.ink
                                        : LensColors.muted,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  action.subtitle,
                                  style: Theme.of(sheetContext)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            action.enabled
                                ? Icons.arrow_forward_rounded
                                : Icons.lock_outline_rounded,
                            color: LensColors.muted,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (prompt == null || !context.mounted) return;
  context.read<AdvisorRepository>().send(prompt);
  context.go('/advisor');
}
